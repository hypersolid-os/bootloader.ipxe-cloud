#!/usr/bin/env bash

set -e

# basedir
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKINGDIR="$(pwd)"

# create environment
docker build \
    -t hypersolid-boot-cloudserver \
    .

# container already exists ?
docker container rm hypersolid-boot-cloudserver-env || echo "ok"

# create image
docker run \
    --privileged=true \
    --volume /dev:/dev \
    --name hypersolid-boot-cloudserver-env \
    --tty \
    --interactive \
    hypersolid-boot-cloudserver

# copy disk image
docker cp hypersolid-boot-cloudserver-env:/tmp/disk.img.gz $WORKINGDIR/dist/boot.img.gz
