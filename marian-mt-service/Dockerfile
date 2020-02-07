FROM mariannmt/marian-rest-server:latest
ARG MAINTAINER="Ulrich Germann <ugermann@inf.ed.ac.uk>"
ENV SSPLIT_ROOT_DIR=/opt/app/ssplit
LABEL Maintainer=${MAINTAINER}
COPY . /opt/app/marian/model/
WORKDIR /opt/app/marian
RUN chmod +x bin/start_rest_server.sh
CMD ["bin/start_rest_server.sh", "-c", "model/decoder.yml"]


