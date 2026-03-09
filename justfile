# run cli entry point
run: instantiate
    julia --project=. ./main.jl

# run GUI entry point
run-gui: instantiate
    julia --project=. ./mainGui.jl

# instantiate project
instantiate:
    julia --project=. -e 'using Pkg; Pkg.instantiate()'
