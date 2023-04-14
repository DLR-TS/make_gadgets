
ifeq ($(filter make_gadgets.mk, $(notdir $(MAKEFILE_LIST))), make_gadgets.mk)

.EXPORT_ALL_VARIABLES:
MAKEFLAGS += --no-print-directory
MAKE_GADGETS_MAKEFILE_PATH:=$(shell realpath "$(shell dirname "$(lastword $(MAKEFILE_LIST))")")
REPO_DIRECTORY?="${MAKE_GADGETS_MAKEFILE_PATH}"

.PHONY: help  
help:
	@bash ${MAKE_GADGETS_MAKEFILE_PATH}/tools/make_help.sh --makefiles "${MAKEFILE_LIST}"

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

endif
