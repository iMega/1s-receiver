FROM openresty/openresty:alpine-fat as builder

RUN luarocks install lua-resty-validation  && \
    luarocks install lbase64 && \
    luarocks install lua-cjson



FROM openresty/openresty:alpine

EXPOSE 80

COPY --from=builder /usr/local/openresty/luajit /usr/local/openresty/luajit
COPY conf.d /etc/nginx/conf.d
COPY src /app
COPY vendor /vendor
