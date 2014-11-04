#!/bin/bash

CODENAME=$1
ARCH=$2

BUILD_DEPENDENCIES='
git-core g++ nodejs npm libprotobuf-dev
libgoogle-perftools-dev libncurses5-dev libboost-all-dev nodejs-legacy
curl libcurl3 libcurl4-openssl-dev protobuf-compiler'

mk-sbuild --arch=$ARCH $CODENAME
sudo schroot -c source:$CODENAME-$ARCH -- \
    apt-get install -y $BUILD_DEPENDENCIES
