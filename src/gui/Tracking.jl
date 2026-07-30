module Tracking

using DataStructures: Queue

using ..BasicHouseAM: isOccupied
using ..FullModel: Model
using ..FullModelPerson: Person, PersonHouse, weeklyTodoTally
using ..KinshipAM: nSiblings
using ..Tasks: taskIsCare
using ..Utilities: isUndefined

import ..Naming

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
    names::Naming.NamePool
end

function getName(fa::FollowedAgent, person::Person)::String
    Naming.getName!(fa.names, person)
end

function pickAgent(model::Model)::FollowedAgent
    agent = rand(model.pop)
    FollowedAgent(model, agent, agent.pos, newLog(20), Naming.newPool())
end

function update!(fa::FollowedAgent)
    if !fa.agent.alive
        name = getName(fa, fa.agent)
        push!(fa.log, "$(name) has died")
        if isOccupied(fa.house)
            fa.agent = rand(fa.house.occupants)
            name = getName(fa, fa.agent)
            push!(fa.log, "following $(name) from same house")
        else
            fa.agent = rand(fa.model.pop)
            fa.house = fa.agent.pos
            Naming.forgetNames!(fa.names)
            name = getName(fa, fa.agent)
            push!(fa.log, "following $(name) from a different house")
        end
    end
    if fa.agent.pos !== fa.house
        name = getName(fa, fa.agent)
        push!(fa.log, "$(name) changed address")
        fa.house = fa.agent.pos
    end
end

function describeAgent(fa::FollowedAgent)::Tuple{String, String}
    agent = fa.agent
    name = getName(fa, agent)
    m_status = isUndefined(agent.partner) ? "single" : "married"
    parents = Vector{String}()
    if !isUndefined(agent.mother)
        push!(parents, getName(fa, agent.mother) * " (mother)")
    end
    if !isUndefined(agent.father)
        push!(parents, getName(fa, agent.father) * " (father)")
    end
    living_parents = join(parents, " & ")
    n_fsibs, n_hsibs = nSiblings(agent)
    n_ch = count(x->!isUndefined(x), agent.children)
    obs1 = "$(name), $(agent.gender), $(floor(Int, agent.age))\n" *
        "status: $m_status\n" *
        "living parents: $living_parents\n" *
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
