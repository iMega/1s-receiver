FROM openresty/openresty:alpine-fat as builder

RUN luarocks install lua-resty-validation  && \
    luarocks install lbase64

FROM openresty/openresty:alpine
RUN apk --no-cache add unzip
EXPOSE 80

RUN echo "env FILE_LIMIT;" >> /usr/local/openresty/nginx/conf/nginx.conf
COPY --from=builder /usr/local/openresty/luajit /usr/local/openresty/luajit
COPY conf.d /etc/nginx/conf.d
COPY src /app
WORKDIR /app

RUN ln -sf /dev/stdout /var/log/nginx_access.log && \
    ln -sf /dev/stderr /var/log/nginx_error.log
