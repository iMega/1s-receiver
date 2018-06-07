FROM openresty/openresty:alpine-fat as builder

RUN luarocks install lua-resty-validation  && \
    luarocks install lbase64

FROM openresty/openresty:alpine
RUN apk --no-cache add unzip
EXPOSE 80

COPY --from=builder /usr/local/openresty/luajit /usr/local/openresty/luajit
COPY conf.d /etc/nginx/conf.d
COPY src /app
