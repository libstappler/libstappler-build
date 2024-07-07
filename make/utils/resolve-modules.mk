# Copyright (c) 2023-2024 Stappler LLC <admin@stappler.dev>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

LOCAL_MODULES_PATHS ?= $(GLOBAL_ROOT)/modules.mk

define include_module_path =
include $(1)
endef

LOCAL_MODULES_PATHS += $(BUILD_ROOT)/../module/module.mk
LOCAL_MODULES += stappler_build_debug_module

$(foreach include,$(LOCAL_MODULES_PATHS),$(eval $(call include_module_path,$(include))))

define emplace_module =
$(eval LOCAL_MODULES = $(LOCAL_MODULES) $(1))
$(eval $(call follow_deps_module,$(MODULE_$(1))))
endef

define follow_deps_module =
$(foreach dep,$($(1)_DEPENDS_ON),\
	$(eval $(call emplace_module,$(dep))) \
)
endef

define merge_module =
TOOLKIT_PRECOMPILED_HEADERS += $($(1)_PRECOMPILED_HEADERS)
TOOLKIT_GENERAL_CFLAGS += $($(1)_FLAGS) $($(1)_GENERAL_CFLAGS) -D$(1)
TOOLKIT_GENERAL_CXXFLAGS += $($(1)_FLAGS) $($(1)_GENERAL_CXXFLAGS) -D$(1)
TOOLKIT_GENERAL_LDFLAGS += $($(1)_GENERAL_LDFLAGS)
TOOLKIT_LIB_CFLAGS += $($(1)_LIB_CFLAGS)
TOOLKIT_LIB_CXXFLAGS += $($(1)_LIB_CXXFLAGS)
TOOLKIT_LIB_LDFLAGS += $($(1)_LIB_LDFLAGS)
TOOLKIT_EXEC_CFLAGS += $($(1)_EXEC_CFLAGS)
TOOLKIT_EXEC_CXXFLAGS += $($(1)_EXEC_CXXFLAGS)
TOOLKIT_EXEC_LDFLAGS += $($(1)_EXEC_LDFLAGS)
TOOLKIT_LIBS += $($(1)_LIBS)
TOOLKIT_SRCS_DIRS += $($(1)_SRCS_DIRS)
TOOLKIT_SRCS_OBJS += $($(1)_SRCS_OBJS)
TOOLKIT_INCLUDES_DIRS += $($(1)_INCLUDES_DIRS)
TOOLKIT_INCLUDES_OBJS += $($(1)_INCLUDES_OBJS)
TOOLKIT_SHADERS_DIR += $($(1)_SHADERS_DIR)
TOOLKIT_SHADERS_INCLUDE += $($(1)_SHADERS_INCLUDE)
TOOLKIT_SRCS_DIRS_WITH_SHADERS += $(if $($(1)_SHADERS_DIR),$($(1)_SRCS_DIRS))
TOOLKIT_SRCS_OBJS_WITH_SHADERS += $(if $($(1)_SHADERS_DIR),$($(1)_SRCS_OBJS))
TOOLKIT_WASM_DIRS += $($(1)_WASM_DIRS)
TOOLKIT_WASM_OBJS += $($(1)_WASM_OBJS)
endef

reverse_modules = $(if $(wordlist 2,2,$(1)),$(call reverse_modules,$(wordlist 2,$(words $(1)),$(1))) $(firstword $(1)),$(1))
unique_modules = $(if $1,$(firstword $1) $(call unique_modules,$(filter-out $(firstword $1),$1)))

$(foreach module,$(LOCAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$(eval $(call follow_deps_module,$(module_name)))))

GLOBAL_MODULES := $(call reverse_modules,$(call unique_modules,$(call reverse_modules,$(LOCAL_MODULES))))

$(foreach module,$(GLOBAL_MODULES),$(if $(MODULE_$(module)),,$(error Module not found: $(module))))

$(info Enabled modules: $(GLOBAL_MODULES))

$(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$(eval $(call merge_module,$(module_name),$(module)))))

	
TOOLKIT_MODULES := $(BUILD_С_OUTDIR)/modules.info
TOOLKIT_CACHED_MODULES := $(shell cat $(TOOLKIT_MODULES) 2> /dev/null)

ifneq ($(LOCAL_MODULES),$(TOOLKIT_CACHED_MODULES))
$(info Modules was updated)
$(shell $(GLOBAL_MKDIR) $(BUILD_С_OUTDIR); echo '$(LOCAL_MODULES)' > $(TOOLKIT_MODULES))
endif
	