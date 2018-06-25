local json = require("cjson")
local strings = require("common.strings")

local function getLoginByToken(token)
    local data = {
        operationName = "CheckToken",
        query = "query CheckToken($token: String!) { checkToken(token: $token) { id } }",
        variables = {
            token = token,
        },
    }

    ngx.req.set_header("GRPC-METADATA-X-OWNER-ID", "owner")
    res = ngx.location.capture(
        "/graphql",
        {
            method = ngx.HTTP_POST,
            body = json.encode(data),
        }
    )
    if res.status ~= ngx.HTTP_OK then
        return nil, "init: graphql returns http code is not 200"
    end

    local ok, body = pcall(json.decode, res.body)
    if not ok then
        return nil, "init failed decode json from graphql-server returns skewed json"
    end

    if strings.empty(body['data']) then
        return nil, "init response from graphql-server is empty"
    end

    local login = body['data']['checkToken']['id']

    return login, nil
end

return {
    getLoginByToken = getLoginByToken,
}
