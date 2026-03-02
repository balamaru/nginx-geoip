ARG NGINX_VERSION=1.25.0
FROM nginx:${NGINX_VERSION} AS builder

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        libpcre3-dev \
        zlib1g-dev \
        libmaxminddb-dev \
        git wget

RUN git clone --depth 1 https://github.com/leev/ngx_http_geoip2_module.git /tmp/ngx_http_geoip2_module

RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz -C /tmp

RUN cd /tmp/nginx-${NGINX_VERSION} && \
    ./configure --with-compat --add-dynamic-module=/tmp/ngx_http_geoip2_module && \
    make modules

FROM nginx:${NGINX_VERSION}

COPY --from=builder /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /etc/nginx/modules/

RUN apt-get update && \
    apt-get install -y libmaxminddb0 && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/nginx/geoip/

COPY geoip/GeoLite2-City.mmdb geoip/GeoLite2-Country.mmdb /etc/nginx/geoip/
