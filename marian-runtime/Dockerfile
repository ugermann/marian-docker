FROM mariannmt/marian-compiled:${MCTAG} as compiled
FROM nvidia/cuda:10.2-cudnn7-runtime-ubuntu16.04
LABEL MAINTAINER="Ulrich Germann <ugermann@inf.ed.ac.uk>"

ARG PROGRAMS=/marian-dev/build/rest-server
#     /marian-dev/build/websocket-server  \
#     /marian-dev/build/amqp-worker \
#     /marian-dev/build/marian-decoder \

WORKDIR /opt/app/marian
COPY --from=compiled ${PROGRAMS} /opt/app/marian/bin/
COPY --from=compiled /marian-dev/src/server/rest /opt/app/marian/rest
