


.PHONY:docker_orbital_cannon
docker_orbital_cannon: ## Deletes ALL docker images and containers.
	@echo -n "This is very destructive and will result in PERMANENT data loss, are you sure you want to proceed? [y/N] " && read ans && [ $${ans:-N} = y ];
	docker stop $$(docker ps -aq) || true
	docker rm --force $$(docker ps -aq) || true
	docker rmi --force $$(docker images -q) || true
	docker volume rm $$(docker volume ls -q) || true
	docker builder prune --all --force
	docker system prune --all --volumes --force

.PHONY:remove_dangling_images
remove_dangling_images:
	docker rmi --force $$(docker images -f 'dangling=true' -q)
