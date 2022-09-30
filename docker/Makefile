
ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

.EXPORT_ALL_VARIABLES:
DOCKER_IMAGE_SEARCH_PATH?="${HOME}"
DOCKER_IMAGE_SEARCH_PATH?="../../"
DOCKER_IMAGE_CACHE_DIRECTORY?=".docker_image_cache"
DEBUG=true

.PHONY:docker_orbital_cannon
docker_orbital_cannon: ## Deletes ALL docker images, volumes, build cache and containers.
	@echo -n "This is very destructive and will result in PERMANENT data loss, are you sure you want to proceed? [y/N] " && read ans && [ $${ans:-N} = y ];
	docker stop $$(docker ps -aq) || true
	docker builder prune --all --force
	docker system prune --all --volumes --force
	docker rm --force $$(docker ps -aq) || true
	docker rmi --force $$(docker images -q) || true
	docker volume rm $$(docker volume ls -q) || true

.PHONY: clean_docker ## Clean/delete add docker dangling images and build cache
clean_docker: delete_dangling_images delete_all_build_cache

.PHONY:delete_all_none_tags ## Delete all orphaned/none tags
delete_all_none_tags:
	docker rmi $$(docker images -f "dangling=true" -q) --force 2> /dev/null || true

.PHONY:delete_dangling_images
delete_dangling_images: ## Delete all dangling images/tags
	docker rmi --force $$(docker images -f 'dangling=true' -q) 2> /dev/null || true
	docker image prune --force --filter="dangling=true" 2> /dev/null || true

.PHONY: delete_all_build_cache
delete_all_build_cache:
	docker builder prune --force --all

.PHONY: system_prune
system_prune: ## Prune docker system
	docker system prune --all --volumes --force

.PHONY: docker_group_check
docker_group_check:# Checks if the current user is a member of the 'docker' group. 
	@[ -n "$$(id -Gn | grep 'docker')" ] || ( \
         echo "  ERROR: User: '$$USER' is not a member of the 'docker' group."; 1>&2 \
         echo "    Run 'sudo usermod -a -G docker \$$USER' to add the current user to the docker group and try again."; 1>&2 \
         echo "    You may need to log out and log back in for changes to take effect." 1>&2 && exit 1 \
    )

.PHONY: docker_save
docker_save: docker_group_check
	bash "${ROOT_DIR}/tools/docker_save.sh" --search-path "${DOCKER_IMAGE_SEARCH_PATH}" --docker-image-cache-directory "${DOCKER_IMAGE_CACHE_DIRECTORY}"

.PHONY: docker_load
docker_load: docker_group_check
	bash "${ROOT_DIR}/tools/docker_save.sh" --search-path "${DOCKER_IMAGE_SEARCH_PATH}" --docker-image-cache-directory "${DOCKER_IMAGE_CACHE_DIRECTORY}"

.PHONY: clean_docker_cache
clean_docker_cache:
	rm -rf "${DOCKER_IMAGE_CACHE_DIRECTORY}"
