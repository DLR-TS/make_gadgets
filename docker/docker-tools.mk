
# To consume this module use:
# include make_gadgets/docker/docker-tools

ifndef DOCKER-TOOLS_MAKEFILE_PATH

DOCKER_IMAGE_EXCLUSION_LIST?=""
DOCKER_IMAGE_INCLUSION_LIST?=""

#DEBUG=true
.EXPORT_ALL_VARIABLES:
DOCKER-TOOLS_MAKEFILE_PATH:=$(shell realpath "$(shell dirname "$(lastword $(MAKEFILE_LIST))")")
DOCKER_GID := $(shell getent group | grep docker | cut -d":" -f3)

.PHONY:docker_orbital_cannon
docker_orbital_cannon: ## Deletes ALL docker images, volumes, build cache and containers.
	@echo -n "This is very destructive and will result in PERMANENT data loss, are you sure you want to proceed? [y/N] " && read ans && [ $${ans:-N} = y ];
	docker stop $$(docker ps -aq) || true
	docker rm --force $$(docker ps -aq) || true
	docker rmi --force $$(docker images -q) || true
	docker volume rm $$(docker volume ls -q) || true
	docker builder prune --all --force || true
	docker system prune --all --volumes --force || true

.PHONY: docker_clean
docker_clean: docker_delete_dangling_images docker_delete_all_build_cache ## Clean/delete all docker dangling images and build cache

.PHONY: docker_delete_all_continers
docker_delete_all_containers: ## Stop and delete all docker containers
	docker stop $$(docker ps -aq) || true
	docker rm --force $$(docker ps -aq) || true

.PHONY: docker_delete_all_none_tags
docker_delete_all_none_tags: ## Delete all docker orphaned/none tags
	docker rmi $$(docker images -f "dangling=true" -q) --force 2> /dev/null || true

.PHONY:docker_delete_dangling_images
docker_delete_dangling_images: ## Delete all dangling images/tags
	docker rmi --force $$(docker images -f 'dangling=true' -q) 2> /dev/null || true
	docker image prune --force --filter="dangling=true" 2> /dev/null || true

.PHONY: docker_delete_all_build_cache
docker_delete_all_build_cache: ## Delete all docker builder cache
	docker builder prune --force --all

.PHONY: docker_system_prune
docker_system_prune: ## Prune the docker system
	docker system prune --all --volumes --force

.PHONY: docker_group_check
docker_group_check:# Checks if the current user is a member of the 'docker' group. 
	@[ -n "$$(id -Gn | grep 'docker')" ] || ( \
         echo "  ERROR: User: '$$USER' is not a member of the 'docker' group."; 1>&2 \
         echo "    Run 'sudo usermod -a -G docker \$$USER' to add the current user to the docker group and try again."; 1>&2 \
         echo "    You may need to log out and log back in for changes to take effect." 1>&2 && exit 1 \
    )

.PHONY: docker_context_check
docker_context_check:# Checks if the current context is inside docker, throws an error if it is not 
	@[ -f "/.dockerenv" ] || ( \
         echo "  ERROR: Target/recipe must be run inside a docker context."; 1>&2 && exit 1 \
    )

.PHONY: docker_host_context_check
docker_host_context_check:# Checks if the current context is inside docker, throws an error if it is not 
	@[ ! -f "/.dockerenv" ] || ( \
         echo "  ERROR: Target/recipe must be run naively on host and not inside a docker context."; 1>&2 && exit 1 \
    )
endif
