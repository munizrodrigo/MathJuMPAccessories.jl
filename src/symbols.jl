ⅈ = im
ⅉ = im
∑ = x -> sum(x; init=0)
∥(x) = abs(x)
∠(x) = angle(x)
∗(x) = conj(x)
ℜ(x) = real(x)
ℑ(x) = imag(x)
∧(x::Bool, y::Bool) = x && y
∧(x, y) = Bool(x) && Bool(y)
∨(x::Bool, y::Bool) = x || y
∨(x, y) = Bool(x) || Bool(y)
⋅(x, y) = x * y
\(x::Set, y::Set) = setdiff(x, y)
\(x::OrderedSet, y::OrderedSet) = setdiff(x, y)
\(x::AbstractSet, y::AbstractSet) = setdiff(x, y)
Ω(x::Vararg{Set}) = Set(zip(x...))
Ω(x::Vararg{OrderedSet}) = OrderedSet(zip(x...))
Ω(x::Vararg{AbstractSet}) = Set(zip(x...))
Ω(x::Set{Tuple{Int64, Int64}}, y::Set{OrderedSet}) = Set(zip(first.(x), last.(x), y...))
Ω(x::OrderedSet{Tuple{Int64, Int64}}, y::Vararg{OrderedSet}) = OrderedSet(zip(first.(x), last.(x), y...))
Ω(x::OrderedSet{Tuple{Int64, Int64}}, y::Vararg{AbstractSet}) = OrderedSet(zip(first.(x), last.(x), y...))

macro forall(iter::Expr, block::Expr)
    iter = string(iter)
    if occursin("∈", iter)
        iter = split(iter, "∈")
    else
        iter = split(iter, "in")
    end
    variable = strip(first(iter))
    variable = Meta.parse(variable)
    set = strip(last(iter))
    set = Meta.parse(set)
    return :(
        for $(esc(:($variable))) in $(esc(:($set)))
            $(esc(:($block)))
        end
    )
end

macro forall(statement::Expr)
    statement = string(statement)
    conditional = nothing
    if occursin("∀", statement)
        if occursin(":", statement)
            statement = split(statement, ":"; limit=2)
            expr = first(statement)
            iter = last(statement)
        else
            statement = split(statement, ","; limit=2)
            expr = first(statement)
            iter = last(statement)
            iter = iter[1:end-1]
            expr = expr[2:end]
        end
    else
        if occursin(":", statement)
            statement = rsplit(statement, ":"; limit=2)
            iter = first(statement)
            expr = last(statement)
        else
            statement = rsplit(statement, ","; limit=2)
            iter = first(statement)
            expr = last(statement)
            iter = iter[2:end]
            expr = expr[1:end-1]
        end
    end 
    if occursin("|", iter)
        iter, conditional = rsplit(iter, "|"; limit=2)
    end 
    if occursin("∈", iter)
        iter = split(iter, "∈")
    else
        iter = split(iter, "in")
    end
    variable = strip(first(iter))
    if occursin("∀", variable)
        variable = replace(variable, "∀" => "")
    end
    variable = Meta.parse(variable)
    set = strip(last(iter))
    set = Meta.parse(set)
    expr = Meta.parse(expr)
    if isnothing(conditional)
        return :(
            ($(esc(:($expr))) for $(esc(:($variable))) in $(esc(:($set))))
        )
    else
        if occursin("∧", conditional)
            conditional = replace(conditional, "∧" => "&&")
        end
        if occursin("∨", conditional)
            conditional = replace(conditional, "∨" => "||")
        end
        cond = Meta.parse(conditional)
        return :(
            ($(esc(:($expr))) for $(esc(:($variable))) in $(esc(:($set))) if $(esc(:($cond))))
        )
    end
end

var"@∀" = var"@forall"