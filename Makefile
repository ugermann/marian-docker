# -*- mode: makefile-gmake; indent-tabs-mode: true; tab-width: 4 -*-
SHELL   = bash
PWD     = $(shell pwd)
mydir  := $(dir $(lastword ${MAKEFILE_LIST}))

TARGET_REGISTRY=mariannmt
MARIAN_REPO=https://github.com/marian-nmt/marian-dev
MARIAN_VERSION=ug-marian-aas

# Docker image tags BE: build environment, RT: runtime
BETAG=$(shell git log -1 --abbrev-commit -- build-environment/ | awk '/commit/ { print $$2 }')
RTTAG=$(shell git rev-parse --short HEAD)

# Build a Docker image with everything we need to compile Marian.
.PHONY: image/build-enviroment
image/build-environment: IMAGE=build-environment
image/build-environment: FLAGS=${DOCKER_BUILD_ARGS}
image/build-environment:
	docker build -t ${TARGET_REGISTRY}/${IMAGE}:${BETAG} ${FLAGS} ${IMAGE}
	docker tag ${TARGET_REGISTRY}/${IMAGE}:${BETAG} ${TARGET_REGISTRY}/${IMAGE}:latest

# Check out Marian source code
marian/code/CMakeLists.txt:
	mkdir -p marian
	git clone ${MARIAN_REPO}  marian/code

# Assemble command for compilation: 
cmake_cmd  = cmake -DBUILD_ARCH=x86-64
cmake_cmd += -DCMAKE_BUILD_TYPE=Release
cmake_cmd += -DUSE_STATIC_LIBS=on
cmake_cmd += -DUSE_SENTENCEPIECE=on

docker_mounts  = ${PWD}/marian/code:/repo
docker_mounts += ${PWD}/marian/build:/build
run_on_docker  = docker run --rm 
run_on_docker += $(addprefix -v, ${docker_mounts})
run_on_docker += --user $$(id -u):$$(id -g) 
run_on_docker += ${IMAGE}

# Target for running cmake
marian/build/CMakeCache.txt: MARIAN_VERSION=ug-marian-aas3
marian/build/CMakeCache.txt: IMAGE=${TARGET_REGISTRY}/build-environment
marian/build/CMakeCache.txt: marian/code/CMakeLists.txt
marian/build/CMakeCache.txt:
	mkdir -p ${@D}
	cd marian/code && git checkout ${MARIAN_VERSION} 
	${run_on_docker} bash -c 'cd /build && ${cmake_cmd} /repo'

marian/build/marian: marian/build/CMakeCache.txt
marian/build/marian: marian/code/.git
	${run_on_docker} bash -c 'cd /build && make -j'

runtime: marian-rest-server/opt/app/marian/bin/rest-server

marian-rest-server/opt/app/marian/bin/rest-server: IMAGE=mariannmt/build-environment
marian-rest-server/opt/app/marian/bin/rest-server: marian/build/marian
marian-rest-server/opt/app/marian/bin/rest-server: docker_mounts += ${PWD}/marian-rest-server/opt/app:/opt/app
marian-rest-server/opt/app/marian/bin/rest-server:
	mkdir -p ${@D}
	${run_on_docker} bash -c '/usr/bin/strip /build/rest-server -o /opt/app/marian/bin/rest-server'

image/marian-rest-server: IMAGE=marian-rest-server
image/marian-rest-server: marian-rest-server/opt/app/marian/bin/rest-server
image/marian-rest-server: marian/code/CMakeLists.txt
	mkdir -p marian-rest-server/opt/app/ssplit 
	rsync -avui marian/code/src/3rd_party/ssplit-cpp/nonbreaking_prefixes marian-rest-server/opt/app/ssplit
	rsync -avui marian/code/src/server/rest marian-rest-server/opt/app/marian
	docker build -t ${TARGET_REGISTRY}/${IMAGE}:${RTTAG} ${IMAGE}
	docker tag ${TARGET_REGISTRY}/${IMAGE}:${RTTAG} ${TARGET_REGISTRY}/${IMAGE}:latest
