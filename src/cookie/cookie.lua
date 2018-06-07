-- Determine whether a variable is empty
--
-- @return bool
--
local function empty(value)
    return value == nil or value == ''
end

local function getTokenFromCookie(headers)
    if empty(headers["cookie"]) then
        return nil, "header Cookie is empty"
    end

    local matchPiece = ngx.re.match(headers["cookie"], "token=([^;\r\n\t\f\v ]+)")

    if empty(matchPiece) then
        return nil, "init failed to match regexp from header Cookie"
    end

    if empty(matchPiece[1]) then
        return nil, "init token is empty from header Cookie"
    end

    return matchPiece[1], nil
end


return {
    getTokenFromCookie = getTokenFromCookie
}
