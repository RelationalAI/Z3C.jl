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
    ctx = Z3_mk_context_rc(cfg)
    c = Context(ctx)
    Z3_del_config(cfg)
    finalizer(c) do c
        Z3_del_context(c.ctx)
    end
end

function ref(c::Context)
    c.ctx
end

# Global Z3 context
const _main_ctx::Ref{Union{Context,Nothing}} = Ref{Union{Context,Nothing}}(nothing)

function main_ctx()
    global _main_ctx
    if isnothing(_main_ctx[])
        _main_ctx[] = Context()
    end
    return _main_ctx[]
end

function _get_ctx(ctx::Union{Context,Nothing})
    if isnothing(ctx)
        return main_ctx()
    else
        return ctx
    end
end

#-----#
# AST #
#-----#

abstract type AST end

Base.show(io::IO, x::AST) = print(io, unsafe_string(Z3_ast_to_string(ctx_ref(x), as_ast(x))))

#-------#
# Sorts #
#-------#

struct Sort <: AST
    ctx::Context
    ast::Z3_sort
end

as_ast(s::Sort) = Z3_sort_to_ast(ctx_ref(s), s.ast)
ctx_ref(s::Sort) = ref(s.ctx)

function DeclareSort(name::Union{String,Int}, ctx=nothing)
    ctx = _get_ctx(ctx)
    sym = to_symbol(name, ctx)
    sort = Z3_mk_uninterpreted_sort(ref(ctx), sym)
    return Sort(ctx, sort)
end

function BoolSort(ctx=nothing)
    ctx = _get_ctx(ctx)
    Sort(ctx, Z3_mk_bool_sort(ref(ctx)))
end

function IntSort(ctx=nothing)
    ctx = _get_ctx(ctx)
    Sort(ctx, Z3_mk_int_sort(ref(ctx)))
end

function BitVecSort(sz::Int, ctx=nothing)
    ctx = _get_ctx(ctx)
    Sort(ctx, Z3_mk_bv_sort(ref(ctx), sz))
end

function Float16Sort(ctx=nothing)
    ctx = _get_ctx(ctx)
    Sort(ctx, Z3_mk_fpa_sort_16(ref(ctx)))
end

function Float32Sort(ctx=nothing)
    ctx = _get_ctx(ctx)
    Sort(ctx, Z3_mk_fpa_sort_32(ref(ctx)))
end

function Float64Sort(ctx=nothing)
    ctx = _get_ctx(ctx)
    Sort(ctx, Z3_mk_fpa_sort_64(ref(ctx)))
end

#-------------#
# Expressions #
#-------------#

struct Expr <: AST
    ctx::Context
    expr::Z3_ast
end

as_ast(e::Expr) = e.expr
ctx_ref(e::Expr) = ref(e.ctx)

function BoolVal(b::Bool, ctx=nothing)
    ctx = _get_ctx(ctx)
    Expr(ctx, b ? Z3_mk_true(ref(ctx)) : Z3_mk_false(ref(ctx)))
end

function IntVal(n::Integer, ctx=nothing)
    ctx = _get_ctx(ctx)
    Expr(ctx, Z3_mk_numeral(ref(ctx), string(n), IntSort(ctx).ast))
end

function BitVecVal(v::Integer, sz::Int, ctx=nothing)
    ctx = _get_ctx(ctx)
    Expr(ctx, Z3_mk_numeral(ref(ctx), string(v), BitVecSort(sz, ctx).ast))
end

function Float32Val(v::Float32, ctx=nothing)
    ctx = _get_ctx(ctx)
    Expr(ctx, Z3_mk_fpa_numeral_float(ref(ctx), v, Float32Sort(ctx).ast))
end

function Float64Val(v::Float64, ctx=nothing)
    ctx = _get_ctx(ctx)
    Expr(ctx, Z3_mk_fpa_numeral_double(ref(ctx), v, Float64Sort(ctx).ast))
end

# function FP(name::String, fpsort::Sort)
#     Expr(fpsort.ctx, Z3_mk_const(ref(fpsort.ctx), to_symbol(name, fpsort.ctx), fpsort.ast))
# end

# (==)(a::Expr, b::Expr) = Expr(Z3_mk_eq(_get_ctx(), as_ast(a), as_ast(b)))

#--------#
# Solver #
#--------#

# mutable struct Solver
#     solver::Z3_solver
# end

# function Solver()
#     Solver(Z3_mk_solver(_get_ctx()))
# end

# function del_solver(s::Solver)
#     Z3_solver_dec_ref(_get_ctx(), s.solver)
# end

# function add(s::Solver, e::Expr)
#     Z3_solver_assert(_get_ctx(), s.solver, as_ast(e))
# end

# function push(s::Solver)
#     Z3_solver_push(_get_ctx(), s.solver)
# end

# function pop(s::Solver, n=1)
#     Z3_solver_pop(_get_ctx(), s.solver, n)
# end

# struct Model
#     model::Z3_model
# end

# model(s::Solver) = Model(Z3_solver_get_model(_get_ctx(), s.solver))

# function Base.show(io::IO, m::Model)
#     print(io, unsafe_string(Z3_model_to_string(_get_ctx(), m.model)))
# end

# struct CheckResult
#     result::Z3_lbool
# end

# CheckResult(r::Symbol) = r == :sat ? CheckResult(Z3_L_TRUE) : r == :unsat ? CheckResult(Z3_L_FALSE) : CheckResult(Z3_L_UNDEF) 

# function Base.show(io::IO, r::CheckResult)
#     print(io, r.result == Z3_L_TRUE ? "sat" : r.result == Z3_L_FALSE ? "unsat" : "unknown")
# end

# check(s::Solver) = CheckResult(Z3_solver_check(_get_ctx(), s.solver))

#--------#
# Others #
#--------#

function to_symbol(s::Union{String,Int}, ctx=nothing)
    c = ref(_get_ctx(ctx))
    _sym(s::String) = Z3_mk_string_symbol(c, s)
    _sym(s::Int) = Z3_mk_int_symbol(c, s)
    return _sym(s)
end

end