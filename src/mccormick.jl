struct McCormick{T <: Number}
    info::JuMP.VariableInfo
    x::JuMP.VariableRef
    y::JuMP.VariableRef
    xₗᵢₘ::Vector{T}
    yₗᵢₘ::Vector{T}
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{McCormick};
    kwargs...
)
    return McCormick(info, kwargs[:x], kwargs[:y], kwargs[:xₗᵢₘ], kwargs[:yₗᵢₘ])
end

function JuMP.add_variable(
    model::JuMP.Model,
    mccormick::McCormick,
    name::String,
)
    w = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(mccormick.info),
        "$(name)"
    )

    x = mccormick.x
    xₗᵢₘ = mccormick.xₗᵢₘ
    y = mccormick.y
    yₗᵢₘ = mccormick.yₗᵢₘ

    xᴸ = first(xₗᵢₘ)
    xᵁ = last(xₗᵢₘ)
    yᴸ = first(yₗᵢₘ)
    yᵁ = last(yₗᵢₘ)

    JuMP.@constraint(model, w >= xᴸ * y + yᴸ * x - xᴸ * yᴸ, base_name="McCormick($(JuMP.name(x)), $(JuMP.name(y))) := {$(name)ₘᵢₙ₁")
    JuMP.@constraint(model, w >= xᵁ * y + yᵁ * x - xᵁ * yᵁ, base_name="McCormick($(JuMP.name(x)), $(JuMP.name(y))) := {$(name)ₘᵢₙ₂")
    JuMP.@constraint(model, w <= xᴸ * y + yᵁ * x - xᴸ * yᵁ, base_name="McCormick($(JuMP.name(x)), $(JuMP.name(y))) := {$(name)ₘₐₓ₁")
    JuMP.@constraint(model, w <= yᴸ * x + xᵁ * y - yᴸ * xᵁ, base_name="McCormick($(JuMP.name(x)), $(JuMP.name(y))) := {$(name)ₘₐₓ₂")
    
    return w
end

struct UpperMcCormick{T <: Number}
    info::JuMP.VariableInfo
    x::JuMP.VariableRef
    y::JuMP.VariableRef
    xₗᵢₘ::Vector{T}
    yₗᵢₘ::Vector{T}
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{UpperMcCormick};
    kwargs...
)
    return UpperMcCormick(info, kwargs[:x], kwargs[:y], kwargs[:xₗᵢₘ], kwargs[:yₗᵢₘ])
end

function JuMP.add_variable(
    model::JuMP.Model,
    mccormick::UpperMcCormick,
    name::String,
)
    w = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(mccormick.info),
        "$(name)"
    )

    x = mccormick.x
    xₗᵢₘ = mccormick.xₗᵢₘ
    y = mccormick.y
    yₗᵢₘ = mccormick.yₗᵢₘ

    xᴸ = first(xₗᵢₘ)
    xᵁ = last(xₗᵢₘ)
    yᴸ = first(yₗᵢₘ)
    yᵁ = last(yₗᵢₘ)

    JuMP.@constraint(model, w >= xᴸ * y + yᴸ * x - xᴸ * yᴸ, base_name="McCormick($(JuMP.name(x)), $(JuMP.name(y))) := {$(name)ₘᵢₙ₁")
    JuMP.@constraint(model, w >= xᵁ * y + yᵁ * x - xᵁ * yᵁ, base_name="McCormick($(JuMP.name(x)), $(JuMP.name(y))) := {$(name)ₘᵢₙ₂")

    return w
end

struct QuadraticMcCormick{T <: Number}
    info::JuMP.VariableInfo
    x::JuMP.VariableRef
    xₗᵢₘ::Vector{T}
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{QuadraticMcCormick};
    kwargs...
)
    return QuadraticMcCormick(info, kwargs[:x], kwargs[:xₗᵢₘ])
end

function JuMP.add_variable(
    model::JuMP.Model,
    mccormick::QuadraticMcCormick,
    name::String,
)
    w = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(mccormick.info),
        "$(name)"
    )

    x = mccormick.x
    xₗᵢₘ = mccormick.xₗᵢₘ

    xᴸ = first(xₗᵢₘ)
    xᵁ = last(xₗᵢₘ)

    JuMP.@constraint(model, w >= -xᴸ^2 + 2 * xᴸ * x, base_name="McCormick($(JuMP.name(x))²) := {$(name)ₘᵢₙ¹")
    JuMP.@constraint(model, w >= -xᵁ^2 + 2 * xᵁ * x, base_name="McCormick($(JuMP.name(x))²) := {$(name)ₘᵢₙ²")
    JuMP.@constraint(model, w <= (xᴸ + xᵁ) * x - (xᴸ * xᵁ), base_name="McCormick($(JuMP.name(x))²) := {$(name)ₘₐₓ¹")

    return w
end