#!/usr/bin/env bash

set -euo pipefail
#set -euxo pipefail

function echoerr { printf "$@" >&2; exit 1;}
echodebug (){ 
    if [ ! -z ${DEBUG+x} ] && [ "${DEBUG}" -eq true ]; then 
        printf "$@\n" >&2;
    fi
}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

DOCKER_IMAGE_CACHE_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/.docker_image_cache")"
SAVE=false
LOAD=false
FETCH=false



POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--docker-image-cache-directory)
      DOCKER_IMAGE_CACHE_DIRECTORY="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--docker-image-search-path)
      DOCKER_IMAGE_SEARCH_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--fetch)
      FETCH=true
      shift # past argument
      ;;
    -s|--save)
      SAVE=true
      shift # past argument
      ;;
    -l|--load)
      LOAD=true
      shift # past argument
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

#if [[ -z "${DOCKER_IMAGE_SEARCH_PATH}" ]]; then
#    echoerr "ERROR: No docker image search path provided. A docker image search path must be supplied with -s or --search-path flag."
#fi

#if [[ ! -d "${DOCKER_IMAGE_SEARCH_PATH}" ]]; then
#    echoerr "ERROR: The provided docker image search path: ${DOCKER_IMAGE_SEARCH_PATH} does not exist."
#fi

function find_docker_base_images(){

    #search_path is a directory containing Dockerfiles 
    local search_path="${1}"

    echodebug "  FROM find_docker_base_images:" 

    if [[ ! -z "${search_path}" ]]; then
        search_path="$(realpath "${search_path}")" 
    fi
    if [[ ! -z "${search_path}" ]] && [[ ! -d "${search_path}" ]]; then
        echoerr "ERROR: The provided docker image search path: ${search_path} does not exist."
    fi

    if [[ -z "${search_path}" ]]; then
        docker_images="$(docker image list --format "{{.Repository}}:{{.Tag}}" | tr '\n' ' ')"
    else
        echodebug "    search_path: ${search_path}" 
        docker_files=$(cd "${search_path}" && find . -type f -name Dockerfile* | uniq | sort)
        cd "${search_path}"
        for docker_file in ${docker_files}; do
            echodebug "        docker_file: ${docker_file}"
            docker_image="$(grep -i "FROM " "${docker_file}" | head -1 | cut -d" " -f2)"
            docker_images+=" ${docker_image}"
        done

        docker_images="$(echo -e "${docker_images}" | uniq)"
    fi
    
    echodebug "    docker_images: ${docker_images}"
    echodebug "    docker_images count: $(echo "${docker_images}" | tr ' ' '\n' | wc -L)"
    echo "${docker_images}"
}

function fetch_docker_images(){

    local docker_images="${1}"

    echodebug "  FROM find_docker_base_images:" 
    
    for docker_image in $docker_images; do
        echo "    fetching docker image: ${docker_image}"
        docker pull "${docker_image}" 2>/dev/null || true
    done
}

function save_docker_images(){

    local docker_image_cache_directory="${1}"
 
    echodebug "  FROM save_docker_images:"

    if [[ -z "${docker_image_cache_directory}" ]]; then
        echoerr "ERROR: The docker image cache directory is not set."
    fi
    docker_image_cache_directory="$(realpath "${docker_image_cache_directory}")" 
    mkdir -p "${docker_image_cache_directory}"
    
    cd "${docker_image_cache_directory}"

    for docker_image in $docker_images; do
        docker_image_archive="${docker_image_cache_directory}/$(echo "${docker_image//:/_}" | sed "s|/|_|g").tar"
        echo "    saving docker image: ${docker_image} to ${docker_image_archive}"
        docker save --output "${docker_image_archive}" "${docker_image}" 2>/dev/null || true
    done

    docker pull edrevo/dockerfile-plus && docker save --output edrevo_dockerfile-plus.tar edrevo/dockerfile-plus

}

function load_docker_images(){

    local docker_image_cache_directory="${1}"
    
    echodebug "  FROM load_docker_images:"

    if [[ ! -d "${docker_image_cache_directory}" ]]; then
        echo "  The provide docker image cache directory: ${docker_image_cache_directory} does not exist. Nothing to load skipping."
    else
        docker_image_cache_directory="$(realpath "${docker_image_cache_directory}")" 

        docker_image_archives="$(ls "${docker_image_cache_directory}"/*.tar)"
        echo "    loading saved docker images in cache directory: ${docker_image_cache_directory}"
        for docker_image_archive in $docker_image_archives; do
            docker_image_archive="$(realpath "${docker_image_archive}")"
            echo "    loading docker image archive: $docker_image_archive"
            docker load --input "${docker_image_archive}"
        done
    fi
}


docker_images="$(find_docker_base_images "${DOCKER_IMAGE_SEARCH_PATH}")"

if [[ "${FETCH}" == true ]]; then
    fetch_docker_images "${docker_images}" 
fi

if [[ "${SAVE}" == true ]]; then
    save_docker_images "${DOCKER_IMAGE_CACHE_DIRECTORY}"
fi

if [[ "${LOAD}" == true ]]; then
    load_docker_images "${DOCKER_IMAGE_CACHE_DIRECTORY}"
fi

