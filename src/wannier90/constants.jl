const WAN_EXECS= ["wannier90.x"]
include(joinpath(depsdir, "wannier90flags.jl"))
const WAN_FLAGS = _WAN_FLAGS()
flagtype(::Type{Wannier90}, flag) = haskey(WAN_FLAGS, flag) ? WAN_FLAGS[flag] : Nothing
flagtype(::DFInput{Wannier90}, flag) = flagtype(Wannier90, flag)
