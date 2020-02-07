ARG MCTAG
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
COPY --from=compiled /marian-dev/src/3rd_party/ssplit-cpp/nonbreaking_prefixes /opt/app/ssplit/nonbreaking_prefixes
COPY start_rest_server.sh /opt/app/marian/bin/
