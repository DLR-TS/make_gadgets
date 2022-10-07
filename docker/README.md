# Make Gadgets docker Makefile

This directory contains a Makefile with docker helper targets.  They can be
imported to extend your makefile or called directly.

## Docker tools Makefile
This directory contains a Makefile that enhance vanilla docker with make.

The Makefile also provides several practical targets that wrap the functionality of the docker-image-cacher.sh tool
provided in this project.

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

## docker-image-cacher.sh
The docker-image-cacher.sh is a utility script for caching docker images with the goal of saving network resources.

There are several major functions this script offers namely fetching, saving, loading, and printing.  All of these
will be discussed in the coming sections.

### Printing
you can call docker-image-cacher.sh with the -p or --print flag to perform a print operation.

The print operation or action simply prints the docker image list that will be fetched and cached/saved with their respective
operations.

### Fetching
You can call docker-image-cacher.sh with the -f or --fetch flag to perform a fetch operation.

There are two ways this can be done. The fist way provides a docker image search path as a basis
to collect a list of images to fetch as in the following example:
```bash
bash docker-image-cacher.sh --docker-image-search-path "${HOME}" --fetch
```
All Dockerfiles in the search path provided will be recursively searched for the docker key word "FROM". Any image 
that is referenced by "FROM IMAGE:TAG" in any Dockerfile within the search path will be fetched with docker using 
the docker pull command.

The second way to fetch docker images is to provide no search path such as follows:
```bash
bash docker-image-cacher.sh --fetch
```
This will effectively update every image already loaded into docker on your host.

### Saving
Similar to fetching saving can be called in two ways.  The first way is to provide a search path
```bash
bash docker-image-cacher.sh --docker-image-search-path "<some path to search>" --save
```
resulting in every discovered docker image will be saved into the default docker image cache directory as an archive 
for each image. 

Another way to call save is without a search path such as follows:
```bash 
bash docker-image-cacher.sh --save
```
Every image in the docker registry will be saved to disk as a tar archive into
the default docker image cache directory.

In order for save to work all docker images in the image list must exist in the docker registry. An image can be added
to the registry in multiple ways:
- Calling 'docker build' on a Dockerfile containing an image reference will pull it to the local registry
- Calling 'docker pull <repository:tag>'
- Using docker-image-cacher.sh with the --fetch flag to batch pull a list of images.

### Loading
All images that are cached as tar archives in the default docker image cache directory will be loaded into the docker registry.
```bash
bash docker-image-cacher.sh --load
```

### Help
To view more documentation on this tool you can run the help flag:
```bash
bash docker-image-cacher.sh --help
```

## Use Cases
This section will give a few practical use cases for the docker-image-cacher.sh tool

### Scrape your home directory for docker images, fetch them, and save them
```bash
bash docker-image-cacher.sh --fetch --save
```
Your home directory must have at least one Dockerfile somewhere in the directory tree.

### Save all docker images in the local registry to the default cache location
```bash
bash docker-image-cacher.sh --save
```

### Load docker images from the default cache location into the local registry
```bash
bash docker-image-cacher.sh --load
```

### Fetch and save the docker image 'ubuntu:latest'
```bash
bash docker-image-cacher.sh --save --fetch -i 'ubuntu:latest'
```

### Fetch and save the docker image 'ubuntu:latest' and 'alpine:latest'
```bash
bash docker-image-cacher.sh --save --fetch -i 'ubuntu:latest alpine:latest'
```


