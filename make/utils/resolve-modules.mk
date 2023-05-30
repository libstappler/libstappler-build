# Copyright (c) 2023 Stappler LLC <admin@stappler.dev>
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
LOCAL_MODULES += stappler_build_module

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
TOOLKIT_MODULE_FLAGS += $($(1)_FLAGS) -D$(1)
TOOLKIT_FLAGS += $($(1)_FLAGS) -D$(1)
TOOLKIT_LIBS += $($(1)_LIBS)
TOOLKIT_SRCS_DIRS += $($(1)_SRCS_DIRS)
TOOLKIT_SRCS_OBJS += $($(1)_SRCS_OBJS)
TOOLKIT_INCLUDES_DIRS += $($(1)_INCLUDES_DIRS)
TOOLKIT_INCLUDES_OBJS += $($(1)_INCLUDES_OBJS)
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
