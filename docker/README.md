# Make Gadgets docker Makefile

This directory contains a Makefile with docker helper targets.  They can be
imported to extend your makefile or called directly.

## Docker tools Makefile
This directory contains a Makefile that enhance vanilla docker with make.

The Makefile provided in this directory contains a wrapper for the docker_image_cacher.sh
also included in this project making it easier to use this tool.

To consume this Makefile you can directly import it to your Makefile such as follows: 
```make
include make_gadgets/docker/Makefile
```

You can directly call the provided targets by calling make directly on this directory:
```bash
cd make_gadgets/docker
make docker_save
...
make docker_load
...
make docker_orbital_cannon
```

## docker_image_cacher.sh
The docker_image_cacher.sh is a utility script for caching docker images with 
the goal of saving network resources.

There are three major functions this script offers namely fetching, saving, and loading.  All of these
will be discussed in the coming sections


### Fetching
You can call docker_image_cacher.sh with the -f or --fetch flag to perform a fetch operation.

There are two ways this can be done. The fist way provides a docker image search path as a basis
to collect a list of images to fetch as in the following example:
```bash
bash docker_image_cacher.sh --docker-image-search-path "${HOME}" --fetch
```
All Dockerfiles in the search path provided will be recursively searched for the docker key word "FROM". Any image 
that is referenced by "FROM IMAGE:TAG" in any Dockerfile within the search path will be fetched with docker using 
the docker pull command.

The second way to fetch docker images is to provide no search path such as follows:
```bash
bash docker_image_cacher.sh --fetch
```
This will effectively update every image already loaded into docker on your host.

### Saving
Similar to fetching saving can be called in two ways.  The first way is to provide a search path
```bash
bash docker_image_cacher.sh --docker-image-search-path "${HOME}" --save
```
resulting in every discovered docker image will be saved into the default docker image cache directory as an archive 
for each image. 

Another way to call save is without a search path such as follows:
```bash
bash docker_image_cacher.sh --save
```
Every image in the docker registry will be saved to disk as a tar archive into
the default docker image cache directory.

### Loading
All images that are cached as tar archives in the default docker image cache directory will be loaded into the docker registry.
```bash
bash docker_image_cacher.sh --load
```

### Help
To view more documentation on this tool you can run the help flag:
```bash
bash docker_image_cacher.sh --help
```
