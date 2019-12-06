# -*- mode: makefile-gmake; indent-tabs-mode: true; tab-width: 4 -*-
SHELL   = bash
mydir  := $(dir $(lastword ${MAKEFILE_LIST}))

REGISTRY=mariannmt

BETAG=$(shell git rev-parse --short HEAD -- build-environment)
MCTAG=$(shell git rev-parse --short HEAD -- build-environment marian-compiled)

image/build-environment: IMAGE=build-environment
image/build-environment: FLAGS=${DOCKER_BUILD_ARGS}
image/build-environment:
	docker build -t ${REGISTRY}/${IMAGE}:${BETAG} ${FLAGS} ${IMAGE}

image/marian-compiled: IMAGE=marian-compiled
image/marian-compiled: FLAGS=${DOCKER_BUILD_ARGS}
image/marian-compiled: FLAGS+=--build-arg BETAG=${BETAG}
image/marian-compiled:
	docker build -t ${REGISTRY}/${IMAGE}:${MCTAG} ${FLAGS} ${IMAGE}

image/marian-runtime: IMAGE=marian-runtime
image/marian-runtime: FLAGS=${DOCKER_BUILD_ARGS}
image/marian-runtime: TAG=${MARIAN_VERSION}
image/marian-runtime: BUILD_ARGS=MARIAN_COMPILED=${REGISTRY}/marian-compiled:${MARIAN_VERSION}
image/marian-runtime:
	docker build -t ${REGISTRY}/${IMAGE}:${TAG} $(addprefix --build-arg ,${BUILD_ARGS}) ${FLAGS} ${IMAGE}
	docker tag ${REGISTRY}/${IMAGE}:${TAG} ${REGISTRY}/${IMAGE}:latest
