struct Discrete
    info::JuMP.VariableInfo
    levels::Union{Vector,Set,OrderedSet}
    binary_type::Union{DataType,Type}
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{Discrete};
    kwargs...
)
    return Discrete(info, kwargs[:levels], kwargs[:binary_type])
end

function JuMP.add_variable(
    model::JuMP.Model,
    discrete::Discrete,
    name::String,
)
    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(discrete.info),
        "$(name)"
    )

    if discrete.binary_type == Bool
        ℤ₂ = JuMP.@variable(model, [l=discrete.levels], Bin, base_name="ℤ₂($(name))")
    else
        ℤ₂ = JuMP.@variable(model, [l=discrete.levels], discrete.binary_type, base_name="ℤ₂($(name))")
    end

    JuMP.@constraint(model, sum(ℤ₂) == 1, base_name="∑(ℤ₂($(name)))")

    JuMP.@constraint(model, variable == sum(ℤ₂[l] * l for l in discrete.levels), base_name="ℤ($(name))")
    
    return variable
end

struct RelaxedBinary{T <: Number}
    info::JuMP.VariableInfo
    zero_tol::T
    one_tol::T
    use_constraint::Bool
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{RelaxedBinary};
    kwargs...
)
    zero_tol = get(kwargs, :zero_tol, 1e-6)
    one_tol = get(kwargs, :one_tol, 1e-3)
    use_constraint = get(kwargs, :use_constraint, false)
    return RelaxedBinary(info, zero_tol, one_tol, use_constraint)
end

function JuMP.add_variable(
    model::JuMP.Model,
    relaxed_binary::RelaxedBinary,
    name::String,
)
    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(relaxed_binary.info),
        "$(name)"
    )

    JuMP.set_lower_bound(variable, 0.0)
    JuMP.set_upper_bound(variable, 1.0)

    d₀ = JuMP.@variable(model, base_name="d₀($(name))")
    JuMP.set_lower_bound(d₀, 0.0)
    JuMP.set_upper_bound(d₀, 1.0)

    d₁ = JuMP.@variable(model, base_name="d₁($(name))")
    JuMP.set_lower_bound(d₁, 0.0)
    JuMP.set_upper_bound(d₁, 1.0)

    JuMP.@constraint(model, variable - d₀ == 0, base_name="δ₀($(name))")
    JuMP.@constraint(model, variable + d₁ == 1, base_name="δ₁($(name))")

    JuMP.@constraint(model, d₀ + d₁ == 1, base_name="d₀ + d₁($(name))")

    d₀d₁ = JuMP.@variable(model, variable_type=McCormick, x=d₀, y=d₁, xₗᵢₘ=[0.0, 1.0], yₗᵢₘ=[0.0, 1.0], base_name="d₀d₁($(name))")

    JuMP.@constraint(model, d₀d₁ <= relaxed_binary.zero_tol, base_name="d₀⋅d₁($(name))")

    if relaxed_binary.use_constraint
        JuMP.@constraint(model, (1 - relaxed_binary.one_tol)^2 <= d₀^2 + d₁^2, base_name="d₀² + d₁²($(name))")
    else
        d = JuMP.@expression(model, -d₀^2 - d₁^2)

        if haskey(model.ext, :objective)
            push!(model.ext[:objective], d)
        else
            model.ext[:objective] = Vector([d])
        end
    end

    return variable
end

struct RelaxedInteger{T <: Number}
    info::JuMP.VariableInfo
    zero_tol::T
    one_tol::T
    use_constraint::Bool
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{RelaxedInteger};
    kwargs...
)
    zero_tol = get(kwargs, :zero_tol, 1e-6)
    one_tol = get(kwargs, :one_tol, 1e-3)
    use_constraint = get(kwargs, :use_constraint, false)
    return RelaxedInteger(info, zero_tol, one_tol, use_constraint)
end

