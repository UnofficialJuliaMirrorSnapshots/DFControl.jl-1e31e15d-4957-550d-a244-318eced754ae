const SymAnyDict = Dict{Symbol, Any}
const Vec{N, T} = SVector{N, T}
const Point = Vec
const Point3 = Point{3}
const Vec3   = Vec{3}
const Mat3{T} = SMatrix{3, 3, T}
const Mat4{T} = SMatrix{4, 4, T}

Point{N, T}(x::T) where {N, T} = Point{N, T}(x, x, x)

Base.convert(::Type{Point3{T}}, x::Vector{T}) where T<:AbstractFloat = Point3{T}(x[1], x[2], x[3])

abstract type Band end

"""
Energy band from DFT calculation.
"""
mutable struct DFBand{T<:AbstractFloat} <: Band
    k_points_cart  ::Vector{Vec3{T}}
    k_points_cryst ::Vector{Vec3{T}}
    eigvals        ::Vector{T}
    extra          ::Dict{Symbol, Any}
end
DFBand(k_points_cart, k_points_cryst, eigvals) = DFBand(k_points_cart, k_points_cryst, eigvals, Dict{Symbol,Any}())
DFBand(::Type{T}, vlength::Int) where T = DFBand(Vector{Vec3{T}}(undef, vlength), Vector{Vec3{T}}(undef, vlength), Vector{T}(undef, vlength), SymAnyDict())
DFBand(vlength::Int) = DFBand(Float64, vlength)


kpoints(band::DFBand, kind=:cryst) = kind == :cart ? band.k_points_cart : band.k_points_cryst


mutable struct ExecFlag
    symbol     ::Symbol
    name       ::String
    typ        ::Type
    description::String
    value
end

ExecFlag(e::ExecFlag, value) = ExecFlag(e.symbol, e.name, e.typ, e.description, value)
ExecFlag(p::Pair{Symbol, T}) where T = ExecFlag(first(p), String(first(p)), T, "", last(p))

const QEEXECFLAGS = ExecFlag[
    ExecFlag(:nk, "kpoint-pools", Int, "groups k-point parallelization into nk processor pools", 0),
    ExecFlag(:ntg, "task-groups", Int, "FFT task groups", 0),
    ExecFlag(:ndiag, "diag", Int, "Number of processes for linear algebra", 0)
]

qeexecflag(flag::AbstractString) = getfirst(x -> x.name==flag, QEEXECFLAGS)
qeexecflag(flag::Symbol) = getfirst(x -> x.symbol==flag, QEEXECFLAGS)

function parse_qeexecflags(line::Vector{<:AbstractString})
    flags = ExecFlag[]
    i=1
    while i<=length(line)
        s = strip(line[i], '-')
        push!(flags, ExecFlag(qeexecflag(Symbol(s)), parse(Int, line[i+1])))
        i += 2
    end
    flags
end

const WANEXECFLAGS = ExecFlag[
    ExecFlag(:pp, "preprocess", Nothing, "Whether or not to preprocess the wannier input", nothing),
]

wanexecflag(flag::AbstractString) = getfirst(x -> x.name==flag, WANEXECFLAGS)
wanexecflag(flag::Symbol) = getfirst(x -> x.symbol==flag, WANEXECFLAGS)
function parse_wanexecflags(line::Vector{<:AbstractString})
    flags = ExecFlag[]
    i=1
    while i<=length(line)
        s = strip(line[i], '-')
        push!(flags, ExecFlag(wanexecflag(Symbol(s)), nothing))
        i += 1
    end
    flags
end

include(joinpath(depsdir, "mpirunflags.jl"))
const MPIFLAGS = _MPIFLAGS()

mpiflag(flag::AbstractString) = getfirst(x -> x.name==flag, MPIFLAGS)
mpiflag(flag::Symbol) = getfirst(x -> x.symbol==flag, MPIFLAGS)

