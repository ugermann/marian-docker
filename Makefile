# -*- mode: makefile-gmake; indent-tabs-mode: true; tab-width: 4 -*-
SHELL   = bash
PWD     = $(shell pwd)
mydir  := $(dir $(lastword ${MAKEFILE_LIST}))

TARGET_REGISTRY=mariannmt

all: image/marian-rest-server

# Docker image tags and image names:
# BE stands for 'build environment', RT for 'runtime'
BE.TAG=$(shell git log -1 --abbrev-commit -- build-environment/ | awk '/commit/ { print $$2 }')
RT.TAG=$(shell git rev-parse --short HEAD)
BE.IMAGE=${TARGET_REGISTRY}/build-environment:${BE.TAG}
RT.IMAGE=${TARGET_REGISTRY}/marian-rest-server:${RT.TAG}

# Pull or build the Docker image with everything we need to compile Marian.
.PHONY: image/build-enviroment
image/build-environment:
	docker pull ${BE.IMAGE} || docker build -t ${BE.IMAGE} ${@F}
	docker tag ${BE.IMAGE} $(patsubst %:${BE.TAG},%:latest,${BE.IMAGE})

# Update or check out Marian source code if necessary
marian/code/.git: update-marian
update-marian:
	git submodule update --init

# Commands for compilation:
cmake_cmd  = cmake -DBUILD_ARCH=x86-64
cmake_cmd += -DCMAKE_BUILD_TYPE=Release
cmake_cmd += -DUSE_STATIC_LIBS=on
cmake_cmd += -DUSE_SENTENCEPIECE=on

# ... and running things on Docker
docker_mounts  = ${PWD}/.git:/.git
docker_mounts += ${PWD}/marian/code:/marian/code
docker_mounts += ${PWD}/marian/build:/marian/build
run_on_docker  = docker run --rm
run_on_docker += $(addprefix -v, ${docker_mounts})
run_on_docker += --user $$(id -u):$$(id -g)
run_on_docker += ${IMAGE}

# Run cmake
marian/build/CMakeCache.txt: IMAGE=${BE.IMAGE}
marian/build/CMakeCache.txt:
	mkdir -p ${@D}
	git submodule update --init
	${run_on_docker} bash -c 'cd /marian/build && ${cmake_cmd} /marian/code'

# Build Marian rest server
marian/build/marian: IMAGE=${BE.IMAGE}
marian/build/marian: .git/modules/marian/code
marian/build/marian: marian/build/CMakeCache.txt
	${run_on_docker} bash -c 'cd /marian/build && make -j'

# Strip symbols from REST server executable to keep things compact
marian-rest-server/opt/app/marian/bin/rest-server: IMAGE=${BE.IMAGE}
marian-rest-server/opt/app/marian/bin/rest-server: docker_mounts += ${PWD}/marian-rest-server/opt/app:/opt/app
marian-rest-server/opt/app/marian/bin/rest-server: marian/build/marian
	mkdir -p ${@D}
	${run_on_docker} bash -c '/usr/bin/strip /marian/build/rest-server -o /opt/app/marian/bin/rest-server'

# update auxiliary files
marian-rest-server/opt/app/ssplit/nonbreaking_prefixes: .git .git/modules/marian/code
marian-rest-server/opt/app/ssplit/nonbreaking_prefixes: marian/code/src/3rd_party/ssplit-cpp/nonbreaking_prefixes
	mkdir -p ${@D}
	rsync -avui $< ${@D}

marian-rest-server/opt/app/marian/rest: .git .git/modules/marian/code
marian-rest-server/opt/app/marian/rest: marian/code/src/service/rest
	rsync -avui $< ${@D}

# Build the Docker image for the Marian REST server
image/marian-rest-server: IMAGE=${RT.IMAGE}
image/marian-rest-server: marian-rest-server/opt/app/ssplit/nonbreaking_prefixes
image/marian-rest-server: marian-rest-server/opt/app/marian/rest
image/marian-rest-server: marian-rest-server/opt/app/marian/bin/rest-server
	docker build -t ${IMAGE} ${@F}
	docker tag ${IMAGE} $(patsubst %:${RT.TAG},%:latest,${IMAGE})