function JuMP.add_variable(
    model::JuMP.Model,
    relaxed_integer::RelaxedInteger,
    name::String,
)
    @assert relaxed_integer.info.has_lb
    @assert relaxed_integer.info.has_ub

    lb = relaxed_integer.info.lower_bound
    ub = relaxed_integer.info.upper_bound

    @assert isinteger(lb)
    @assert isinteger(ub)

    variable_range = ub - lb

    num_binary = Int(ceil(log2(variable_range)))

    binary_levels = 1:num_binary

    bin_variables = JuMP.@variable(model, [binary_levels], variable_type=RelaxedBinary, base_name="ℤ₂($(name))", one_tol=relaxed_integer.one_tol, zero_tol=relaxed_integer.zero_tol, use_constraint=relaxed_integer.use_constraint)

    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(relaxed_integer.info),
        "$(name)"
    )

    JuMP.@constraint(model, sum(2^(index-1) * bin_variables[index] for index in binary_levels) <= variable_range, base_name="∑(ℤ₂($(name)))")

    JuMP.@constraint(model, variable == lb + sum(2^(index-1) * bin_variables[index] for index in binary_levels), base_name="ℤ($(name))")

    return variable
end

struct ConstrainedRelaxedBinary
    info::JuMP.VariableInfo
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{ConstrainedRelaxedBinary};
    kwargs...
)
    return ConstrainedRelaxedBinary(info)
end

function JuMP.add_variable(
    model::JuMP.Model,
    relaxed_binary::ConstrainedRelaxedBinary,
    name::String,
)
    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(relaxed_binary.info),
        "$(name)"
    )

    JuMP.set_lower_bound(variable, 0.0)
    JuMP.set_upper_bound(variable, 1.0)

    # JuMP.@constraint(model, variable * (1 - variable) == 0, base_name="Π($(name) * (1 - $(name)))")

    π  = JuMP.@expression(model, variable - variable^2)
    if haskey(model.ext, :objective)
        push!(model.ext[:objective], π)
    else
        model.ext[:objective] = Vector([π])
    end

    return variable
end

struct ConstrainedRelaxedInteger
    info::JuMP.VariableInfo
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{ConstrainedRelaxedInteger};
    kwargs...
)
    return ConstrainedRelaxedInteger(info)
end

function JuMP.add_variable(
    model::JuMP.Model,
    relaxed_integer::ConstrainedRelaxedInteger,
    name::String,
)
    @assert relaxed_integer.info.has_lb
    @assert relaxed_integer.info.has_ub

    lb = relaxed_integer.info.lower_bound
    ub = relaxed_integer.info.upper_bound

    @assert isinteger(lb)
    @assert isinteger(ub)

    variable_range = ub - lb

    num_binary = Int(ceil(log2(variable_range)))

    binary_levels = 1:num_binary

    bin_variables = JuMP.@variable(model, [binary_levels], variable_type=ConstrainedRelaxedBinary, base_name="ℤ₂($(name))")

    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(relaxed_integer.info),
        "$(name)"
    )

    JuMP.@constraint(model, sum(2^(index-1) * bin_variables[index] for index in binary_levels) <= variable_range, base_name="∑(ℤ₂($(name)))")

    JuMP.@constraint(model, variable == lb + sum(2^(index-1) * bin_variables[index] for index in binary_levels), base_name="ℤ($(name))")

    return variable
end

struct BinaryExpandedInteger
    info::JuMP.VariableInfo
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{BinaryExpandedInteger};
    kwargs...
)
    return BinaryExpandedInteger(info)
end

function JuMP.add_variable(
    model::JuMP.Model,
    binary_expanded_integer::BinaryExpandedInteger,
    name::String,
)
    @assert binary_expanded_integer.info.has_lb
    @assert binary_expanded_integer.info.has_ub

    lb = binary_expanded_integer.info.lower_bound
    ub = binary_expanded_integer.info.upper_bound

    @assert isinteger(lb)
    @assert isinteger(ub)

    variable_range = ub - lb

    num_binary = Int(ceil(log2(variable_range)))

    binary_levels = 1:num_binary

    bin_variables = JuMP.@variable(model, [binary_levels], binary=true, base_name="ℤ₂($(name))")

    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(binary_expanded_integer.info),
        "$(name)"
    )

    JuMP.@constraint(model, sum(2^(index-1) * bin_variables[index] for index in binary_levels) <= variable_range, base_name="∑(ℤ₂($(name)))")

    JuMP.@constraint(model, variable == lb + sum(2^(index-1) * bin_variables[index] for index in binary_levels), base_name="ℤ($(name))")

    return variable