function mpi_flag_val(::Type{String}, line, i)
    v = line[i+1]
    return v, i + 2
end

function mpi_flag_val(::Type{Vector{String}}, line, i)
    tval = String[]
    while i+1 <= length(line) && !occursin('-', line[i+1])
        push!(tval, line[i+1])
        i += 1
    end
    return tval, i + 1
end

function mpi_flag_val(::Type{Int}, line, i)
    if line[i+1][1] == '\$'
        tval = line[i+1]
    else
        tval = parse(Int, line[i+1])
    end
    return tval, i + 2
end

function mpi_flag_val(::Type{Vector{Int}}, line, i)
    tval = Union{Int, String}[]
    while i+1 <= length(line) && !occursin('-', line[i+1])
        if line[i+1][1] == '\$'
            push!(tval, line[i+1])
        else
            push!(tval, parse(Int, line[i+1]))
        end
        i += 1
    end
    return tval, i + 1
end

function mpi_flag_val(::Type{Pair{Int, String}}, line, i)
    tval = Union{Int, String}[]
    while i+1<=length(line) && !occursin('-', line[i+1])
        if line[i+1][1] == '\$'
            push!(tval, line[i+1])
        else
            tparse = tryparse(Int, line[i+1])
            if tparse != nothing
                push!(tval, tparse)
            else
                push!(tval, string(line[i+1]))
            end
        end
        i += 1
    end
    return tval, i + 1
end
function parse_mpiflags(line::Vector{<:SubString})
    eflags = ExecFlag[]
    i = 1
    while i <= length(line)
        s = line[i]
        if s[1] != '-'
            break
        end
        if s[2] == '-'
            mflag = mpiflag(strip(s, '-'))
        else
            mflag = mpiflag(Symbol(strip(s, '-')))
        end

        @assert mflag != nothing "$(strip(s, '-')) is not a recognized mpiflag"
        val, i = mpi_flag_val(mflag.typ, line, i)
        push!(eflags, ExecFlag(mflag, val))
    end
    eflags
end

const RUNEXECS = ["mpirun"]
allexecs() = vcat(RUNEXECS, QEEXECS, WANEXECS)
parseable_execs() = vcat(QEEXECS, WANEXECS)

mutable struct Exec
    exec ::String
    dir  ::String
    flags::Vector{ExecFlag}
end

Exec() = Exec("")
Exec(exec::String) = Exec(exec, "")
Exec(exec::String, dir::String) = Exec(exec, dir, ExecFlag[])
Exec(exec::String, dir::String, flags...) = Exec(exec, dir, SymAnyDict(flags))
function Exec(exec::String, dir::String, flags::SymAnyDict)
    _flags = ExecFlag[]
    for (f, v) in flags
        push!(_flags, ExecFlag(f => v))
    end
    return Exec(exec, dir, _flags)
end

isparseable(exec::Exec) = exec.exec ∈ parseable_execs()

function inputparser(exec::Exec)
    if exec.exec ∈ QEEXECS
        qe_read_input
    elseif exec.exec ∈ WANEXECS
        read_wannier_input
    end
end

function setflags!(exec::Exec, flags...)
    for (f, val) in flags
        flag = isa(f, String) ? getfirst(x -> x.name == f, exec.flags) : getfirst(x -> x.symbol == f, exec.flags)
        if flag != nothing
            flag.value = convert(flag.typ, val)
        end
    end
    exec.flags
end
function rmflags!(exec::Exec, flags...)
    for f in flags
        if isa(f, String)
            filter!(x -> x.name != f, exec.flags)
        elseif isa(f, Symbol)
            filter!(x -> x.symbol != f, exec.flags)
        end
    end
    exec.flags
end
hasflag(exec::Exec, s::Symbol) = findfirst(x->x.symbol == s, exec.flags) != nothing
setexecdir!(exec::Exec, dir) = exec.dir = dir