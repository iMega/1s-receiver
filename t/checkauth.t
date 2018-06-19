use Test::Nginx::Socket::Lua 'no_plan';

our $HttpConfig = qq{
    lua_package_path "./src/?.lua;/vendor/?.lua;;";
};

run_tests;

__DATA__
=== TEST 1: Header Authorization is not set. Script must return a code of response equal 400

--- http_config eval: $::HttpConfig

--- config
    location /t {
        content_by_lua_file ../../src/checkauth.lua;
    }

--- request
GET /t

--- error_code: 400




=== TEST 2: Header Authorization is empty. Script must return a code of response equal 400

--- http_config eval: $::HttpConfig

--- config
    location /t {
        content_by_lua_file ../../src/checkauth.lua;
    }

--- request
GET /t

--- more_headers
Authorization:

--- error_code: 400




=== TEST 3: Header Authorization is not basic auth. Script must return a code of response equal 400

--- http_config eval: $::HttpConfig

--- config
    location /t {
        content_by_lua_file ../../src/checkauth.lua;
    }

--- request
GET /t

--- more_headers
Authorization: Basi Not base64

--- error_code: 400




=== TEST 4: Header Authorization is not encode base64. Script must return a code of response equal 400

--- http_config eval: $::HttpConfig

--- config
    location /t {
        content_by_lua_file ../../src/checkauth.lua;
    }

--- request
GET /t

--- more_headers
Authorization: Basic Not base64

--- error_code: 400




=== TEST 5: Creds is invalid. Script must return a code of response equal 400
--- http_config eval: $::HttpConfig

--- config
    location /t {
        content_by_lua_file ../../src/checkauth.lua;
    }

--- request
GET /t

--- more_headers
Authorization: Basic OWJkYmEwMjYtOTQwNS00ZmQ2LWFmZTEtOGJmYzE2OWQ2Njk0OmE3NmU3MThmLTM4YmQtNGJiNC1iYWU3LWFkYzQ0ZWRiMGQ0Cg==

--- error_code: 400




=== TEST 6: Graphql not responding. Script must return a code of response equal 400
--- http_config eval: $::HttpConfig
--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        return 500;
    }

    location /t {
        content_by_lua_file ../../src/checkauth.lua;
    }

--- request
GET /t

--- more_headers
Authorization: Basic OWJkYmEwMjYtOTQwNS00ZmQ2LWFmZTEtOGJmYzE2OWQ2Njk0OmE3NmU3MThmLTM4YmQtNGJiNC1iYWU3LWFkYzQ0ZWRiMGQ0MQo=

--- error_code: 500



=== TEST 7: Optimistic. Script must return a code of response equal 200
--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";
    server {
        listen 127.0.0.1:80;

        location /protected {
            content_by_lua_block {
                ngx.say(ngx.req.get_headers()["X-SITE-ID"])
            }
        }
    }
--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        content_by_lua_block {
            local json = require "cjson"

            local body = {
                data = {
                    createToken = {
                        token = "this-is-token",
                    },
                },
            }

            ngx.status = ngx.HTTP_OK
            ngx.say(json.encode(body))
            ngx.exit(ngx.HTTP_OK)
        }
    }

    location /t {
        content_by_lua_file ../../src/checkauth.lua;
    }

--- request
GET /t

--- more_headers
Authorization: Basic OWJkYmEwMjYtOTQwNS00ZmQ2LWFmZTEtOGJmYzE2OWQ2Njk0OmE3NmU3MThmLTM4YmQtNGJiNC1iYWU3LWFkYzQ0ZWRiMGQ0MQo=

--- response_body
success
token
this-is-token

--- error_code: 200
