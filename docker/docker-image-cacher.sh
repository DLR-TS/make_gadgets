#!/usr/bin/env bash

set -euo pipefail
#set -euxo pipefail

function echoerr { printf "$@" >&2; exit 1;}
echodebug (){ 
    if [ ! -z "${DEBUG+x}" ] && [ "${DEBUG}" == true ]; then 
        printf "$@\n" >&2;
    fi
}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

DOCKER_IMAGE_CACHE_DIRECTORY="$(realpath "${SCRIPT_DIRECTORY}/.docker_image_cache")"
#DOCKER_IMAGE_SEARCH_PATH="${HOME}"
DOCKER_IMAGE_SEARCH_PATH=""

DOCKER_IMAGE_EXCLUSION_LIST=""
DOCKER_IMAGE_INCLUSION_LIST=""

SAVE=false
LOAD=false
CONDITIONAL_LOAD=false
FETCH=false
PRINT=false

help (){
 
    printf "  \n"
    printf "docker-image-cacher.sh is a Docker image caching tool. \n\n"
    printf "  \n"
    printf "  Usage: bash docker-image-cacher.sh [OPTIONS]\n\n"

    printf "         Scrape your home directory for docker images, fetch them, and save them:\n"
    printf "             bash docker-image-cacher.sh --fetch --save \n\n"

    printf "         Save all docker images in the local registry to the default cache location:\n"
    printf "             bash docker-image-cacher.sh --save"

    printf "         Load docker images from the default cache location into the local registry: \n"
    printf "             bash docker-image-cacher.sh --load \n\n"
    
    printf "         Fetch and save the docker image 'ubuntu:latest': \n"
    printf "             bash docker-image-cacher.sh --save --fetch -i 'ubuntu:latest' \n\n"

    printf "         Fetch and save the docker image 'ubuntu:latest' and 'alpine:latest': \n"
    printf "             bash docker-image-cacher.sh --save --fetch -i 'ubuntu:latest alpine:latest' \n\n"


    printf "  Description: This tool can be used to discover, fetch, cache, and load docker images in your local \n"
    printf "               registry with the goal of saving bandwidth. Docker images are saved and loaded from tar archives \n\n"

    printf "  Options: \n"

    printf "           -i, --docker-image-inclusion-list [inclusion list] OPTIONAL\n"
    printf "                                                  The docker image exclusion list is a space separated list \n"
    printf "                                                  of docker images to include in fetching and caching in \n"
    printf "                                                  addition to images scraped the docker image search path \n"
    printf "                                                  example: 'ubuntu:latest debian:latest' \n\n"

    printf "           -x, --docker-image-exclusion-list [exclusion list] OPTIONAL\n"
    printf "                                                  The docker image exclusion list is a space separated list \n"
    printf "                                                  of docker images to be excluded from fetching and caching. \n"
    printf "                                                  example: 'ubuntu:latest debian:latest' \n\n"

    printf "           -d, --docker-image-search-path [directory] OPTIONAL - DEFAULT: '\$HOME' --> ${HOME}\n"
    printf "                                                  This flag provides a search path to discover docker \n"
    printf "                                                  images.  This path will be recursively scraped for \n"
    printf "                                                  Dockerfiles containing 'from <repository>:<tag>'. If no \n"
    printf "                                                  docker image search path is provide then docker images \n"
    printf "                                                  are pulled from the local registry via 'docker image ls'. \n\n"

    printf "           -c, --docker-image-cache-directory [directory] OPTIONAL - DEFAULT: '${DOCKER_IMAGE_CACHE_DIRECTORY}'\n"
    printf "                                                  The docker image cache directory is were image archives \n" 
    printf "                                                  are saved to and loaded from by this tool. \n"
    printf "                                                  If a cache directory is provided with -c then it will be \n"
    printf "                                                  created including all parent directives using mkdir -p \n\n"

    printf "    Operations: REQUIRED - At least one operation is required! \n"

    printf "           -f, --fetch                            \n"
    printf "                                                  If this flag is provided the list of discovered docker \n"
    printf "                                                  images will be fetched from the Docker central registry \n"
    printf "                                                  using 'docker pull'. \n\n"

    printf "           -s, --save                             Save all discovered docker images to the docker image \n"
    printf "                                                  cache directory as tar archive. Docker images must \n"
    printf "                                                  already be available in the local registry to be saved \n\n"

    printf "           -l, --load                             Load all images in the docker image cache directory from \n"
    printf "                                                  their respective tar archives into the local docker \n"
    printf "                                                  registry \n\n"

    printf "           -p, --print \n"
    printf "                                                  This flag will print all discoverable docker images and \n"
    printf "                                                  exit 0. The strategy used to discovered images is \n"
    printf "                                                  determined by the '-d' flag. If a docker image search \n"
    printf "                                                  path is provided with -d then that path is scraped for \n"
    printf "                                                  potential docker images. If no '-d' flag is provided\n"
    printf "                                                  then the local docker registry is scraped. Discovered \n"
    printf "                                                  images are used for fetching and caching. \n\n"

    printf "           -c, --conditional-load                 Same as load however if there is already any docker \n"
    printf "                                                  images in the local registry then this is a NOOP. \n\n"

}

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
    -c|--conditional-load)
      CONDITIONAL_LOAD=true
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
    -p|--print)
      PRINT=true
      shift # past argument
      ;;
    -x|--docker-image-exclusion-list)
      DOCKER_IMAGE_EXCLUSION_LIST="$2"
      shift # past argument
      ;;
    -i|--docker-image-inclusion-list)
      DOCKER_IMAGE_INCLUSION_LIST="$2"
      shift # past argument
      ;;
    -h|--help)
      help
      exit 0
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



