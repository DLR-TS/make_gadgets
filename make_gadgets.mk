
#ifndef MAKE_GADGETS_MAKEFILE_PATH

#$(warning "make_gadgets.mk loaded")

.EXPORT_ALL_VARIABLES:
MAKE_GADGETS_MAKEFILE_PATH:=$(shell realpath "$(shell dirname "$(lastword $(MAKEFILE_LIST))")")
REPO_DIRECTORY?="${MAKE_GADGETS_MAKEFILE_PATH}"

.PHONY: help  
help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: root_check
root_check: # Check if target was run as root
	@[ "$$EUID" -ne 0 ] || (echo "  ERROR: Do not run as root!"; 1>&2 && exit 1)

.PHONY: get_sanitized_branch_name
get_sanitized_branch_name: ## Returns a sanitized git branch name with only alphanumeric and ASCII characters permitted as docker tags
	@cd "${MAKE_GADGETS_MAKEFILE_PATH}/tools" && bash "branch_name.sh" --repo-directory "${REPO_DIRECTORY}"

.PHONY: dump
dump: # Print all defined make variables
	$(foreach v, \
        $(shell echo "$(filter-out .VARIABLES,$(.VARIABLES))" | tr ' ' '\n' | sort), \
        $(info $(shell printf "%-20s" "$(v)")= $(value $(v))) \
    )

#endif
