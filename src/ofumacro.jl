"""
```
macro ofu_str(unit)
```

String macro to easily recall oil-field units located in the `UnitfulOfu`
package. Although all unit symbols in that package are suffixed with `_ofu`,
the suffix should not be used when using this macro.

Note that what goes inside must be parsable as a valid Julia expression.

Examples:

```jldoctest
julia> 1.0ofu"lbf"
4.45 N

julia> 5.0ofu"rpm" - 1//60u"Hz"
4.0 Hz
```
"""
macro ofu_str(unit)
    ex = parse(unit)
    esc(replace_value(ex))
end

const allowed_funcs = [:*, :/, :^, :sqrt, :√, :+, :-, ://]
function replace_value(ex::Expr)
    if ex.head == :call
        ex.args[1] in allowed_funcs ||
            error("""$(ex.args[1]) is not a valid function call when parsing a unit.
             Only the following functions are allowed: $allowed_funcs""")
        for i=2:length(ex.args)
            if typeof(ex.args[i])==Symbol || typeof(ex.args[i])==Expr
                ex.args[i]=replace_value(ex.args[i])
            end
        end
        return ex
    elseif ex.head == :tuple
        for i=1:length(ex.args)
            if typeof(ex.args[i])==Symbol
                ex.args[i]=replace_value(ex.args[i])
            else
                error("only use symbols inside the tuple.")
            end
        end
        return ex
    else
        error("Expr head $(ex.head) must equal :call or :tuple")
    end
end

dottify(s, t, u...) = dottify(Expr(:(.), s, QuoteNode(t)), u...)
dottify(s) = s

function replace_value(sym::Symbol)
    s = Symbol(sym, :_us)
    if !isdefined(UnitfulOfu, s)
        error("Symbol $s could not be found in UnitfulUS.")
    end

    expr = Expr(:(.), dottify(fullname(UnitfulOfu)...), QuoteNode(s))
    return :(UnitfulOfu.ustrcheck($expr))
end

replace_value(literal::Number) = literal

ustrcheck(x::Unitful.Unitlike) = x
ustrcheck(x::Unitful.Quantity) = x
ustrcheck(x) = error("Symbol $x is not a unit or quantity.")