find_docker_base_images(){

    #search_path is a directory containing Dockerfiles 
    local search_path="${1}"
    local docker_image_exclusion_list="${2}"
    local docker_image_inclusion_list="${3}"
    local docker_images=""

    docker_image_exclusion_list="$(echo "${docker_image_exclusion_list}" | tr ' ' '\n' | sort)"
    docker_image_inclusion_list="$(echo "${docker_image_inclusion_list}" | tr ' ' '\n' | sort)"

    echodebug "  FROM find_docker_base_images:" 

    if [[ ! -z "${search_path}" ]]; then
        search_path="$(realpath "${search_path}" 2> /dev/null || echo "${search_path}")" 
    fi
   
    if [ -z "${search_path+x}" -a ! -d "${search_path}" ]; then
        echoerr "ERROR: The provided docker image search path: ${search_path} does not exist."
    fi

    echodebug "    search_path: ${search_path}" 
    if [[ -z "${search_path}" ]]; then
        docker_images="$(docker image list --format "{{.Repository}}:{{.Tag}}")"
    else
        docker_files=$(cd "${search_path}" && find . -type f -name Dockerfile* | uniq | sort)
        cd "${search_path}"
        for docker_file in ${docker_files}; do
            echodebug "        docker_file: ${docker_file}"
            docker_image="$(grep -i "FROM " "${docker_file}" | head -1 | cut -d" " -f2)"
            docker_images+="\n${docker_image}"
        done
    fi
    
    docker_images="$(echo -e "${docker_images}\n${docker_image_inclusion_list}" | sed '/^$/d' | grep ":" | grep -v -e '<none>:<none>\|\$' | sort | uniq)"
    #docker_images="$(printf "%s" "${docker_images}" | sed '/^$/d' | sort | uniq)"
    echodebug "    docker_images: ${docker_images}"
    echodebug "    docker_images count: $(echo "${docker_images}" | wc -L)"
    docker_images="$(comm -23 <(echo "${docker_images}" | sort) <(echo "${docker_image_exclusion_list}" | sort))"
    echo "${docker_images}"
}

