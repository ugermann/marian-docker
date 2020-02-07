# marian-docker
Docker files for deploying Marian in a Docker container.

### Creating a Docker image based on `mariannmt/marian-rest-server:latest`

This is the most convenient way to create a Docker image for a specific model.

1. Put all necessary files into a directory:
   - the binarized model file(s). Binaries with `marian-conv` from the Marian distribution.
   - the vocabulary file(s)
   - the Dockerfile from `marian-mt-service` in this repository
   - the decoder.yml file. You'll have to create this. Here's an example:
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
2. Build the image
   ```
   docker build -t my-mt-service /path/to/the/directory/with/the/model
   ```

3. Run it
   ```
   docker run --rm -d -p 18080:18080 my-mt-service
   ```

   If you use docker 19.03 or above, use 
   ```
   docker run --gpus device=0 --rm -d -p 18080:18080 my-mt-service
   ```
   to have the container make use of the GPU #0.
   See https://github.com/NVIDIA/nvidia-docker for more information on
   using the host's GPU in a running docker container. 
   

You'll find a web translation page at `http://localhost:18080/api/elg/v1`


## Recreating `mariannmt/marian-rest-server`

```
make image/build-environment
make image/marian-compiled
make image/marian-runtime
```
