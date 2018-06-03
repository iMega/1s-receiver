use Test::Nginx::Socket::Lua 'no_plan';

run_tests;

__DATA__
=== TEST 1:

--- http_config
    lua_package_path "/vendor/?.lua;;";

--- config
    location /t {
        content_by_lua_file ../../src/init.lua;
    }

--- request
GET /t

--- error_code: 200
