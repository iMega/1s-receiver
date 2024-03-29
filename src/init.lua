local cookie = require("cookie.cookie")
local token = require("token.token")
local strings = require("common.strings")

local headers = ngx.req.get_headers()

local t, err = cookie.getTokenFromCookie(headers)
if err then
    ngx.log(ngx.ERR, err)
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

local login, err = token.getLoginByToken(t)
if err then
    ngx.log(ngx.ERR, err)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

if strings.empty(login) then
    ngx.log(ngx.ERR, "init response from graphql-server unauthorized")
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.exit(ngx.status)
end

local fileLimit = 1048576 * tonumber(ngx.var.file_limit, 10) or 1048576

ngx.say("zip=yes\nfile_limit=" .. fileLimit)
