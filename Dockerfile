FROM alpine:3.15
LABEL net.technoboggle.authorname="Edward Finlayson" \
      net.technoboggle.authors="edward.finlayson@btinternet.com" \
      net.technoboggle.version="0.1" \
      net.technoboggle.description="This image builds a HAProxy server" \
      net.technoboggle.alpine_version="3.15.3" \
      net.technoboggle.dataplane_version="2.4.4" \
      net.technoboggle.haproxy_version="2.6-dev4" \
      net.technoboggle.libslz_version="1.2.0" \
      net.technoboggle.buildDate=$buildDate

LABEL Name HAProxy
LABEL Release Community Edition
LABEL Vendor HAProxy
LABEL Version 2.6-dev4
LABEL RUN /usr/bin/docker -d IMAGE

ENV HAPROXY_BRANCH 2.6
ENV HAPROXY_MINOR 2.6-dev4
ENV HAPROXY_SHA256 a7d5f2c5f20974a26de9b9dc0ab5c623c8a254179280e1647a41e1d1a1f078e9
ENV HAPROXY_SRC_URL http://www.haproxy.org/download

ENV DATAPLANE_MINOR 2.4.4
ENV DATAPLANE_SHA256 9fe55a15c419c05f3c7e2d99c0619efb52097ca512c5f945e4425304e712f6ca
ENV DATAPLANE_URL https://github.com/haproxytech/dataplaneapi/releases/download

ENV LIBSLZ_VERSION 1.2.0

ENV HAPROXY_UID haproxy
ENV HAPROXY_GID haproxy

RUN apk add --no-cache --virtual .build-deps ca-certificates gcc libc-dev \
    linux-headers lua5.3-dev make openssl openssl-dev pcre2-dev tar \
    zlib-dev curl shadow ca-certificates && \
    curl -sfSL "http://git.1wt.eu/web?p=libslz.git;a=snapshot;h=v${LIBSLZ_VERSION};sf=tgz" -o libslz.tar.gz && \
    mkdir -p /tmp/libslz && \
    tar -xzf libslz.tar.gz -C /tmp/libslz --strip-components=1 && \
    make -C /tmp/libslz static && \
    rm -f libslz.tar.gz && \
    curl -sfSL "${HAPROXY_SRC_URL}/${HAPROXY_BRANCH}/src/devel/haproxy-${HAPROXY_MINOR}.tar.gz" -o haproxy.tar.gz && \
    echo "$HAPROXY_SHA256 *haproxy.tar.gz" | sha256sum -c - && \
    groupadd "$HAPROXY_GID" && \
    useradd -g "$HAPROXY_GID" "$HAPROXY_UID" && \
    mkdir -p /tmp/haproxy && \
    tar -xzf haproxy.tar.gz -C /tmp/haproxy --strip-components=1 && \
    rm -f haproxy.tar.gz && \
    make -C /tmp/haproxy -j"$(nproc)" TARGET=linux-musl CPU=generic USE_PCRE2=1 USE_PCRE2_JIT=1 USE_REGPARM=1 USE_OPENSSL=1 \
                            USE_TFO=1 USE_LINUX_TPROXY=1 USE_GETADDRINFO=1 \
                            USE_LUA=1 LUA_LIB=/usr/lib/lua5.3 LUA_INC=/usr/include/lua5.3 \
                            USE_PROMEX=1 USE_SLZ=1 SLZ_INC=/tmp/libslz/src SLZ_LIB=/tmp/libslz \
                            all && \
    make -C /tmp/haproxy TARGET=linux2628 install-bin install-man && \
    ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy && \
    mkdir -p /var/lib/haproxy && \
    chown "$HAPROXY_UID:$HAPROXY_GID" /var/lib/haproxy && \
    mkdir -p /usr/local/etc/haproxy && \
    ln -s /usr/local/etc/haproxy /etc/haproxy && \
    cp -R /tmp/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors && \
    rm -rf /tmp/libslz && \
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
    apk del .build-deps && \
    apk add --no-cache openssl zlib lua5.3-libs pcre2 && \
    rm -f /var/cache/apk/*

COPY haproxy.cfg /usr/local/etc/haproxy
COPY docker-entrypoint.sh /

STOPSIGNAL SIGUSR1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
