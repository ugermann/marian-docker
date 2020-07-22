#!/bin/bash

NPROC=${NPROC:-$(nproc)}

if [[ "$(which nvidia-smi)" == "" ]]; then
    bin/rest-server --cpu-threads $NPROC $@
else
    bin/rest-server $@
fi
