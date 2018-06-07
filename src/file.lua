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

local filename = ngx.var.arg_filename

ngx.req.read_body()
local body = ngx.var.request_body

if strings.empty(body) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

local path = "/data/source/" .. login
os.execute("mkdir -p " .. path)

file = io.open(path .. "/" .. filename, "a")
file:write(body)
file:close()

ngx.say("success")
