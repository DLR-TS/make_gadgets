ROOT_DIR=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")

MAKEFILE_PATH:=$(shell dirname "$(abspath "$(lastword $(MAKEFILE_LIST)"))")


.EXPORT_ALL_VARIABLES:
REPO_DIRECTORY?="${ROOT_DIR}"


.PHONY: help  
help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: root_check
root_check:# Check if target was run as root
	@[ "$$EUID" -ne 0 ] || (echo "  ERROR: Do not run as root!"; 1>&2 && exit 1)

.PHONY: get_sanitized_branch_name
get_sanitized_branch_name: ## Returns a sanitized git branch name with only alphanumeric ASCII characters. Set the 'REPO_DIRECTORY' env var before calling such as follows: 'make get_sanitized_branch_name REPO_DIRECTORY="<path to git repo>"'. 
	@cd "${MAKEFILE_PATH}/tools" && bash "branch_name.sh" --repo-directory "${REPO_DIRECTORY}"


