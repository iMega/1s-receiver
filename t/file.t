use Test::Nginx::Socket::Lua 'no_plan';

our $HttpConfig = qq{
    lua_package_path "./src/?.lua;/vendor/?.lua;;";
};

run_tests;

__DATA__

=== TEST 1: Accept files. Script must return code of response equal is 200

--- http_config eval: $::HttpConfig

--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';
    set_by_lua $file_limit 'return "2"';

    location /graphql {
        content_by_lua_block {
            local json = require "cjson"

            local body = {
                data = {
                    checkToken = {
                        login = "asdasd",
                    },
                },
            }


            ngx.status = 200
            ngx.say(json.encode(body))
            ngx.exit(200)
        }
    }

    location /t {
        content_by_lua_file ../../src/file.lua;
    }

--- pipelined_requests eval
[
"POST /t?filename=test.zip
hello",
"POST /t?filename=test.zip
world"]

--- more_headers
Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c; co=sdlvmksflk

--- response_body eval: ["success\n","success\n"]

--- error_code eval: [200, 200]
