module Z3

include("libz3.jl")
using .Libz3

ctx = Z3_mk_context(Z3_mk_config())
sym = Z3_mk_string_symbol(ctx, "foo")
sort = Z3_mk_uninterpreted_sort(ctx, sym)
s = Z3_sort_to_string(ctx, sort)

@info unsafe_string(s)

end