end

struct RelaxedBinaryWithoutDistanceVariables{T <: Number}
    info::JuMP.VariableInfo
    zero_tol::T
    one_tol::T
    use_constraint::Bool
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{RelaxedBinaryWithoutDistanceVariables};
    kwargs...
)
    zero_tol = get(kwargs, :zero_tol, 1e-6)
    one_tol = get(kwargs, :one_tol, 1e-3)
    use_constraint = get(kwargs, :use_constraint, false)
    return RelaxedBinaryWithoutDistanceVariables(info, zero_tol, one_tol, use_constraint)
end

function JuMP.add_variable(
    model::JuMP.Model,
    relaxed_binary::RelaxedBinaryWithoutDistanceVariables,
    name::String,
)
    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(relaxed_binary.info),
        "$(name)"
    )

    JuMP.set_lower_bound(variable, 0.0)
    JuMP.set_upper_bound(variable, 1.0)

    w = JuMP.@variable(model, base_name="w($(name))")
    JuMP.set_lower_bound(w, 0.0)
    JuMP.set_upper_bound(w, relaxed_binary.zero_tol)

    JuMP.@constraint(model, w <= variable, base_name="m($(name))")
    JuMP.@constraint(model, w <= 1 - variable, base_name="1-m($(name))")

    f = JuMP.@expression(model, -4*variable^2 + 4*variable - 1)

    if haskey(model.ext, :objective)
        push!(model.ext[:objective], f)
    else
        model.ext[:objective] = Vector([f])
    end

    return variable
end

struct RelaxedIntegerWithoutDistanceVariables{T <: Number}
    info::JuMP.VariableInfo
    zero_tol::T
    one_tol::T
    use_constraint::Bool
end

function JuMP.build_variable(
    _err::Function,
    info::JuMP.VariableInfo,
    ::Type{RelaxedIntegerWithoutDistanceVariables};
    kwargs...
)
    zero_tol = get(kwargs, :zero_tol, 1e-6)
    one_tol = get(kwargs, :one_tol, 1e-3)
    use_constraint = get(kwargs, :use_constraint, false)
    return RelaxedIntegerWithoutDistanceVariables(info, zero_tol, one_tol, use_constraint)
end

function JuMP.add_variable(
    model::JuMP.Model,
    relaxed_integer::RelaxedIntegerWithoutDistanceVariables,
    name::String,
)
    @assert relaxed_integer.info.has_lb
    @assert relaxed_integer.info.has_ub

    lb = relaxed_integer.info.lower_bound
    ub = relaxed_integer.info.upper_bound

    @assert isinteger(lb)
    @assert isinteger(ub)

    variable_range = ub - lb

    num_binary = Int(ceil(log2(variable_range)))

    binary_levels = 1:num_binary

    bin_variables = JuMP.@variable(model, [binary_levels], variable_type=RelaxedBinaryWithoutDistanceVariables, base_name="ℤ₂($(name))", one_tol=relaxed_integer.one_tol, zero_tol=relaxed_integer.zero_tol, use_constraint=relaxed_integer.use_constraint)

    variable = JuMP.add_variable(
        model,
        JuMP.ScalarVariable(relaxed_integer.info),
        "$(name)"
    )

    JuMP.@constraint(model, sum(2^(index-1) * bin_variables[index] for index in binary_levels) <= variable_range, base_name="∑(ℤ₂($(name)))")

    JuMP.@constraint(model, variable == lb + sum(2^(index-1) * bin_variables[index] for index in binary_levels), base_name="ℤ($(name))")

    return variable
end