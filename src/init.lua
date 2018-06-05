local json = require("cjson")

local headers = ngx.req.get_headers()

-- Determine whether a variable is empty
--
-- @return bool
--
local function empty(value)
    return value == nil or value == ''
end

if empty(headers["cookie"]) then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

local matchPiece = ngx.re.match(headers["cookie"], "token=([^;\r\n\t\f\v ]+)")

if empty(matchPiece) then
    ngx.log(ngx.ERR, "init failed to match regexp from header Cookie")
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

if empty(matchPiece[1]) then
    ngx.log(ngx.ERR, "init token is empty from header Cookie")
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("failure\n");
    ngx.exit(ngx.status)
end

local data = {
    operationName = "CheckToken",
    query = "query CheckToken($token: String!) { checkToken(token: $token) { login } }",
    variables = validData,
}

res = ngx.location.capture(
    ngx.var.graphql_endpoint_uri,
    {
        method = ngx.HTTP_POST,
        body = json.encode(data),
    }
)
if res.status ~= ngx.HTTP_OK then
    ngx.log(ngx.ERR, "init: graphql returns http code is not 200")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.status)
end

local ok, body = pcall(json.decode, res.body)
if not ok then
    ngx.log(ngx.ERR, "init failed decode json from graphql-server returns skewed json")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.status)
end

if empty(body) then
    ngx.log(ngx.ERR, "init response from graphql-server is empty")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.exit(ngx.status)
end

local login = body['data']['checkToken']['login']

if empty(login) then
    ngx.log(ngx.ERR, "init response from graphql-server unauthorized")
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.exit(ngx.status)
end

local fileLimit = 1048576 * tonumber(ngx.var.file_limit, 10) or 1048576

ngx.say("zip=yes\nfile_limit=" .. fileLimit)
