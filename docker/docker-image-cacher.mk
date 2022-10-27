

ifndef docker-image-cacher.mk_MAKEFILE_PATH


docker-image-cacher.mk_MAKEFILE_PATH:= $(shell dirname "$(abspath "$(lastword $(MAKEFILE_LIST))")")

include ${docker-image-cacher.mk_MAKEFILE_PATH}/docker-tools.mk

DOCKER_IMAGE_EXCLUSION_LIST?=""
DOCKER_IMAGE_INCLUSION_LIST?=""

#DEBUG=true
.EXPORT_ALL_VARIABLES:
DOCKER_IMAGE_SEARCH_PATH?="${HOME}"
DOCKER_IMAGE_CACHE_DIRECTORY?="${docker-image-cacher.mk_MAKEFILE_PATH}/.docker_image_cache"


.PHONY: docker_fetch
docker_fetch: docker_group_check## Fetches from docker.io all docker images provided by DOCKER_IMAGE_SEARCH_PATH or 'docker image ls' to a local cache.
	cd "${docker-image-cacher.mk_MAKEFILE_PATH}" && \
    bash docker-image-cacher.sh --docker-image-search-path "${DOCKER_IMAGE_SEARCH_PATH}" \
                                --docker-image-exclusion-list ${DOCKER_IMAGE_EXCLUSION_LIST} \
                                --docker-image-inclusion-list ${DOCKER_IMAGE_INCLUSION_LIST} \
                                --fetch

.PHONY: docker_save
docker_save: docker_group_check ## Saves all docker images provided by DOCKER_IMAGE_SEARCH_PATH or 'docker image ls' to a local cache.
	cd "${docker-image-cacher.mk_MAKEFILE_PATH}" && \
    bash docker-image-cacher.sh --docker-image-search-path ${DOCKER_IMAGE_SEARCH_PATH} \
                                --docker-image-cache-directory ${DOCKER_IMAGE_CACHE_DIRECTORY} \
                                --docker-image-exclusion-list ${DOCKER_IMAGE_EXCLUSION_LIST} \
                                --docker-image-inclusion-list ${DOCKER_IMAGE_INCLUSION_LIST} \
                                --save

.PHONY: docker_save_local_registry_only
docker_save_local_registry_only: docker_group_check ## Saves all docker images in the local registry via 'docker image ls' to a local cache.
	cd "${docker-image-cacher.mk_MAKEFILE_PATH}" && \
    bash docker-image-cacher.sh \
                                --docker-image-cache-directory ${DOCKER_IMAGE_CACHE_DIRECTORY} \
                                --docker-image-exclusion-list ${DOCKER_IMAGE_EXCLUSION_LIST} \
                                --docker-image-inclusion-list ${DOCKER_IMAGE_INCLUSION_LIST} \
                                --save


.PHONY: docker_print
docker_print: ## Prints all docker images that will be saved/cached/fetched with 'make docker_save' or 'make docker_fetch'
	cd "${docker-image-cacher.mk_MAKEFILE_PATH}" && \
    bash docker-image-cacher.sh --docker-image-search-path ${DOCKER_IMAGE_SEARCH_PATH} \
                                --docker-image-exclusion-list ${DOCKER_IMAGE_EXCLUSION_LIST} \
                                --docker-image-inclusion-list ${DOCKER_IMAGE_INCLUSION_LIST} \
                                --print

.PHONY: docker_load
docker_load: docker_group_check ## Loads docker image archives, in the docker image cache, into docker
	cd "${docker-image-cacher.mk_MAKEFILE_PATH}" && \
    bash docker-image-cacher.sh --docker-image-cache-directory ${DOCKER_IMAGE_CACHE_DIRECTORY} \
                                --load

docker_conditional_load: docker_group_check ## Loads docker image archives, in the docker image cache only if it is empty
	cd "${docker-image-cacher.mk_MAKEFILE_PATH}" && \
    bash docker-image-cacher.sh --docker-image-cache-directory "${DOCKER_IMAGE_CACHE_DIRECTORY}" \
                                --conditional-load

.PHONY: docker_clean_image_cache
docker_clean_image_cache: ## Delete/clear local docker image cache
	rm -rf "${DOCKER_IMAGE_CACHE_DIRECTORY}"

.PHONY: docker_get_image_cache_size
docker_get_image_cache_size: ## Returns the docker image cache size on disk
	@du -h "$(shell realpath "${DOCKER_IMAGE_CACHE_DIRECTORY}")" 2>/dev/null || echo 0

endif
