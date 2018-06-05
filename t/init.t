use Test::Nginx::Socket::Lua 'no_plan';

run_tests;

__DATA__
=== TEST 1: Send without header cookie. Script must return a code of response equal 400

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- error_code: 400




=== TEST 2: Send empty header cookie. Script must return a code of response equal 400

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie:

--- error_code: 400



=== TEST 3: Header cookie not have token. Script must return a code of response equal 400

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie: without token

--- error_code: 400



=== TEST 4: Graphql is down. Script must return a code of response equal 500

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        content_by_lua_block {
            ngx.status = 500
            ngx.exit(500)
        }
    }

    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c; co=sdlvmksflk

--- error_code: 500




=== TEST 5: Graphql returns skewed response. Script must return a code of response equal 500

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        content_by_lua_block {
            ngx.say("{data[")
            ngx.status = 200
            ngx.exit(200)
        }
    }

    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c; co=sdlvmksflk

--- error_code: 500




=== TEST 6: Graphql returns empty response. Script must return a code of response equal 500

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        content_by_lua_block {
            ngx.say("")
            ngx.status = 200
            ngx.exit(200)
        }
    }

    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c; co=sdlvmksflk

--- error_code: 500





=== TEST 6: Header cookie have skewed token. Script must return a code of response equal 401

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        content_by_lua_block {
            local json = require "cjson"

            local body = {
                data = {
                    checkToken = {
                        login = "",
                    },
                },
            }

            ngx.say(json.encode(body))
            ngx.status = 200
            ngx.exit(200)
        }
    }

    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c; co=sdlvmksflk

--- error_code: 401



=== TEST 7: Optimistic. Script must return a code of response equal 200

--- http_config
    lua_package_path "/vendor/?.lua;;";

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

            ngx.say(json.encode(body))
            ngx.status = 200
            ngx.exit(200)
        }
    }

    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c; co=sdlvmksflk

--- response_body
zip=yes
file_limit=2097152

--- error_code: 200
