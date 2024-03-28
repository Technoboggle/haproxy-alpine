# docker-bake.hcl
group "default" {
    targets = ["app"]
}

target "app" {
    context = "."
    dockerfile = "Dockerfile"
    tags = ["technoboggle/haproxy-alpine:${HAPROXY_VERSION}-${ALPINE_VERSION}", "technoboggle/haproxy-alpine:${HAPROXY_VERSION}", "technoboggle/haproxy-alpine:latest"]
    args = {
        ALPINE_VERSION="${ALPINE_VERSION}"
        HAPROXY_VERSION="${HAPROXY_VERSION}"
        HAPROXY_BRANCH="${HAPROXY_BRANCH}"
        HAPROXY_MINOR="${HAPROXY_MINOR}"
        HAPROXY_SHA256="${HAPROXY_SHA256}"
        HAPROXY_SRC_URL="${HAPROXY_SRC_URL}"
        DATAPLANE_MINOR="${DATAPLANE_MINOR}"
        DATAPLANE_SHA256="${DATAPLANE_SHA256}"
        DATAPLANE_URL="${DATAPLANE_URL}"
        LIBSLZ_VERSION="${LIBSLZ_VERSION}"
        LIBSLZ_SHA256="${LIBSLZ_SHA256}"
        HAPROXY_UID="${HAPROXY_UID}"
        HAPROXY_GID="${HAPROXY_GID}"

        MAINTAINER_NAME = "${MAINTAINER_NAME}"
        AUTHORNAME = "${AUTHORNAME}"
        AUTHORS = "${AUTHORS}"
        VERSION = "${VERSION}"

        SCHEMAVERSION = "${SCHEMAVERSION}"
        NAME = "${NAME}"
        DESCRIPTION = "${DESCRIPTION}"
        URL = "${URL}"
        VCS_URL = "${VCS_URL}"
        VENDOR = "${VENDOR}"
        BUILDVERSION = "${BUILD_VERSION}"
        BUILD_DATE="${BUILD_DATE}"
        DOCKERCMD:"${DOCKERCMD}"
        USAGE:"${USAGE}"
    }
    platforms = ["linux/arm64", "linux/amd64"]
    push = true
    cache = false
    progress = "plain"
}
