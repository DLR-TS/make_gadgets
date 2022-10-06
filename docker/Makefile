
ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")
MAKEFILE_DIR := $(shell dirname "$(abspath "$(lastword $(MAKEFILE_LIST))")")

.EXPORT_ALL_VARIABLES:
DOCKER_IMAGE_SEARCH_PATH?="${HOME}"
DOCKER_IMAGE_CACHE_DIRECTORY?="${MAKEFILE_DIR}/.docker_image_cache"
DOCKER_IMAGE_EXCLUSION_LIST?=""
#DEBUG=true

.PHONY:docker_orbital_cannon
docker_orbital_cannon: ## Deletes ALL docker images, volumes, build cache and containers.
	@echo -n "This is very destructive and will result in PERMANENT data loss, are you sure you want to proceed? [y/N] " && read ans && [ $${ans:-N} = y ];
	docker stop $$(docker ps -aq) || true
	docker rm --force $$(docker ps -aq) || true
	docker rmi --force $$(docker images -q) || true
	docker volume rm $$(docker volume ls -q) || true
	docker builder prune --all --force || true
	docker system prune --all --volumes --force || true

.PHONY: clean_docker
clean_docker: delete_dangling_images delete_all_build_cache ## Clean/delete all docker dangling images and build cache

.PHONY:delete_all_none_tags
delete_all_none_tags: ## Delete all docker orphaned/none tags
	docker rmi $$(docker images -f "dangling=true" -q) --force 2> /dev/null || true

.PHONY:delete_dangling_images
delete_dangling_images: ## Delete all dangling images/tags
	docker rmi --force $$(docker images -f 'dangling=true' -q) 2> /dev/null || true
	docker image prune --force --filter="dangling=true" 2> /dev/null || true

.PHONY: delete_all_build_cache
delete_all_build_cache: ## Delete all docker builder cache
	docker builder prune --force --all

.PHONY: system_prune
system_prune: ## Prune the docker system
	docker system prune --all --volumes --force

.PHONY: docker_group_check
docker_group_check:# Checks if the current user is a member of the 'docker' group. 
	@[ -n "$$(id -Gn | grep 'docker')" ] || ( \
         echo "  ERROR: User: '$$USER' is not a member of the 'docker' group."; 1>&2 \
         echo "    Run 'sudo usermod -a -G docker \$$USER' to add the current user to the docker group and try again."; 1>&2 \
         echo "    You may need to log out and log back in for changes to take effect." 1>&2 && exit 1 \
    )

.PHONY: docker_fetch
docker_fetch: docker_group_check## Fetches from docker.io all docker images provided by DOCKER_IMAGE_SEARCH_PATH or docker image ls to a local cache
	cd "${MAKEFILE_DIR}" && \
    bash docker_image_cacher.sh --docker-image-search-path "${DOCKER_IMAGE_SEARCH_PATH}" \
                                --docker-image-exclusion-list "${DOCKER_IMAGE_EXCLUSION_LIST}" \
	                            --fetch

.PHONY: docker_save
docker_save: docker_group_check ## Saves all docker images provided by DOCKER_IMAGE_SEARCH_PATH or docker image ls to a local cache
	cd "${MAKEFILE_DIR}" && \
    bash docker_image_cacher.sh --docker-image-search-path "${DOCKER_IMAGE_SEARCH_PATH}" \
                                --docker-image-cache-directory "${DOCKER_IMAGE_CACHE_DIRECTORY}" \
                                --docker-image-exclusion-list "${DOCKER_IMAGE_EXCLUSION_LIST}" \
		                        --save

.PHONY: docker_load
docker_load: docker_group_check ## Loads docker image archives, in the docker image cache, into docker
	cd "${MAKEFILE_DIR}" && \
    bash docker_image_cacher.sh --docker-image-cache-directory "${DOCKER_IMAGE_CACHE_DIRECTORY}" \
                                --load

docker_conditional_load: docker_group_check ## Loads docker image archives, in the docker image cache only if it is empty
	cd "${MAKEFILE_DIR}" && \
    bash docker_image_cacher.sh --docker-image-cache-directory "${DOCKER_IMAGE_CACHE_DIRECTORY}" \
                                --conditional-load

.PHONY: clean_docker_image_cache
clean_docker_image_cache: ## Delete/clear local docker image cache
	rm -rf "${DOCKER_IMAGE_CACHE_DIRECTORY}"

.PHONY: get_docker_image_cache_size
get_docker_image_cache_size: ## Returns the docker image cache size on disk
	@du -h "$(shell realpath "${DOCKER_IMAGE_CACHE_DIRECTORY}")" 2>/dev/null || echo 0
