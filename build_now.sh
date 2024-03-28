#!/usr/bin/env sh

owd="$(pwd)"
cd "$(dirname "$0")" || exit

BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
VCS_REF="$(git rev-parse --verify HEAD)"

export BUILD_DATE
export VCS_REF

sed -i.bu -E 's/BUILD_DATE=".*"/BUILD_DATE="'"${BUILD_DATE}"'"/g' env.hcl
sed -i.bu -E 's/VCS_REF=".*"/VCS_REF="'"${VCS_REF}"'"/g' env.hcl

if [ -f env.hcl ]; then
    while IFS= read -r line; do
        export "$line"
    done <env.hcl
fi

DOCKERCMD='docker run -it -d --rm -p 53:53 --name myhaproxy technoboggle/haproxy-alpine:'"${HAPROXY_VERSION//\"/}-${ALPINE_VERSION//\"/}"

sed -i.bu -E 's#DOCKERCMD=".*"#DOCKERCMD="'"${DOCKERCMD//\"/}"'"#g' env.hcl

export DOCKERCMD

if [ -f .perms ]; then
    export $(cat .perms | xargs)
fi

# Setting File permissions
xattr -c .git
xattr -c .gitignore
xattr -c .dockerignore
xattr -c ./*

find "$(pwd)" -type d -exec chmod ugo+x {} \;
find "$(pwd)" -type f -exec chmod ugo=wr {} \;
find "$(pwd)" -type f \( -iname \*.sh -o -iname \*.py \) -exec chmod ugo+x {} \;
chmod 0666 .gitignore
chmod 0666 .dockerignore

docker login -u="${DOCKER_USER}" -p="${DOCKER_PAT}"

current_builder=$(docker buildx ls | grep -i '\s\*' | head -n1 | awk '{print $1;}')



if [ -z "${BUILD_LOCALLY}" ] || [[ "${BUILD_LOCALLY}" =~ ^(false|FALSE|N|n)$ ]]; then
    echo "Building locally"
    docker buildx create --name technoboggle_builder --use --bootstrap
    docker buildx bake -f env.hcl -f docker-bake.hcl --builder technoboggle_builder --no-cache --push
else
    echo "Building remotely"
    #docker buildx create --driver cloud technoboggle/production
    docker buildx use cloud-technoboggle-production
    docker buildx bake -f docker-bake.hcl -f env.hcl --builder "${CLOUD_BUILDER}" --no-cache --push
fi


#docker buildx create --name technoboggle_builder --use --bootstrap
#docker buildx bake -f env.hcl -f docker-bake.hcl --builder technoboggle_builder --no-cache --push

# The following would be for a remote builder
#docker buildx create --driver cloud technoboggle/production
#docker buildx bake -f docker-bake.hcl -f env.hcl --builder cloud-technoboggle-production --no-cache --push
sed -i.bu -E 's/BUILD_DATE=".*"/BUILD_DATE=""/g' env.hcl
sed -i.bu -E 's/VCS_REF=".*"/VCS_REF=""/g' env.hcl
sed -i.bu -E 's/DOCKERCMD=".*"/DOCKERCMD=""/g' env.hcl

rm -f env.hcl.bu


echo "Running the container, using the following command:"
echo "  ${DOCKERCMD}"
echo
docker run -it -d --rm -p 53:53 --name myhaproxy technoboggle/haproxy-alpine:"${HAPROXY_VERSION//\"/}-${ALPINE_VERSION//\"/}"

docker container stop -t 10 myhaproxy

echo "Switching back to builder: ${current_builder}"
docker buildx use "${current_builder}"
if [ -z "${BUILD_LOCALLY}" ] || [[ "${BUILD_LOCALLY}" =~ ^(false|FALSE|N|n)$ ]]; then
    docker buildx rm technoboggle_builder
fi

cd "$owd" || exit
