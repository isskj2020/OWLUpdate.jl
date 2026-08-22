
function get_value(::Type{T}, dict, key, default) where T
    convert(T, get(dict, key, default))
end

