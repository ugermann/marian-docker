# Docker files for deploying Marian-as-a-Service in a Docker container.

This repository contains docker files for deploying Marian as a REST service in a Docker container.
At this point, each instance supports only a translation direction. (In the future, the Marian REST server may also support multiple models in one instance, but currently it's a single system per instance.)

## Preparatory steps

1. Put all necessary files into a directory:
   - the binarized model file(s). Binarize with `marian-conv` from the Marian distribution.
   - the vocabulary file(s)
   - the decoder.yml file. You'll have to create this or adapt it from the decoder file written 
     by the Marian training process. Here's an example:
     ```
     relative-paths: true
     models:
       - model.bin
     vocabs:
       - joint-vocab.spm
       - joint-vocab.spm
     beam-size: 4
     normalize: 1
     word-penalty: 0
     mini-batch: 128
     maxi-batch: 100
     maxi-batch-sort: src

     # The following are specific to the marian REST server
     # source-language and target-language are used for the Demo
     # interface; the ssplit-prefix-file is from the Moses sentence splitter
     # and comes with the marian REST server image. Pick the right one
     # for your source language. SSPLIT_ROOT_DIR is set to the appropriate
     # value in the `mariannmt/marian-rest-server` image.
     source-language: German
     target-language: English
     ssplit-prefix-file: ${SSPLIT_ROOT_DIR}/nonbreaking_prefixes/nonbreaking_prefix.de
     ```
## Running the server locally
   - without GPU utilization:
     ```
     docker run --rm -d -p 18080:18080 -v /path/to/the/model/directory:/opt/app/marian/model mariannmt/marian-rest-server
     ```
   - with GPU utilization. This requires Docker 19.03 or above (see https://github.com/NVIDIA/nvidia-docker) 
     and unfortunately currently won't work within docker-compose (see https://github.com/docker/compose/issues/6691).
     ```
     docker run --rm --gpus device=${GPU_IDs} -d -p 18080:18080 -v /path/to/the/model/directory:/opt/app/marian/model mariannmt/marian-rest-server
     ```
     where GPU_IDs is a comma-separated list of GPUs on the host that should be made available to the Docker container.

You'll find a web translation page at `http://localhost:18080/api/elg/v1`. The API is described [here](https://github.com/ugermann/marian-docker/wiki/The-ELG-Translation-API)


## Creating a Docker image including the model
   For easy deployment in a cluster, you may want create a Docker image with the model integrated.
   1. copy the `./marian-mt-service/Dockerfile` from this repository into your model directory.
   2. run
        ```
        docker build -t ${IMAGE_ID} /path/to/the/model/directory
        ```
      IMAGE_ID is the name of the resulting Docker image (e.g. <your dockerhub account>/marian-rest-server:<model id>).
      
   3. to publish, push the image to dockerhub:
      ```
      docker push ${IMAGE_ID}
      ```
## Recreating `mariannmt/marian-rest-server`
Normally, this is not necessary. **Do this only if you can't find mariannmt/marian-rest-server:latest, or if you are using your own custom version of Marian server.**

In order to achieve compact images, we use a staged build process:
- Create an image that contains the build environment. 
- Compile Marian in a separate build process that uses the build environment image as its base image.
- Create a new image and copy only the necessary bits and pieces into the new image.

```
make image/build-environment
make image/marian-compiled
make image/marian-runtime
```
