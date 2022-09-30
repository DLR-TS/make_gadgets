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
    -s|--search-path)
      DOCKER_IMAGE_SEARCH_PATH="$2"
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

if [[ -z "${DOCKER_IMAGE_SEARCH_PATH}" ]]; then
    echoerr "ERROR: No docker image search path provided. A docker image search path must be supplied with -s or --search-path flag."
fi

if [[ ! -d "${DOCKER_IMAGE_SEARCH_PATH}" ]]; then
    echoerr "ERROR: The provided docker image search path: ${DOCKER_IMAGE_SEARCH_PATH} does not exist."
fi

mkdir -p "${DOCKER_IMAGE_CACHE_DIRECTORY}"
docker_image_cache_directory_absolute_path="$(realpath "${DOCKER_IMAGE_CACHE_DIRECTORY}")"
mkdir -p "${docker_image_cache_directory_absolute_path}"

docker_image_search_path_absolute="$(realpath "${DOCKER_IMAGE_SEARCH_PATH}")"

echodebug "  docker_save.sh"
echodebug "    DOCKER_IMAGE_SEARCH_PATH: ${DOCKER_IMAGE_SEARCH_PATH}"
echodebug "    docker_image_search_path_absolute: ${docker_image_search_path_absolute}"
echodebug "    DOCKER_IMAGE_CACHE_DIRECTORY: ${DOCKER_IMAGE_CACHE_DIRECTORY}"
echodebug "    docker_image_cache_directory_absolute_path: ${docker_image_cache_directory_absolute_path}"


docker_files=$(cd "${docker_image_search_path_absolute}" && find . -type f -name Dockerfile* | uniq | sort)
(
cd "${docker_image_search_path_absolute}"
for docker_file in ${docker_files}; do
    docker_image="$(grep -i "FROM " "${docker_file}" | head -1 | cut -d" " -f2)"
    docker_images+="\n${docker_image}"
done
)

docker_images="$(echo -e "${docker_images}" | uniq)"
docker_images_count="$(echo -e "${docker_images}" | wc -l)"

echodebug "  docker_images_count: ${docker_images_count}"

cd "${docker_image_cache_directory_absolute_path}"
for docker_image in $docker_images; do
    
    docker_image_archive="${docker_image_cache_directory_absolute_path}/$(echo "${docker_image//:/_}" | sed "s|/|_|g").tar"
    docker_image_archive="$(echo "${docker_image//:/_}" | sed "s|/|_|g").tar"
    echodebug "    docker image: ${docker_image}"
    echodebug "    docker image archive: ${docker_image_archive}"
    if [[ -f "${docker_image_archive}" ]]; then
        echo "    docker image: ${docker_image} already exists in the cache: ${docker_image_cache_directory_absolute_path} skipping fetch."
    else
        docker pull "${docker_image}" 2>/dev/null || true
        docker save --output "${docker_image_archive}" "${docker_image}" 2>/dev/null || true
    fi
done

docker pull edrevo/dockerfile-plus && docker save --output edrevo_dockerfile-plus.tar edrevo/dockerfile-plus
