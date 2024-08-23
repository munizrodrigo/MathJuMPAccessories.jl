function JuMP.value(var::Union{Dict,OrderedDict})
    return OrderedDict(k => JuMP.value(v) for (k,v) in var)
end