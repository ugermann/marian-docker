ARG BETAG
FROM mariannmt/build-environment:${BETAG}
LABEL MAINTAINER="Ulrich Germann <ugermann@inf.ed.ac.uk>"
ARG MARIAN_VERSION=cd846b0
ARG BUILD_ARCH=x86-64 

RUN git clone https://github.com/marian-nmt/marian-dev \
    && mkdir marian-dev/build

WORKDIR marian-dev/build
RUN git checkout ${MARIAN_VERSION}
RUN cmake \
       -DBUILD_ARCH=${BUILD_ARCH} \
       -DCMAKE_BUILD_TYPE=Release \
       -DUSE_STATIC_LIBS=on \
       -DUSE_SENTENCEPIECE=on \
       ..
RUN make -j
