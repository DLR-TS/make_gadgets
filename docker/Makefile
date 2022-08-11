


.PHONY:docker_orbital_cannon
docker_orbital_cannon: ## Deletes ALL docker images and containers.
	@echo -n "This is very destructive and will result in PERMANENT data loss, are you sure you want to proceed? [y/N] " && read ans && [ $${ans:-N} = y ];
	docker stop $$(docker ps -aq) || true
	docker builder prune --all --force
	docker system prune --all --volumes --force
	docker rm --force $$(docker ps -aq) || true
	docker rmi --force $$(docker images -q) || true
	docker volume rm $$(docker volume ls -q) || true

.PHONY: clean_docker
clean_docker: delete_dangling_images delete_all_build_cache

.PHONY:delete_all_none_tags
delete_all_none_tags:
	docker rmi $$(docker images -f "dangling=true" -q) --force

.PHONY:delete_dangling_images
delete_dangling_images:
	docker rmi --force $$(docker images -f 'dangling=true' -q) 2> /dev/null || true
	docker image prune --force --filter="dangling=true" 2> /dev/null || true

.PHONY: delete_all_build_cache
	docker builder prune --force --all
