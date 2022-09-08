ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

.PHONY: help  
help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: root_check
root_check:# Check if target was run as root
	@[ "$$EUID" -ne 0 ] || (echo "  ERROR: Do not run as root!"; 1>&2 && exit 1)

.PHONY: docker_group_check
docker_group_check:# Checks if the current user is a member of the 'docker' group. 
	@[ -n "$$(id -Gn | grep 'docker')" ] || ( \
         echo "  ERROR: User: '$$USER' is not a member of the 'docker' group."; 1>&2 \
         echo "    Run 'sudo usermod -a -G docker \$$USER' to add the current user to the docker group and try again."; 1>&2 \
         echo "    You may need to log out and log back in for changes to take effect." 1>&2 && exit 1 \
    )
