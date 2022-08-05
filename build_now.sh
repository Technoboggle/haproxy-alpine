#!/usr/bin/env sh

owd="`pwd`"
cd "$(dirname "$0")"

haproxy_ver="2.7"
alpine_ver="3.16.1"

# Setting File permissions
xattr -c .git
xattr -c .gitignore
xattr -c .dockerignore
xattr -c *
chmod 0666 *
chmod 0777 *.sh

#docker network create haproxy
docker build -f Dockerfile -t technoboggle/haproxy-alpine:"$haproxy_ver-$alpine_ver" --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg VCS_REF="`git rev-parse --verify HEAD`" --build-arg BUILD_VERSION=0.05 --no-cache .
#--progress=plain 

docker run -it -d --rm -p 8010:80 -p 4430:443 --name myhaproxy technoboggle/haproxy-alpine:"$haproxy_ver-$alpine_ver"

#docker tag technoboggle/haproxy-alpine:"$haproxy_ver-$alpine_ver" technoboggle/haproxy-alpine:latest
docker login
docker push technoboggle/haproxy-alpine:"$haproxy_ver-$alpine_ver"
#docker push technoboggle/haproxy-alpine:latest
docker container stop -t 10 myhaproxy

cd "$owd"
