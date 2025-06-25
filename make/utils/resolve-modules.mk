# Copyright (c) 2023-2025 Stappler LLC <admin@stappler.dev>
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

# to use without Stappler SDK, just watch for root module list
LOCAL_MODULES_PATHS ?= $(GLOBAL_ROOT)/modules.mk

define include_module_source =
TOOLKIT_MODULE_PATH := $(1)
include $(1)
endef

define include_module_optional =
$(info Optional module "$(1)": $(if $(MODULE_$(1)),<found>,<not found>))
LOCAL_MODULES += $(if $(MODULE_$(1)),$(1))
endef

# inject debug module
ifndef SHARED_PREFIX
LOCAL_MODULES_PATHS += $(realpath $(BUILD_ROOT)/../module/module.mk)
endif # SHARED_PREFIX

LOCAL_MODULES += stappler_build_debug_module

ifeq ($(LINUX),1)
# Special threatment for Alpine, replace execinfo.h with full libbacktrace
LOCAL_MODULES +=  $(if $(strip $(shell cat /etc/os-release | grep "Alpine Linux")),stappler_backtrace)
endif

TOOLKIT_MODULE_LIST :=

ifdef SHARED_PREFIX
TOOLKIT_MODULE_LIST += $(wildcard $(BUILD_ROOT)/modules/*.mk)
$(foreach include,$(filter /%,$(LOCAL_MODULES_PATHS)),$(eval $(call include_module_path,$(include))))
else
include $(filter /%,$(LOCAL_MODULES_PATHS)) $(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(LOCAL_MODULES_PATHS)))
endif

ifdef MAKE_4_1
$(foreach include,$(TOOLKIT_MODULE_LIST),$(eval $(call include_module_source,$(include))))
else
include $(TOOLKIT_MODULE_LIST)
endif # MAKE_4_1

$(foreach module,$(LOCAL_MODULES_OPTIONAL),$(eval $(call include_module_optional,$(module))))

define emplace_module =
$(eval LOCAL_MODULES = $(LOCAL_MODULES) $(1))
$(eval $(call follow_deps_module,$(MODULE_$(1))))
endef

define follow_deps_module =
$(foreach dep,$(filter-out $(LOCAL_MODULES),$($(1)_DEPENDS_ON)),\
	$(eval $(call emplace_module,$(dep))) \
)
endef # follow_deps_module

define define_consumed =
$(2)_CONSUMED_BY := $(1)
endef # define_consumed

define merge_module =
TOOLKIT_CONFIG_FLAGS += $(1) $($(1)_CONFIG_FLAGS)
TOOLKIT_CONFIG_VALUES += $($(1)_CONFIG_VALUES)
TOOLKIT_CONFIG_STRINGS += $($(1)_CONFIG_STRINGS) $(1)_NAME=$(2)
TOOLKIT_PRECOMPILED_HEADERS += $($(1)_PRECOMPILED_HEADERS)
TOOLKIT_GENERAL_CFLAGS += $($(1)_FLAGS) $($(1)_GENERAL_CFLAGS)
TOOLKIT_GENERAL_CXXFLAGS += $($(1)_FLAGS) $($(1)_GENERAL_CXXFLAGS)
TOOLKIT_GENERAL_LDFLAGS += $($(1)_GENERAL_LDFLAGS)
TOOLKIT_LIB_CFLAGS += $($(1)_LIB_CFLAGS)
TOOLKIT_LIB_CXXFLAGS += $($(1)_LIB_CXXFLAGS)
TOOLKIT_LIB_LDFLAGS += $($(1)_LIB_LDFLAGS)
TOOLKIT_EXEC_CFLAGS += $($(1)_EXEC_CFLAGS)
TOOLKIT_EXEC_CXXFLAGS += $($(1)_EXEC_CXXFLAGS)
TOOLKIT_EXEC_LDFLAGS += $($(1)_EXEC_LDFLAGS)
TOOLKIT_LIBS += $($(1)_LIBS)
TOOLKIT_LIBS_SHARED += $($(1)_LIBS_SHARED)
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
TOOLKIT_SHARED_CONSUME += $($(1)_SHARED_CONSUME)
TOOLKIT_GENERAL_CFLAGS += $(if $(BUILD_SHARED_PKGCONFIG),$(foreach name,$($(1)_SHARED_PKGCONFIG),$(shell pkg-config --cflags-only-I $(name))))
TOOLKIT_GENERAL_CXXFLAGS += $(if $(BUILD_SHARED_PKGCONFIG),$(foreach name,$($(1)_SHARED_PKGCONFIG),$(shell pkg-config --cflags-only-I $(name))))
$(foreach module,$($(1)_SHARED_CONSUME),$(eval $(call define_consumed,$(2),$(MODULE_$(module)))))
endef # merge_module

reverse_modules = $(if $(wordlist 2,2,$(1)),$(call reverse_modules,$(wordlist 2,$(words $(1)),$(1))) $(firstword $(1)),$(1))
unique_modules = $(if $1,$(firstword $1) $(call unique_modules,$(filter-out $(firstword $1),$1)))


ifdef MAKE_4_1
$(foreach module,$(LOCAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$(eval $(call follow_deps_module,$(module_name)))))
else
# WARNING: no infinite recursion control!
read_dependencies = $(filter-out $(LOCAL_MODULES),\
	$(foreach module,$(1),$(foreach module_name,$(MODULE_$(module)),$($(module_name)_DEPENDS_ON))) \
)

read_dependencies_recursive = $(call read_dependencies,$(1)) \
	$(if $(call read_dependencies,$(1)),$(call read_dependencies_recursive,$(call read_dependencies,$(1))))

LOCAL_MODULES := $(LOCAL_MODULES) $(call read_dependencies_recursive,$(LOCAL_MODULES))
endif # MAKE_4_1


GLOBAL_MODULES := $(call reverse_modules,$(call unique_modules,$(call reverse_modules,$(LOCAL_MODULES))))

$(foreach module,$(GLOBAL_MODULES),$(if $(MODULE_$(module)),,$(error Module not found: $(module))))

$(info Enabled modules: $(GLOBAL_MODULES))

ifdef MAKE_4_1
$(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$(eval $(call merge_module,$(module_name),$(module)))))
else
# Fallback for macOS
TOOLKIT_CONFIG_FLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_CONFIG_FLAGS) $(module_name)))
TOOLKIT_CONFIG_VALUES := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_CONFIG_VALUES)))
TOOLKIT_CONFIG_STRINGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_CONFIG_STRINGS) $(module_name)_NAME=$(module)))
TOOLKIT_PRECOMPILED_HEADERS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_PRECOMPILED_HEADERS)))
TOOLKIT_GENERAL_CFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_FLAGS) $($(module_name)_GENERAL_CFLAGS)))
TOOLKIT_GENERAL_CXXFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_FLAGS) $($(module_name)_GENERAL_CXXFLAGS)))
TOOLKIT_GENERAL_LDFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_GENERAL_LDFLAGS)))
TOOLKIT_LIB_CFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_LIB_CFLAGS)))
TOOLKIT_LIB_CXXFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_LIB_CXXFLAGS)))
TOOLKIT_LIB_LDFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_LIB_LDFLAGS)))
TOOLKIT_EXEC_CFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_EXEC_CFLAGS)))
TOOLKIT_EXEC_CXXFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_EXEC_CXXFLAGS)))
TOOLKIT_EXEC_LDFLAGS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_EXEC_LDFLAGS)))
TOOLKIT_SRCS_DIRS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_SRCS_DIRS)))
TOOLKIT_SRCS_OBJS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_SRCS_OBJS)))
TOOLKIT_INCLUDES_DIRS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_INCLUDES_DIRS)))
TOOLKIT_INCLUDES_OBJS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_INCLUDES_OBJS)))
TOOLKIT_SHADERS_DIR := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_SHADERS_DIR)))
TOOLKIT_SHADERS_INCLUDE := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_SHADERS_INCLUDE)))
TOOLKIT_LIBS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_LIBS)))
TOOLKIT_LIBS_SHARED := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$($(module_name)_LIBS_SHARED)))
TOOLKIT_SRCS_DIRS_WITH_SHADERS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$(if $($(module_name)_SHADERS_DIR),$($(module_name)_SRCS_DIRS))))
TOOLKIT_SRCS_OBJS_WITH_SHADERS := $(foreach module,$(GLOBAL_MODULES),$(foreach module_name,$(MODULE_$(module)),\
	$(if $($(module_name)_SHADERS_DIR),$($(module_name)_SRCS_OBJS))))
endif # MAKE_4_1

TOOLKIT_MODULES := $(BUILD_С_OUTDIR)/modules.info
TOOLKIT_CACHED_FLAGS := $(BUILD_С_OUTDIR)/cached_flags.mk

TOOLKIT_CACHED_MODULES := $(shell cat $(TOOLKIT_MODULES) 2> /dev/null)

ifdef MAKE_4_1
ifneq ($(LOCAL_MODULES),$(TOOLKIT_CACHED_MODULES))
$(info Modules was updated)
$(shell $(GLOBAL_MKDIR) $(BUILD_С_OUTDIR); echo '$(LOCAL_MODULES)' > $(TOOLKIT_MODULES))
endif
endif # MAKE_4_1
	