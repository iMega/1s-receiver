require "resty.validation.ngx"

local validation = require "resty.validation"
local base64     = require "base64"
local json       = require "cjson"
local strings    = require "common.strings"

local headers = ngx.req.get_headers()

if strings.empty(headers["Authorization"]) then
    ngx.log(ngx.ERR, "checkauth header Authorization is empty")
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

local matchPiece = ngx.re.match(headers["Authorization"], "Basic\\s(.+)")

if strings.empty(matchPiece) then
    ngx.log(ngx.ERR, "checkauth failed to match regexp from header Authorization")
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

if strings.empty(matchPiece[1]) then
    ngx.log(ngx.ERR, "checkauth creds is empty from header Authorization")
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

local ok, rawCredentials = pcall(base64.decode, matchPiece[1])
if not ok then
    ngx.log(ngx.ERR, "checkauth failed to decode base64 from header Authorization")
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.exit(ngx.status)
end

local loginPass = {}
for t in string.gmatch(rawCredentials, "[^:%s]+") do
    table.insert(loginPass, t)
end

local credentials = {
    login = loginPass[1],
    pass  = loginPass[2]
}

local validatorCredentials = validation.new{
    login = validation.string.trim:len(32,32),
    pass  = validation.string.trim:len(6,36),
}

local ok, values = validatorCredentials(credentials)
if not ok then
    ngx.log(ngx.ERR, "checkauth failed to validate uuids")
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n")
    ngx.exit(ngx.status)
end

local validData = values("valid")

local data = {
    operationName = "CreateToken",
    query = "mutation CreateToken($login: ID!, $pass: String!) { createToken(id: $login, pass: $pass) }",
    variables = validData,
}

ngx.req.set_header("GRPC-METADATA-X-OWNER-ID", validData["login"])
res = ngx.location.capture(
    "/graphql",
    {
        method = ngx.HTTP_POST,
        body = json.encode(data),
    }
)
if res.status ~= ngx.HTTP_OK then
    ngx.log(ngx.ERR, "checkauth: graphql returns http code is not 200, retuns code " .. res.status)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.status)
end

local ok, body = pcall(json.decode, res.body)
if not ok then
    ngx.log(ngx.ERR, "checkauth failed decode json from graphql-server returns skewed json")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.status)
end

if strings.empty(body['data']) then
    ngx.log(ngx.ERR, "checkauth response is empty")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.status)
end

token = body['data']['createToken']

ngx.say("success\ntoken\n" .. token)
