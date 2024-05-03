module Z3

include("libz3.jl")
using .Libz3
export DeclareSort, _main_ctx

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

abstract type AST end

Base.show(io::IO, x::AST) = print(io, unsafe_string(Z3_ast_to_string(ctx(x), as_ast(x))))

struct Sort <: AST
    ctx::Z3_sort
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

function to_symbol(s::Union{String,Int}, ctx=nothing)
    _sym(s::String) = Z3_mk_string_symbol(_get_ctx(ctx), s)
    _sym(s::Int) = Z3_mk_int_symbol(_get_ctx(ctx), s)
    return _sym(s)
end

end