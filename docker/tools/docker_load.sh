#!/usr/bin/env bash 

set -e

function echoerr { echo "$@" >&2; exit 1;}
function echodebug { [ ! -z $DEBUG ] && echo "$@" >&2;}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DOCKER_IMAGE_CACHE_DIRECTORY="${SCRIPT_DIRECTORY}/.cache"

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--docker-image-cache-directory)
      DOCKER_IMAGE_CACHE_DIRECTORY="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ ! -d "${DOCKER_IMAGE_CACHE_DIRECTORY}" ]]; then
    echoerr "ERROR: The provided docker image cache directory: ${DOCKER_IMAGE_CACHE_DIRECTORY} does not exist."
    echo "  The provide docker image cache directory: ${DOCKER_IMAGE_CACHE_DIRECTORY} does not exist. Nothing to load skipping."
    exit 0
fi

docker_image_cache_directory_absolute_path="$(realpath "${DOCKER_IMAGE_CACHE_DIRECTORY}")"

docker_image_archives="$(ls "${docker_image_cache_directory_absolute_path}"/*.tar)"
echo "    loading saved docker images in: ${docker_image_cache_directory_absolute_path}"
for docker_image in $docker_image_archives; do
  docker_image="$(realpath "${docker_image}")"
  echo "    Loading: $docker_image"
  docker load --input "${docker_image}"
done


