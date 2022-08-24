


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
