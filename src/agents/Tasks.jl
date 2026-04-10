module Tasks

using EnumX

export taskTimeToDay, taskTimeToHour

import ..TaskI


mutable struct ChildCare{P} <: TaskI.Task{P}
    owner :: P
    worker :: P
    "Time in h after 0:00 on Monday."
    time :: Int
    "Urgency of the task (0-1)."
    urgency :: Float64
    "Focus required (0-1)."
    focus :: Float64
end

TaskI.weightClass(::Type{<:ChildCare{<:P}}) where {P} = 1

function TaskI.isCare(task::ChildCare)
    true
end


mutable struct SocialCare{P} <: TaskI.Task{P}
    owner :: P
    worker :: P
    "Time in h after 0:00 on Monday."
    time :: Int
    "Urgency of the task (0-1)."
    urgency :: Float64
    "Focus required (0-1)."
    focus :: Float64
end

TaskI.weightClass(::Type{<:SocialCare{<:P}}) where {P} = 2

function TaskI.isCare(task::SocialCare)
    true
end


mutable struct Work{P} <: TaskI.Task{P}
    owner :: P
    worker :: P
    "Time in h after 0:00 on Monday."
    time :: Int
    "Urgency of the task (0-1)."
    urgency :: Float64
    "Focus required (0-1)."
    focus :: Float64
    Work{P}(worker::P, time::Int, urgency::Float64, focus::Float64) where {P} = new(worker, worker, time, urgency, focus)
end

TaskI.weightClass(::Type{<:Work{<:P}}) where {P} = 3

function TaskI.isCare(task::Work)
    false
end


"Task time -> day of the week."
taskTimeToDay(t) = (t-1) ÷ 24 + 1
taskTimeToHour(t) = (t-1) % 24 + 1

end
