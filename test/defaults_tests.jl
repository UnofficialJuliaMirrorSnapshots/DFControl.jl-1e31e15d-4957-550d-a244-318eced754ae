
using DFControl, Test
import DFControl: Exec, data, execs

prevdefault = getdefault_server()
setdefault_server("localhost")
setdefault_pseudodir(:test, joinpath(testdir, "testassets", "pseudos"))
configuredefault_pseudos(pseudo_dirs=Dict(:test => getdefault_pseudodirs()[:test]))

@test DFControl.getdefault_pseudo(:Pt, :test, specifier="UPF") == Pseudo("Pt.UPF",joinpath(testdir, "testassets", "pseudos"))
@test DFControl.getdefault_server() == "localhost"
