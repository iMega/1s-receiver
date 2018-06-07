local cookie = require("cookie.cookie")
local token = require("token.token")
local strings = require("common.strings")

local headers = ngx.req.get_headers()

local handler = function (premature, login, filename)
    local path = "/data/source/" .. login
    local file = path .. "/" .. filename

    ngx.log(ngx.INFO, "import start decompress file: " .. file)

    os.execute("unzip " .. file .. " -d " .. path .. "/unziped")

    ngx.log(ngx.INFO, "import end decompress file: " .. file)
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

local ok, err = ngx.timer.at(0, handler, login, ngx.var.arg_filename)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end

ngx.say("success")
