module TaskI

using RequiredInterfaces

# should probably do that at the task level directly
abstract type Task{P} end

function weightClass end
function isCare end

@required Task begin
    weightClass(::Type{Task})
    isCare(::Task)
end

end
