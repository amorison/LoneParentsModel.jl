include("mainHelpers.jl")

include("analysis.jl")

using GLMakie
import LoneParentsModel.Tracking


include("guiHelpers.jl")

function main(parOverrides...)
    args = copy(ARGS)

    for pov in parOverrides
        push!(args, string(pov))
    end

    # need to do that first, otherwise it blocks the GUI
    simPars, pars, args = loadParameters(args)

    model = setupModel(pars)
    logfile = setupLogging(simPars)
    
# *** Window 1

    GLMakie.activate!()
    fig = Figure(size=(1600,900))
    
    obs_hc, positions, obs_positions_c, obs_positions_p, obs_positions_s = 
        create_map!(fig[1:2, 1], model)

    obs_agent1_main = Observable("")
    Label(fig[3, 1][1, 1], obs_agent1_main, tellwidth=false, justification=:left)
    obs_agent2_main = Observable("")
    Label(fig[3, 1][1, 2], obs_agent2_main, tellwidth=false, justification=:left)
    
    followed_agent = Tracking.pickAgent(model)
    
    obs_pop, ax_pop = create_series(fig[1, 2], ["population size", "#married", "working", "unemployed"];
        axis=(; xticks=LTTicks(WilkinsonTicks(5), 1920.0, 1/12)))

    obs_hh_log = Observable("")
    Label(fig[1, 3][1, 1], obs_hh_log, tellwidth=false, tellheight=false, justification=:left, valign=:top, halign=:left, fontsize=15)
    obs_hh_occupants = Observable("")
    Label(fig[1, 3][1, 2], obs_hh_occupants, tellwidth=false, tellheight=false, justification=:left, valign=:top, halign=:left, fontsize=20)

    obs_careneed, ax_careneed = create_barplot(fig[2,2][1,1], "care need")
    obs_class, ax_class = create_barplot(fig[2,2][1,2], "social class")
    obs_nchildren, ax_nchildren = create_barplot(fig[2,2][2,1], "n children")
    obs_age, ax_age = create_barplot(fig[2, 2][2, 2], "population pyramid"; direction=:x)
    
    obs_care, ax_care = create_series(fig[2,3], ["care supply", "unmet care need"],
        axis=(; xticks=LTTicks(WilkinsonTicks(5), 1920.0, 1/12)))
        
# *** Window 2
    
    display(GLMakie.Screen(), fig)
    
# *** buttons    
    
    runbutton = Button(fig[3,3][1,1]; label = "run", tellwidth = false)    
    pause = Observable(false)
    on(runbutton.clicks) do clicks; pause[] = !pause[]; end
    quitbutton = Button(fig[3,3][1,2]; label = "quit", tellwidth = false)    
    goon = Observable(true)
    on(quitbutton.clicks) do clicks; goon[]=false; end
    
    obs_year = Observable("")
    Label(fig[3,2][1,1], obs_year, tellwidth=false, fontsize=25)
    
    randbutton = Button(fig[3,2][1,2]; label = "agent", tellwidth = false)
    on(randbutton.clicks) do clicks; followed_agent = Tracking.pickAgent(model); end
    
# *** simulation
    
    time = Rational(pars.poppars.startTime)
    while goon[]

        if !pause[] && time <= pars.poppars.finishTime
            stepModel!(model, time, pars)
            time += simPars.dt
            data = observe(Data, model, time, pars)
            log_results(logfile, data)
            
            # add values to graph objects
            add_series_point!(obs_pop[][1], data.alive.n)
            add_series_point!(obs_pop[][2], data.married.n)
            add_series_point!(obs_pop[][3], data.employed.n)
            add_series_point!(obs_pop[][4], data.unemployed.n)
            
            #push!(obs_care[][1], data.care_supply.mean)
            #push!(obs_care[][2], data.unmet_care.mean)
            add_series_point!(obs_care[][1], data.av_care_time.mean)
            add_series_point!(obs_care[][2], data.open_tasks.mean)
            
            setto!(obs_careneed[], data.careneed.bins)
            setto!(obs_class[], data.class.bins)
            setto!(obs_nchildren[], data.n_children.bins)
            
            setto!(obs_age[], data.age.bins)
            
            update_house_colors!(obs_hc[], model.houses)
            #setto!(dat_f_status, data.f_status.bins)
            #setto!(dat_m_status, data.m_status.bins)
            
            
            println(data.hh_size.max, " ", data.alive.n, " ", data.single.n, 
                    " ", data.income.mean)
        end
        
        if pause[]
            sleep(0.001)
        end
        Tracking.update!(followed_agent, time)
        update_network!(positions, followed_agent.agent, model.town_size)

        notify(obs_hc)
        notify(obs_positions_c)
        notify(obs_positions_p)
        notify(obs_positions_s)
        
        notify(obs_pop)
        autolimits!(ax_pop)
        
        notify(obs_care)
        autolimits!(ax_care)
        
        notify(obs_careneed)
        autolimits!(ax_careneed)
        notify(obs_class)
        autolimits!(ax_class)
        notify(obs_nchildren)
        autolimits!(ax_nchildren)
        
        notify(obs_age)
        autolimits!(ax_age)

        (obs_agent1_main[], obs_agent2_main[]) = Tracking.describeAgent(followed_agent)
        obs_hh_log[] = Tracking.currentLog(followed_agent)
        obs_hh_occupants[] = Tracking.describeOccupants(followed_agent)

        year, month = date2yearsmonths(time)
        obs_year[] = "$(year)/$(month+1)"
    end


    close(logfile)
end

if ! isinteractive()
    main()
end
