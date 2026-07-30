module Naming

using Random: shuffle

using ..BasicInfoAM: Gender, male
using ..FullModelPerson: Person

maleNames = [
    "Adam", "Albert", "Albie", "Alexander", "Alfie", "Alfred", "Archie", "Arlo",
    "Arthur", "Asher", "Benjamin", "Blake", "Bobby", "Brody", "Caleb", "Carter",
    "Charles", "Charlie", "Chester", "Daniel", "David", "Dylan", "Edward",
    "Elijah", "Elliot", "Ellis", "Ethan", "Ezra", "Felix", "Finley", "Finn",
    "Frankie", "Freddie", "Frederick", "Gabriel", "George", "Grayson", "Harry",
    "Harvey", "Henry", "Hudson", "Hugo", "Hunter", "Isaac", "Jack", "Jackson",
    "Jacob", "James", "Jasper", "Jaxon", "Jesse", "Joseph", "Joshua", "Jude",
    "Julian", "Kai", "Leo", "Levi", "Liam", "Logan", "Louie", "Louis", "Luca",
    "Lucas", "Mason", "Max", "Michael", "Milo", "Mohammad", "Myles", "Nathan",
    "Noah", "Oakley", "Oliver", "Ollie", "Oscar", "Otis", "Ralph", "Reggie",
    "Reuben", "Riley", "Roman", "Ronnie", "Rory", "Rowan", "Rupert", "Samuel",
    "Sebastian", "Sonny", "Stanley", "Teddy", "Theo", "Thomas", "Tobias",
    "Toby", "Tommy", "Waylon", "William", "Yusuf", "Zachary",
]
femaleNames = [
    "Ada", "Alice", "Amber", "Amelia", "Amelie", "Anna", "Arabella", "Aria",
    "Aurora", "Ava", "Ayla", "Beatrice", "Bella", "Bonnie", "Camilla",
    "Charlotte", "Ciara", "Clara", "Daisy", "Darcie", "Delilah", "Eden",
    "Edith", "Eleanor", "Eliza", "Elizabeth", "Ella", "Elodie", "Elsie",
    "Emilia", "Emily", "Emma", "Erin", "Esme", "Eva", "Evelyn", "Evie",
    "Florence", "Freya", "Grace", "Gracie", "Hallie", "Hannah", "Harper",
    "Harriet", "Hazel", "Heidi", "Holly", "Imogen", "Iris", "Isabelle", "Isla",
    "Ivy", "Jasmine", "Jessica", "Lara", "Layla", "Lily", "Lola", "Lottie",
    "Lucy", "Luna", "Lyla", "Lyra", "Mabel", "Maeve", "Maisie", "Margot",
    "Maria", "Maryam", "Matilda", "Maya", "Mia", "Mila", "Millie", "Molly",
    "Myla", "Nancy", "Nova", "Olive", "Olivia", "Orla", "Penelope", "Phoebe",
    "Poppy", "Robyn", "Rose", "Rosie", "Ruby", "Sara", "Scarlett", "Sienna",
    "Sofia", "Sophia", "Sophie", "Summer", "Thea", "Violet", "Willow", "Zara",
]

mutable struct NamePool
    map::Dict{Person, String}
    maleNames::Vector{String}
    femaleNames::Vector{String}
end

function newPool()::NamePool
    NamePool(Dict{Person, String}(), shuffle(maleNames), shuffle(femaleNames))
end

function getName!(pool::NamePool, person::Person)::String
    get!(pool.map, person) do
        if person.gender == male
            name = pop!(pool.maleNames)
            if isempty(pool.maleNames)
                pool.maleNames = shuffle(maleNames)
            end
            return name;
        else
            name = pop!(pool.femaleNames)
            if isempty(pool.femaleNames)
                pool.femaleNames = shuffle(femaleNames)
            end
            return name;
        end
    end
end

function forgetNames!(pool::NamePool)
    empty!(pool.map)
end

end
