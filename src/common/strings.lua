-- Determine whether a variable is empty
--
-- @return bool
--
local function empty(value)
    return value == nil or value == ''
end

return {
    empty = empty,
}
