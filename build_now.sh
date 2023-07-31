#!/usr/bin/env sh

owd="$(pwd)"
cd "$(dirname "$0")" || exit

haproxy_ver="2.8.1"
alpine_ver="3.18.2"

# Setting File permissions
xattr -c .git
xattr -c .gitignore
xattr -c .dockerignore
xattr -c ./*
chmod 0666 ./*
find "$(pwd)" -type d -exec chmod ugo+x {} \;
find "$(pwd)" -type f -exec chmod ugo=wr {} \;
find "$(pwd)" -type f \( -iname \*.sh -o -iname \*.py \) -exec chmod ugo+x {} \;

current_builder=$(docker buildx ls | grep -i '\*' | head -n1 | awk '{print $1;}')
docker buildx create --name tb_builder --use --bootstrap

docker login -u="technoboggle" -p="dckr_pat_FhwkY2NiSssfRBW2sJP6zfkXsjo"

#docker network create haproxy
docker buildx build -f Dockerfile --platform linux/arm64,linux/amd64,linux/386 \
    -t technoboggle/haproxy-alpine:"$haproxy_ver-$alpine_ver" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --verify HEAD)" \
    --build-arg BUILD_VERSION=0.05 \
    --progress=plain \
    --no-cache \
    --push .
#--progress=plain

docker run -it -d --rm -p 8010:80 -p 4430:443 \
    --name myhaproxy technoboggle/haproxy-alpine:"$haproxy_ver-$alpine_ver"

docker container stop -t 10 myhaproxy

docker buildx use "${current_builder}"
docker buildx rm tb_builder

cd "$owd" || exit
