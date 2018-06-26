local cookie = require("cookie.cookie")
local token = require("token.token")
local strings = require("common.strings")

local headers = ngx.req.get_headers()

local handler = function (premature, login)
    local path = "/data/source/" .. login

    ngx.log(ngx.INFO, "import start decompress file: " .. path)

    local reader = assert(io.popen(os.execute("unzip " .. path .. "/* -d " .. path .. "/unziped"), "r"))
    local stdout = assert(reader:read('*a'))
    ngx.log(ngx.INFO, "unzip: " .. stdout)
    reader:close()

    ngx.log(ngx.INFO, "import end decompress file: " .. path)
end

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
    ngx.log(ngx.ERR, "import response from graphql-server unauthorized")
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.exit(ngx.status)
end

local ok, err = ngx.timer.at(0, handler, login)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end

ngx.say("success")
