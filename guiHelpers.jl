using LoneParentsModel.TasksAM
using LoneParentsModel.Tasks

struct LTTicks{T}
    ticks::T
    offset::Float64
    slope::Float64
end

function Makie.get_ticks(lt::LTTicks, scale, formatter, vmin, vmax)
    lims_transformed = (vmin, vmax) .* lt.slope .+ lt.offset
    tickvals_transformed, ticklabels = Makie.get_ticks(lt.ticks, scale, formatter, lims_transformed...)
    tickvals_untransformed = (tickvals_transformed .- lt.offset) ./ lt.slope
    return tickvals_untransformed, ticklabels
end


function proportions(histo)
    hsum = sum(histo)
    histo ./ hsum
end


function setto!(a1::AbstractVector, a2::AbstractVector)
    resize!(a1, length(a2))
    a1[:] = a2
end

t_pos(t, town_size) = t.pos[1] * (town_size + 1), (12-t.pos[2]) * (town_size + 1)
h_pos(h, town_size) = t_pos(h.town, town_size) .+ h.pos

coords(agent, town_size) = h_pos(agent.pos, town_size)

const h_red = colorant"red"
const h_black = colorant"black"


function update_house_colors!(cols, houses)
    empty!(cols)
    for h in houses
        push!(cols, isempty(h.occupants) ? h_black : h_red)
    end
end

# draw map with towns, houses and focal agent
function create_map!(fig, model)
# *** map (towns = green land, otherwise blue water)
    #ax_left = Axis(fig[1:2, 1])
    towns = [Rect(t_pos(t, model.town_size)..., model.town_size, model.town_size) for t in model.towns]
    colors = [(isempty(t.houses) ? colorant"blue" : colorant"green") for t in model.towns]
    ax_left, _ = poly(fig, towns, color = colors)
    hidespines!(ax_left)
    hidedecorations!(ax_left)
    
# *** houses, colour marks occupancy
    houses = [h_pos(h, model.town_size) for h in model.houses]
    colors = typeof(h_red)[]
    update_house_colors!(colors, model.houses)
    obs_hc = Observable(colors)
    scatter!(houses, color=obs_hc, marker=:rect, markersize=1, markerspace=:data)
    
# *** connections between focal agent and relatives
    positions = Vector{Vector{Tuple{Int, Int}}}()
    push!(positions, [])
    push!(positions, [])
    push!(positions, [])
    obs_positions_c = Observable(positions[1])
    obs_positions_p = Observable(positions[2])
    obs_positions_s = Observable(positions[3])
    lines!(obs_positions_c, color=:yellow)
    lines!(obs_positions_p, color=:black)
    lines!(obs_positions_s, color=:blue)
    
    # return all observables; changing these updates the map
    obs_hc, positions, obs_positions_c, obs_positions_p, obs_positions_s
end

# update network of relatives for agent
function update_network!(positions, agent, town_size)
    empty!.(positions)
    ac = coords(agent, town_size)
    for c in agent.children
        if !c.alive
            continue
        end
        push!(positions[1], ac)
        push!(positions[1], coords(c, town_size))
    end
    for c in parents(agent)
        if isUndefined(c) || !c.alive
            continue
        end
        push!(positions[2], ac)
        push!(positions[2], coords(c, town_size))
    end
    for c in siblings(agent)
        if isUndefined(c) || !c.alive
            continue
        end
        push!(positions[3], ac)
        push!(positions[3], coords(c, town_size))
    end
end

function add_series_point!(arr, dat, dx = 1)
    push!(arr, Point2(arr[end][1]+1, dat))
end

function create_series(fig, labels; args...)
    data = [ [Point2(1, 0.0)] for l in labels ]
    obsable = Observable(data)
    
    axis, _ = series(fig, obsable; labels=labels, args...)
    axislegend(axis, position = :lt)
    
    obsable, axis
end

function create_barplot(fig, label; args...)
    obsable = Observable([0.0])
    
    axis, _ = barplot(fig, obsable; label=label, args...)
    axislegend(axis)
    
    obsable, axis
end
