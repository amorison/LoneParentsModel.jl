module Tracking

using DataStructures: Queue

using ..BasicHouseAM: isOccupied
using ..FullModel: Model
using ..FullModelPerson: Person, PersonHouse, weeklyTodoTally
using ..KinshipAM: nSiblings
using ..Tasks: taskIsCare
using ..Utilities: isUndefined

struct Log
    log::Queue{String}
    size::Int
end

function Base.push!(log::Log, x::String)
    push!(log.log, x)
    while length(log.log) > log.size
        popfirst!(log.log)
    end
end

function newLog(size::Int)::Log
    Log(Queue{String}(), size)
end

mutable struct FollowedAgent
    model::Model
    agent::Person
    house::PersonHouse
    log::Log
end

function pickAgent(model::Model)::FollowedAgent
    agent = rand(model.pop)
    FollowedAgent(model, agent, agent.pos, newLog(20))
end

function update!(fa::FollowedAgent)
    if !fa.agent.alive
        push!(fa.log, "tracked agent has died")
        if isOccupied(fa.house)
            fa.agent = rand(fa.house.occupants)
            push!(fa.log, "following another agent from same house")
        else
            push!(fa.log, "this house is empty, picking another one")
            fa.agent = rand(fa.model.pop)
            fa.house = fa.agent.pos
        end
    end
    if fa.agent.pos !== fa.house
        push!(fa.log, "agent changed address")
        fa.house = fa.agent.pos
    end
end

function describeAgent(fa::FollowedAgent)::Tuple{String, String}
    agent = fa.agent
    m_status = isUndefined(agent.partner) ? "single" : "married"
    m_s = isUndefined(agent.mother) ? "" : "mother"
    f_s = isUndefined(agent.father) ? "" : "father"
    n_fsibs, n_hsibs = nSiblings(agent)
    n_ch = count(x->!isUndefined(x), agent.children)
    obs1 = "age: $(floor(Int, agent.age))\n" *
        "status: $m_status\n" *
        "living parents: $m_s $f_s\n" *
        "$n_fsibs full siblings\n" *
        "$n_hsibs half siblings\n" *
        "$n_ch children"

    weeklyTally = weeklyTodoTally(agent)

    ncare_open = 0
    ncare_assigned = 0
    for task in agent.openTasks
        if taskIsCare(task)
            ncare_open += 1
        end
    end
    for task in agent.assignedTasks
        if taskIsCare(task)
            ncare_assigned += 1
        end
    end
    tot_care = ncare_open + ncare_assigned

    obs2 = "$(agent.status)\n" *
        "working hours: $(weeklyTally.work) / $(agent.workingHours)\n" *
        "care done: child: $(weeklyTally.childCare), social: $(weeklyTally.socialCare)\n" *
        "care need level: $(agent.careNeedLevel)\n" *
        "cared for: $(ncare_assigned) / $(tot_care)"

    (obs1, obs2)
end

function currentLog(fa::FollowedAgent)::String
    join(fa.log.log, '\n')
end

end
