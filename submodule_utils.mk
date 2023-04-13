
ifeq ($(filter submodule_utils.mk, $(notdir $(MAKEFILE_LIST))), submodule_utils.mk)

##define include_submodule
## ifeq (,$(strip $(1) $(2)))
##    $(if $(and $(1),$(2),$(wildcard $(1)/$(2)/$(2).mk)), \
##        $(eval include $(1)/$(2)/$(2).mk), \
##        $(error ERROR: submodule: $(2) not populated. File: $(1)/$(2)/$(2).mk does not exist. Did you clone it?)
##    )
## endef
define include_submodule
    $(if $(strip $(1))$(strip $(2)), \
        $(if $(wildcard $(1)/$(2)/$(2).mk), \
            $(eval include $(1)/$(2)/$(2).mk), \
            $(error ERROR: submodule $(2) not populated. File: $(1)/$(2)/$(2).mk does not exist. Did you clone it?) \
        ) \
    )
endef


define include_submodules
    $(foreach submodule,$(2),$(call include_submodule,$(1),$(submodule)))
endef

endif
