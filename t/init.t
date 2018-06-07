use Test::Nginx::Socket::Lua 'no_plan';

run_tests;

__DATA__
=== TEST 1: Send without header cookie. Script must return a code of response equal 400

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

--- config
    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- error_code: 400
--- error_log: header Cookie is empty



=== TEST 2: Send empty header cookie. Script must return a code of response equal 400

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

--- config
    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie:

--- error_code: 400
--- error_log: header Cookie is empty



=== TEST 3: Header cookie not have token. Script must return a code of response equal 400

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

--- config
    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- more_headers
Cookie: without token

--- error_code: 400
--- error_log: init failed to match regexp from header Cookie



=== TEST 4: Graphql is down. Script must return a code of response equal 500

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

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
--- error_log: init: graphql returns http code is not 200




=== TEST 5: Graphql returns skewed response. Script must return a code of response equal 500

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        content_by_lua_block {
            ngx.status = 200
            ngx.say("{data[")
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
--- error_log: init failed decode json from graphql-server returns skewed json



=== TEST 6: Graphql returns empty response. Script must return a code of response equal 500

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

--- config
    set_by_lua $graphql_endpoint_uri 'return "/graphql"';

    location /graphql {
        content_by_lua_block {
            ngx.status = 200
            ngx.say("")
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
--- error_log: init failed decode json from graphql-server returns skewed json





=== TEST 7: Header cookie have skewed token. Script must return a code of response equal 401

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

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

            ngx.status = 200
            ngx.say(json.encode(body))
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
--- error_log: init response from graphql-server unauthorized


=== TEST 8: Optimistic. Script must return a code of response equal 200

--- http_config
    lua_package_path "./src/?.lua;/vendor/?.lua;;";

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
