module Z3

include("libz3.jl")
using .Libz3
import Base: ==
export init_ctx, clear_ctx, DeclareSort, BoolSort, IntSort, BitVecSort, Float16Sort, Float32Sort, Float64Sort,
BoolVal, IntVal, BitVecVal, Float32Val, Float64Val, 
FP,
Solver, del_solver, add, push, pop, check, CheckResult, model

#---------#
# Context #
#---------#

mutable struct Context
    ctx::Z3_context
end

function Context()
    cfg = Z3_mk_config()
    ctx = Z3_mk_context(cfg)
    Z3_del_config(cfg)
    return Context(ctx)
end

# Global Z3 context
const _main_ctx::Ref{Union{Context,Nothing}} = Ref{Union{Context,Nothing}}(nothing)

function init_ctx()
    global _main_ctx
    @assert isnothing(_main_ctx[]) "Context already initialized"
    _main_ctx[] = Context()
end

function _get_ctx()
    @assert !isnothing(_main_ctx[]) "Context not initialized"
    return _main_ctx[].ctx
end

function clear_ctx()
    global _main_ctx
    @assert !isnothing(_main_ctx[]) "Context not initialized"
    Z3_del_context(_main_ctx[].ctx)
    _main_ctx[] = nothing
end

#-----#
# AST #
#-----#

abstract type AST end

Base.show(io::IO, x::AST) = print(io, unsafe_string(Z3_ast_to_string(_get_ctx(), as_ast(x))))

#-------#
# Sorts #
#-------#

struct Sort <: AST
    sort::Z3_sort
end

as_ast(s::Sort) = Z3_sort_to_ast(_get_ctx(), s.sort)

function DeclareSort(name::Union{String,Int})
    sym = to_symbol(name)
    sort = Z3_mk_uninterpreted_sort(_get_ctx(), sym)
    return Sort(sort)
end

BoolSort() = Sort(Z3_mk_bool_sort(_get_ctx()))
IntSort() = Sort(Z3_mk_int_sort(_get_ctx()))
BitVecSort(sz::Int) = Sort(Z3_mk_bv_sort(_get_ctx(), sz))
Float16Sort() = Sort(Z3_mk_fpa_sort_16(_get_ctx()))
Float32Sort() = Sort(Z3_mk_fpa_sort_32(_get_ctx()))
Float64Sort() = Sort(Z3_mk_fpa_sort_64(_get_ctx()))

#-------------#
# Expressions #
#-------------#

struct Expr <: AST
    expr::Z3_ast
end

as_ast(e::Expr) = e.expr

BoolVal(b::Bool) = Expr(b ? Z3_mk_true(_get_ctx()) : Z3_mk_false(_get_ctx()))

IntVal(n::Integer) = Expr(Z3_mk_numeral(_get_ctx(), string(n), IntSort().sort))

BitVecVal(v::Integer, sz::Int) = Expr(Z3_mk_numeral(_get_ctx(), string(v), BitVecSort(sz).sort))

# Float16Val(v::Float16) = Expr(Z3_mk_fpa_numeral_float(_get_ctx(), v, Float16Sort().sort))
Float32Val(v::Float32) = Expr(Z3_mk_fpa_numeral_float(_get_ctx(), v, Float32Sort().sort))
Float64Val(v::Float64) = Expr(Z3_mk_fpa_numeral_double(_get_ctx(), v, Float64Sort().sort))

FP(name::String, fpsort::Sort) = Expr(Z3_mk_const(_get_ctx(), to_symbol(name), fpsort.sort))

(==)(a::Expr, b::Expr) = Expr(Z3_mk_eq(_get_ctx(), as_ast(a), as_ast(b)))

#--------#
# Solver #
#--------#

mutable struct Solver
    solver::Z3_solver
end

function Solver()
    Solver(Z3_mk_solver(_get_ctx()))
end

function del_solver(s::Solver)
    Z3_solver_dec_ref(_get_ctx(), s.solver)
end

function add(s::Solver, e::Expr)
    Z3_solver_assert(_get_ctx(), s.solver, as_ast(e))
end

function push(s::Solver)
    Z3_solver_push(_get_ctx(), s.solver)
end

function pop(s::Solver, n=1)
    Z3_solver_pop(_get_ctx(), s.solver, n)
end

struct Model
    model::Z3_model
end

model(s::Solver) = Model(Z3_solver_get_model(_get_ctx(), s.solver))

function Base.show(io::IO, m::Model)
    print(io, unsafe_string(Z3_model_to_string(_get_ctx(), m.model)))
end

struct CheckResult
    result::Z3_lbool
end

CheckResult(r::Symbol) = r == :sat ? CheckResult(Z3_L_TRUE) : r == :unsat ? CheckResult(Z3_L_FALSE) : CheckResult(Z3_L_UNDEF) 

function Base.show(io::IO, r::CheckResult)
    print(io, r.result == Z3_L_TRUE ? "sat" : r.result == Z3_L_FALSE ? "unsat" : "unknown")
end

check(s::Solver) = CheckResult(Z3_solver_check(_get_ctx(), s.solver))

#--------#
# Others #
#--------#

function to_symbol(s::Union{String,Int})
    _sym(s::String) = Z3_mk_string_symbol(_get_ctx(), s)
    _sym(s::Int) = Z3_mk_int_symbol(_get_ctx(), s)
    return _sym(s)
end

end