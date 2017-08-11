#!/bin/bash

set -e

[[ -z "${ZIPKIN_VERSION}" ]] && ZIPKIN_VERSION="0.3.1"

BASE_DIR=`pwd`/..
DIST_DIR=${BASE_DIR}/dist

IMAGE_NAME=zipkin-cpp-build:ubuntu
CONTAINER_NAME=zipkin-cpp-build

# When running docker on a Mac, root user permissions are required.
if [[ "$OSTYPE" == "darwin"* ]]; then
    USER=root
    USER_GROUP=root
else
    USER=$(id -u)
    USER_GROUP=$(id -g)
fi

function container_is_exists {
    local CONTAINER_ID=`docker ps -a -q -f "name=${CONTAINER_NAME}" -f "ancestor=${IMAGE_NAME}"`

    [[ -n $CONTAINER_ID ]]
}

function container_is_running {
    local CONTAINER_ID=`docker ps -q -f "name=${CONTAINER_NAME}" -f "ancestor=${IMAGE_NAME}"`

    [[ -n $CONTAINER_ID ]]
}

function run_container {
    echo "run new container"

    docker run --name ${CONTAINER_NAME} -u "${USER}":"${USER_GROUP}" -v ${DIST_DIR}:/zipkin-cpp/dist ${IMAGE_NAME} $1
}

if container_is_exists; then
    if container_is_running; then
        docker logs -f ${CONTAINER_NAME}
    else
        docker rm ${CONTAINER_NAME}

        run_container
    fi
else
    run_container
fi

PKG_TYPE=$2

if [[ -d ${DIST_DIR} ]]; then
    cd ${DIST_DIR}

    if [[ `gem list -i fpm` != 'true' ]]; then
        gem install fpm -f --no-document
    fi

    fpm -f --prefix /usr/local -s dir -t $PKG_TYPE -n zipkin-cpp -v ${ZIPKIN_VERSION} include lib

    if [ "$PKG_TYPE" == 'osxpkg' ]; then
        pkgutil --payload-files zipkin-cpp-${ZIPKIN_VERSION}.pkg
    fi
fi
