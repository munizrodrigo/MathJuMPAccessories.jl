module MathJuMPAccessories

import Base: \
import OrderedCollections: OrderedSet, OrderedDict
import JuMP

export ⅈ, ⅉ, ∑, ∥, ∠, ∗, ℜ, ℑ, ∧, ∨, ⋅, Ω, @∀
export McCormick, UpperMcCormick, QuadraticMcCormick
export Discrete, RelaxedBinary, RelaxedInteger, ConstrainedRelaxedBinary, ConstrainedRelaxedInteger, BinaryExpandedInteger, RelaxedBinaryWithoutDistanceVariables, RelaxedIntegerWithoutDistanceVariables

include("symbols.jl")
include("mccormick.jl")
include("integer_variables.jl")
include("extensions.jl")

end
