module TasksCareCM
    

using ..Utilities

import ..FullModelPerson: Person
using ..MaternityAM, ..TasksAM
using ..Tasks: TaskKind, ATask


export socialCareDemandPerDay, weeklyCareSupply, initCareTasks!


function weeklyCareSupply(person, pars)
    if person.careNeedLevel > 0
        return 0
    end
    
    if isInMaternity(person)
        return pars.careSupplyMaternity
    end
    
    s = Int(person.status)
    
    informal = pars.careSupplyByStatus[s+1]

    if person.socialWorker
        return person.workingHours + informal
    end

    informal
end


socialCareDemandPerDay(person, pars) = pars.socialCareDemandPerDay[person.careNeedLevel + 1]
childCareDemandPerDay(person, pars) = 
    person.age < pars.stopChildCareAge ? 
        ( person.age < pars.stopBabyCareAge ? pars.babyCarePerDay : pars.childCarePerDay) :
        0

function initCareTasks!(person, pars)
    sc = socialCareDemandPerDay(person, pars)
    cc = childCareDemandPerDay(person, pars)
    
    # social care demand replaces childcare
    cc = max(cc-sc, 0)
    
    @assert 0 <= cc + sc <= 24
    
    freeHours = 24 - (sc + cc)
    @assert freeHours >= 0
    first = freeHours ÷ 2 + 1
    nSc1stHalf = sc ÷ 2
    nSc2ndHalf = sc - nSc1stHalf
    
    # TODO focus, urgency

    for day in 1:7
        hour = first
        for h in 1:nSc1stHalf
            task = ATask{Person}(TaskKind.SocialCare, person, undefined(person), 24*(day-1)+hour, 0.5, 0.5)
            push!(person.openTasks, task)
            hour += 1
        end
        for h in 1:cc
            task = ATask{Person}(TaskKind.ChildCare, person, undefined(person), 24*(day-1)+hour, 0.5, 0.5)
            push!(person.openTasks, task)
            hour += 1
        end
        for h in 1:nSc2ndHalf
            task = ATask{Person}(TaskKind.SocialCare, person, undefined(person), 24*(day-1)+hour, 0.5, 0.5)
            push!(person.openTasks, task)
            hour += 1
        end           
    end
end


end
