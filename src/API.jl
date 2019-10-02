export Structure, Atom, Pseudo, DFTU
#Units exported
export Ang, e₀, kₑ, a₀, Eₕ, Ry


include("inputAPI.jl")
export DFInput
#Basic Interaction with DFInputs
export flag, setflags!, rmflags!, data, setdata!, setdataoption!, exec, execs,
       setexecflags!, rmexecflags!, setexecdir!, runcommand, outputdata

#Extended Interaction with DFInputs
export setkpoints!, readbands, readfermi, setwanenergies!, isconverged

#generating new DFInputs
export gencalc_scf, gencalc_nscf, gencalc_bands, gencalc_projwfc, gencalc_wan

include("jobAPI.jl")
#Basic Job Control Functionality
export save, submit, abort, setflow!, setheaderword!, isrunning, progressreport,
       setserverdir!, setlocaldir!, structure, scale_cell!, volume

#Basic Interaction with DFInputs inside DFJob
export searchinput, searchinputs, setcutoffs!, setname!

#Interacting with the Structure inside DFJob
export atom, atoms, setatoms!, setpseudos!, projections, setprojections!, cell,
	   set_magnetization!

export create_supercell

# Atom interface functions
export name, position_cart, position_cryst, element, pseudo, projections, magnetization, dftu
export distance, set_position!, scale_bondlength!

#Bands related functionality
export bandgap

include("serverAPI.jl")
export qstat, watch_qstat, qdel

#Slurm interactions
export slurm_history_jobdir, slurm_jobid, slurm_isrunning, slurm_mostrecent, slurm_isqueued

include("documentationAPI.jl")
export documentation, search_documentation
