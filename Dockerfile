FROM alpine:3.13.5 AS builder

MAINTAINER Edward Finlayson <edward.finlayson@btinternet.com>

LABEL Name HAProxy
LABEL Release Community Edition
LABEL Vendor HAProxy
LABEL Version 2.4-dev18
LABEL RUN /usr/bin/docker -d IMAGE

ENV HAPROXY_BRANCH 2.4
ENV HAPROXY_MINOR 2.4-dev18
ENV HAPROXY_SHA256 fab8b85664afc74c481c91a8f104b6bf87b265f9b5f03054dc926364e9801e74
ENV HAPROXY_SRC_URL http://www.haproxy.org/download

ENV DATAPLANE_MINOR 2.2.1
ENV DATAPLANE_SHA256 0017cd9ce316ea4b4a27cbd87f6edb842cfd55144fd6f159cebdb2d4f501a72f
ENV DATAPLANE_URL https://github.com/haproxytech/dataplaneapi/releases/download

ENV HAPROXY_UID haproxy
ENV HAPROXY_GID haproxy

RUN apk --no-cache upgrade musl &&\
    apk add --no-cache --virtual build-deps ca-certificates gcc libc-dev \
    linux-headers lua5.3-dev make openssl openssl-dev pcre2-dev tar \
    zlib-dev curl shadow ca-certificates && \
    curl -sfSL "${HAPROXY_SRC_URL}/${HAPROXY_BRANCH}/src/devel/haproxy-${HAPROXY_MINOR}.tar.gz" -o haproxy.tar.gz && \
    echo "$HAPROXY_SHA256 *haproxy.tar.gz" | sha256sum -c - && \
    groupadd "$HAPROXY_GID" && \
    useradd -g "$HAPROXY_GID" "$HAPROXY_UID" && \
    mkdir -p /tmp/haproxy && \
    tar -xzf haproxy.tar.gz -C /tmp/haproxy --strip-components=1 && \
    rm -f haproxy.tar.gz && \
    make -C /tmp/haproxy -j"$(nproc)" TARGET=linux-musl CPU=generic USE_PCRE2=1 USE_PCRE2_JIT=1 USE_REGPARM=1 USE_OPENSSL=1 \
                            USE_ZLIB=1 USE_TFO=1 USE_LINUX_TPROXY=1 USE_GETADDRINFO=1 \
                            USE_LUA=1 LUA_LIB=/usr/lib/lua5.3 LUA_INC=/usr/include/lua5.3 \
                            EXTRA_OBJS="contrib/prometheus-exporter/service-prometheus.o" \
                            all && \
    make -C /tmp/haproxy TARGET=linux2628 install-bin install-man && \
    ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy && \
    mkdir -p /var/lib/haproxy && \
    chown "$HAPROXY_UID:$HAPROXY_GID" /var/lib/haproxy && \
    mkdir -p /usr/local/etc/haproxy && \
    ln -s /usr/local/etc/haproxy /etc/haproxy && \
    cp -R /tmp/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors && \
    rm -rf /tmp/haproxy && \
    curl -sfSL "${DATAPLANE_URL}/v${DATAPLANE_MINOR}/dataplaneapi_${DATAPLANE_MINOR}_Linux_x86_64.tar.gz" -o dataplane.tar.gz && \
    echo "$DATAPLANE_SHA256 *dataplane.tar.gz" | sha256sum -c - && \
    mkdir /tmp/dataplane && \
    tar -xzf dataplane.tar.gz -C /tmp/dataplane --strip-components=1 && \
    rm -f dataplane.tar.gz && \
    mv /tmp/dataplane/dataplaneapi /usr/local/bin/dataplaneapi && \
    chmod +x /usr/local/bin/dataplaneapi && \
    ln -s /usr/local/bin/dataplaneapi /usr/bin/dataplaneapi && \
    rm -rf /tmp/dataplane && \
    apk del build-deps && \
    apk add --no-cache openssl zlib lua5.3-libs pcre2 && \
    rm -f /var/cache/apk/*

#COPY haproxy.cfg /usr/local/etc/haproxy
#COPY docker-entrypoint.sh /
#RUN chmod 0755 /docker-entrypoint.sh

STOPSIGNAL SIGUSR1

#ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
