ARG ALPINE_VERSION
ARG HAPROXY_VERSION
ARG ALPINE_VERSION
ARG HAPROXY_VERSION
ARG HAPROXY_BRANCH
ARG HAPROXY_MINOR
ARG HAPROXY_SHA256
ARG HAPROXY_SRC_URL
ARG DATAPLANE_MINOR
ARG DATAPLANE_SHA256
ARG DATAPLANE_URL
ARG LIBSLZ_VERSION
ARG LIBSLZ_SHA256
ARG HAPROXY_UID
ARG HAPROXY_GID
ARG GO_VERSION
ARG MAINTAINER_NAME
ARG AUTHORNAME
ARG AUTHORS
ARG VERSION
ARG SCHEMAVERSION
ARG NAME
ARG DESCRIPTION
ARG URL
ARG VCS_URL
ARG VENDOR
ARG BUILD_VERSION
ARG BUILD_DATE
ARG VCS_REF
ARG DOCKERCMD

FROM alpine:${ALPINE_VERSION} AS haproxy

ARG ALPINE_VERSION
ARG HAPROXY_VERSION
ARG ALPINE_VERSION
ARG HAPROXY_VERSION
ARG HAPROXY_BRANCH
ARG HAPROXY_MINOR
ARG HAPROXY_SHA256
ARG HAPROXY_SRC_URL
ARG DATAPLANE_MINOR
ARG DATAPLANE_SHA256
ARG DATAPLANE_URL
ARG LIBSLZ_VERSION
ARG LIBSLZ_SHA256
ARG HAPROXY_UID
ARG HAPROXY_GID
ARG GO_VERSION
ARG MAINTAINER_NAME
ARG AUTHORNAME
ARG AUTHORS
ARG VERSION
ARG SCHEMAVERSION
ARG NAME
ARG DESCRIPTION
ARG URL
ARG VCS_URL
ARG VENDOR
ARG BUILD_VERSION
ARG BUILD_DATE
ARG VCS_REF
ARG DOCKERCMD

# Labels.
LABEL maintainer=${MAINTAINER_NAME} \
      version=${VERSION} \
      description=${DESCRIPTION} \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.name=${NAME} \
      org.label-schema.description=${DESCRIPTION} \
      org.label-schema.usage=${USAGE} \
      org.label-schema.url=${URL} \
      org.label-schema.vcs-url=${VCS_URL} \
      org.label-schema.vcs-ref=${VSC_REF} \
      org.label-schema.vendor=${VENDOR} \
      org.label-schema.version=${BUILDVERSION} \
      org.label-schema.schema-version=${SCHEMAVERSION} \
      org.label-schema.docker.cmd=${DOCKERCMD} \
      org.label-schema.docker.cmd.devel="" \
      org.label-schema.docker.cmd.test="" \
      org.label-schema.docker.cmd.debug="" \
      org.label-schema.docker.cmd.help="" \
      org.label-schema.docker.params=""

RUN apk update --no-cache && apk upgrade --no-cache && \
    apk add --no-cache --virtual .build-deps ca-certificates gcc libc-dev \
    linux-headers lua5.3-dev make openssl openssl-dev pcre2-dev tar \
    zlib-dev curl git bash go shadow ca-certificates && \
    curl -sfSL "http://git.1wt.eu/web?p=libslz.git;a=snapshot;h=v${LIBSLZ_VERSION};sf=tgz" -o libslz.tar.gz && \
    echo "$LIBSLZ_SHA256 *libslz.tar.gz" | sha256sum -c - && \
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
    \
    \
    make -C /tmp/haproxy -j"$(nproc)" TARGET=${TARGETOS}-${TARGETARCH} CPU=generic USE_PCRE2=1 USE_PCRE2_JIT=1 USE_REGPARM=1 USE_OPENSSL=1 \
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
    cd / && \
    \
    \
    echo "Building dataplaneapi" && \
    echo "From: ${DATAPLANE_URL}${DATAPLANE_MINOR}.tar.gz" && \
    echo && \
    echo && \
    curl -sfSL "${DATAPLANE_URL}${DATAPLANE_MINOR}.tar.gz" -o dataplane.tar.gz && \
    echo "$DATAPLANE_SHA256 *dataplane.tar.gz" | sha256sum -c - && \
    mkdir -p /tmp/dataplane && \
    tar -xzf dataplane.tar.gz -C /tmp/dataplane --strip-components=1 && \
    rm -f dataplane.tar.gz && \
    cd /tmp/dataplane && \
    make build && \
    mv /tmp/dataplane/build/dataplaneapi /usr/local/bin/dataplaneapi && \
    chmod +x /usr/local/bin/dataplaneapi && \
    ln -s /usr/local/bin/dataplaneapi /usr/bin/dataplaneapi && \
    rm -rf /tmp/libslz && \
    rm -rf /tmp/haproxy && \
    rm -rf /tmp/dataplane && \
    apk del .build-deps && \
    apk add --no-cache openssl zlib lua5.3-libs pcre2 && \
    rm -f /var/cache/apk/*

COPY haproxy.cfg /usr/local/etc/haproxy
COPY dataplaneapi.yaml /etc/
COPY docker-entrypoint.sh /

STOPSIGNAL SIGUSR1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
