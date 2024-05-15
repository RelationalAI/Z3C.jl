module Z3

include("libz3.jl")
using .Libz3
import Base: ==
export DeclareSort, BoolSort, IntSort, BoolVal, IntVal, Solver, add, push, pop, check, CheckResult

#---------#
# Context #
#---------#

# Making struct mutable to register a finalizer
mutable struct Context
    ctx::Z3_context
end

function Context()
    cfg = Z3_mk_config()
    ctx = Z3_mk_context(cfg)
    Z3_del_config(cfg)
    finalizer(Context(ctx)) do c 
        Z3_del_context(c.ctx)
    end
end

# Global Z3 context
const _main_ctx::Ref{Union{Context,Nothing}} = Ref{Union{Context,Nothing}}(nothing)

function main_ctx()
    global _main_ctx
    if _main_ctx[] === nothing
        _main_ctx[] = Context()
    end
    return _main_ctx[]
end

function _get_ctx(ctx::Union{Context,Nothing})
    if ctx === nothing
        return main_ctx().ctx
    else
        return ctx.ctx
    end
end

#-----#
# AST #
#-----#

abstract type AST end

Base.show(io::IO, x::AST) = print(io, unsafe_string(Z3_ast_to_string(ctx(x), as_ast(x))))

#-------#
# Sorts #
#-------#

struct Sort <: AST
    ctx::Z3_context
    sort::Z3_sort
end

function Sort(s::Z3_sort, ctx=nothing)
    c = _get_ctx(ctx)
    return Sort(c, s)
end

ctx(s::Sort) = s.ctx

as_ast(s::Sort) = Z3_sort_to_ast(ctx(s), s.sort)

function DeclareSort(name::Union{String,Int}, ctx=nothing)
    sym = to_symbol(name, ctx)
    sort = Z3_mk_uninterpreted_sort(_get_ctx(ctx), sym)
    return Sort(sort)
end

BoolSort(ctx=nothing) = Sort(Z3_mk_bool_sort(_get_ctx(ctx)))
IntSort(ctx=nothing) = Sort(Z3_mk_int_sort(_get_ctx(ctx)))

#-------------#
# Expressions #
#-------------#

struct Expr <: AST
    ctx::Z3_context
    expr::Z3_ast
end

function Expr(expr::Z3_ast, ctx=nothing)
    c = _get_ctx(ctx)
    return Expr(c, expr)
end

ctx(e::Expr) = e.ctx

as_ast(e::Expr) = e.expr

BoolVal(b::Bool, ctx=nothing) = Expr(b ? Z3_mk_true(_get_ctx(ctx)) : Z3_mk_false(_get_ctx(ctx)))

IntVal(n::Integer, ctx=nothing) = Expr(Z3_mk_numeral(_get_ctx(ctx), string(n), IntSort(ctx).sort))

(==)(a::Expr, b::Expr) = Expr(Z3_mk_eq(ctx(a), as_ast(a), as_ast(b)))


#--------#
# Solver #
#--------#

mutable struct Solver
    ctx::Z3_context
    solver::Z3_solver
end

function Solver(ctx=nothing)
    c = _get_ctx(ctx)
    s = Z3_mk_solver(c)
    finalizer(Solver(c, s)) do s
        Z3_dec_ref(s.ctx, s.solver)
    end
end

function add(s::Solver, e::Expr)
    Z3_solver_assert(s.ctx, s.solver, as_ast(e))
end

function push(s::Solver)
    Z3_solver_push(s.ctx, s.solver)
end

function pop(s::Solver, n=1)
    Z3_solver_pop(s.ctx, s.solver, n)
end

struct CheckResult
    result::Z3_lbool
end

CheckResult(r::Symbol) = r == :sat ? CheckResult(Z3_L_TRUE) : r == :unsat ? CheckResult(Z3_L_FALSE) : CheckResult(Z3_L_UNDEF) 

function Base.show(io::IO, r::CheckResult)
    print(io, r.result == Z3_L_TRUE ? "sat" : r.result == Z3_L_FALSE ? "unsat" : "unknown")
end

check(s::Solver) = CheckResult(Z3_solver_check(s.ctx, s.solver))

#--------#
# Others #
#--------#

function to_symbol(s::Union{String,Int}, ctx=nothing)
    _sym(s::String) = Z3_mk_string_symbol(_get_ctx(ctx), s)
    _sym(s::Int) = Z3_mk_int_symbol(_get_ctx(ctx), s)
    return _sym(s)
end

end