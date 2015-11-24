#/bin/bash

pushd $(dirname $(dirname $BASH_SOURCE))

pub run test -j 1 -p vm -p content-shell -r expanded