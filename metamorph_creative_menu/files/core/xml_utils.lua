local xml_utils = {}

function xml_utils.escape_attribute(value)
    local escaped_value = tostring(value or "")
    escaped_value = string.gsub(escaped_value, "&", "&amp;")
    escaped_value = string.gsub(escaped_value, '"', "&quot;")
    escaped_value = string.gsub(escaped_value, "<", "&lt;")
    escaped_value = string.gsub(escaped_value, ">", "&gt;")
    return escaped_value
end

return xml_utils
