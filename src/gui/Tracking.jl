module Tracking

using DataStructures: Queue
import GLMakie

using ..BasicHouseAM: isOccupied
using ..FullModel: Model
using ..FullModelPerson: Person, PersonHouse, weeklyTodoTally
using ..KinshipAM: nSiblings
using ..Tasks: taskIsCare
using ..Utilities: isUndefined, date2yearsmonths
using ..WorkAM: WorkStatus

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

mutable struct AgentState
    partner::Person
    mother::Person
    father::Person
    n_full_siblings::Int64
    n_half_siblings::Int64
    n_children::Int64
end

mutable struct HousemateState
    status::WorkStatus.T
    careNeed::Int
end

function agentState(person::Person)
    n_fsibs, n_hsibs = nSiblings(person)
    n_ch = count(x->!isUndefined(x), person.children)
    AgentState(person.partner, person.mother, person.father, n_fsibs, n_hsibs, n_ch)
end

function housemateState(house::PersonHouse)::Dict{Person, HousemateState}
    map = Dict{Person, HousemateState}()
    for person in house.occupants
        map[person] = HousemateState(person.status, person.careNeedLevel)
    end
    map
end

mutable struct FollowedAgent
    model::Model
    agent::Person
    last_state::AgentState
    last_hm_states::Dict{Person, HousemateState}
    house::PersonHouse
    log::Log
    names::Naming.NamePool
end

function getName(fa::FollowedAgent, person::Person)::String
    Naming.getName!(fa.names, person)
end

function pickAgent(model::Model)::FollowedAgent
    agent = rand(model.pop)
    house = agent.pos
    FollowedAgent(model, agent, agentState(agent), housemateState(house), house, newLog(30), Naming.newPool())
end

function statusDescr(status::WorkStatus.T)::String
    if status == WorkStatus.child
        "a child"
    elseif status == WorkStatus.teenager
        "a teenager"
    elseif status == WorkStatus.student
        "a student"
    elseif status == WorkStatus.FixedShiftEmployed
        "employed with a fixed shift"
    elseif status == WorkStatus.FlexibleShiftEmployed
        "employed with a flexible shift"
    elseif status == WorkStatus.retired
        "retired"
    else
        "unemployed"
    end
end

function update!(fa::FollowedAgent, time::Rational{Int})
    year, month = date2yearsmonths(time)
    tStr = "$(year)/$(month+1): "
    name = getName(fa, fa.agent)
    if !fa.agent.alive
        push!(fa.log, "$(tStr)$(name) has died")
        if isOccupied(fa.house)
            fa.agent = rand(fa.house.occupants)
            fa.last_state = agentState(fa.agent)
            name = getName(fa, fa.agent)
            push!(fa.log, "$(tStr)following $(name) from same house")
        else
            fa.agent = rand(fa.model.pop)
            fa.last_state = agentState(fa.agent)
            fa.house = fa.agent.pos
            Naming.forgetNames!(fa.names)
            name = getName(fa, fa.agent)
            push!(fa.log, "$(tStr)following $(name) from a different house")
        end
    end
    if fa.agent.pos !== fa.house
        push!(fa.log, "$(tStr)$(name) changed address")
        fa.house = fa.agent.pos
    end

    new_state = agentState(fa.agent)
    if new_state.partner != fa.last_state.partner
        if isUndefined(new_state.partner)
            ex_name = getName(fa, fa.last_state.partner)
            push!(fa.log, "$(tStr)$(name) and $(ex_name) separated")
        else
            partner_name = getName(fa, new_state.partner)
            push!(fa.log, "$(tStr)$(name) married $(partner_name)")
        end
    end
    if new_state.mother != fa.last_state.mother
        mo_name = getName(fa, fa.last_state.mother)
        push!(fa.log, "$(tStr)$(name)'s mother, $(mo_name), died")
    end
    if new_state.father != fa.last_state.father
        fa_name = getName(fa, fa.last_state.father)
        push!(fa.log, "$(tStr)$(name)'s father, $(fa_name), died")
    end

    new_hm_state = housemateState(fa.house)
    for (agent, state) in pairs(new_hm_state)
        name = getName(fa, agent)
        last = get(fa.last_hm_states, agent, nothing)
        if isnothing(last)
            if (agent.age < 1)
                push!(fa.log, "$(tStr)$(name) was born")
            else
                push!(fa.log, "$(tStr)$(name) joined the house")
            end
            continue
        end
        if state.status != last.status
            statusStr = statusDescr(state.status)
            push!(fa.log, "$(tStr)$(name) is now $(statusStr)")
        end
        if state.careNeed != last.careNeed
            push!(fa.log, "$(tStr)$(name) care need went from $(last.careNeed) to $(state.careNeed)")
        end
    end
    for agent in keys(fa.last_hm_states)
        name = getName(fa, agent)
        if !haskey(new_hm_state, agent) && agent.alive
            push!(fa.log, "$(tStr)$(name) left the house")
        end
    end

    fa.last_state = new_state
    fa.last_hm_states = new_hm_state
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
    parents = join(parents, " & ")
    obs1 = "$(name), $(agent.gender), $(floor(Int, agent.age))\n" *
        "status: $m_status\n" *
        "parents: $parents\n" *
        "$(fa.last_state.n_full_siblings) full siblings\n" *
        "$(fa.last_state.n_half_siblings) half siblings\n" *
        "$(fa.last_state.n_children) children"

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

function describeOccupants(fa::FollowedAgent)::String
    # emojis = ['\U1f642', '\U1F610', '\U1FAE9', '\U1F915', '\U1F635']
    descr = ""
    for agent in sort(fa.house.occupants, by= a -> a.age, rev = true)
        name = getName(fa, agent)
        care = agent.careNeedLevel
        descr *= "$(name), $(agent.gender), $(floor(Int, agent.age)), care level: $(care)\n"
    end
    descr
end

function currentLog(fa::FollowedAgent)::String
    join(fa.log.log, '\n')
end

end