fetch_docker_images(){

    local docker_images="${1}"

    echodebug "  FROM find_docker_base_images:" 
    
    for docker_image in $docker_images; do
        echo "    fetching docker image: ${docker_image}"
        { # try
            docker pull "${docker_image}" 2>/dev/null
        } || { # catch
            local error_message="    ERROR: Unable to pull docker image: ${docker_image} from Docker central registry, try "
            error_message+="adding it to the exclusion list. \n" 
            error_message+="      Example: 'bash docker-image-cacher.sh ... -x \"${docker_image}\" ...' \n\n"
            echoerr "${error_message}"
        }
    done
}

save_docker_images(){

    local docker_image_cache_directory="${1}"
    local docker_images="${2}"
 
    echodebug "  FROM save_docker_images:"

    if [[ -z "${docker_image_cache_directory}" ]]; then
        echoerr "ERROR: The docker image cache directory is not set."
    fi

    docker_image_cache_directory="$(realpath "${docker_image_cache_directory}")" 
    mkdir -p "${docker_image_cache_directory}"
    
    cd "${docker_image_cache_directory}"

     if [[ -z "${docker_images}" ]]; then
         echoerr "ERROR: The docker image list is empty, there is nothing to save. Provide a search path with -d or inclusion list with -i\n"
     fi
    for docker_image in $docker_images; do
        docker_image_archive="${docker_image_cache_directory}/$(echo "${docker_image//:/_}" | sed "s|/|_|g").tar"
        echo "    saving docker image: ${docker_image} to ${docker_image_archive}"
        { # try
            docker save --output "${docker_image_archive}" "${docker_image}"
        } || { # catch
            local error_message="    ERROR: Unable to save docker image: ${docker_image} "
            error_message+="it must exist in the local registry to save it.\n" 
            error_message+="      Try 'docker pull ${docker_image}' and run this tool again. "
            error_message+="You can also run this tool with the 'fetch' operation to pull this docker image. \n\n"
            echoerr "${error_message}"
        }
        #docker save --output "${docker_image_archive}" "${docker_image}" 2>/dev/null || true
    done
}

load_docker_images(){

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

if [ "${FETCH}" == true -o "${PRINT}" == true -o "${SAVE}" == true ]; then
    docker_images="$(find_docker_base_images "${DOCKER_IMAGE_SEARCH_PATH}" "${DOCKER_IMAGE_EXCLUSION_LIST}" "${DOCKER_IMAGE_INCLUSION_LIST}")"
fi

if [ "${PRINT}" == true ]; then
    printf "%s \n" "${docker_images}" | tr " " "\n"
    exit 0
fi

if [[ "${FETCH}" == true ]]; then
    fetch_docker_images "${docker_images}" 
fi

if [[ "${SAVE}" == true ]]; then
    save_docker_images "${DOCKER_IMAGE_CACHE_DIRECTORY}" "${docker_images}"
fi

if [[ "${LOAD}" == true ]]; then
    load_docker_images "${DOCKER_IMAGE_CACHE_DIRECTORY}"
fi

docker_image_count="$(docker image ls | grep -v "REPOSITORY" | wc -l)" || true

if [ "${docker_image_count}" == "0" -a "${CONDITIONAL_LOAD}" == true ]; then
    printf "Loading docker images from docker image cache: %s\n" "${DOCKER_IMAGE_CACHE_DIRECTORY}"
    load_docker_images "${DOCKER_IMAGE_CACHE_DIRECTORY}"
elif [ "${CONDITIONAL_LOAD}" == true ]; then
    printf "Conditional load enabled and docker contains %s images, skipping load\n" "${docker_image_count}"
fi

if [ "${FETCH}" == false -a "${SAVE}" == false -a "${LOAD}" == false -a "${CONDITIONAL_LOAD}" == false -a "${PRINT}" == false ]; then
    help
    echoerr "ERROR: Invalid or no arguments. You must provide an operation: save (-s, --save), load (-l, --load), fetch (-f, --fetch), or print (-p, --print). \n"
fi

