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

BUILD_SRCS := $(call sp_local_source_list,$(LOCAL_SRCS_DIRS),$(LOCAL_SRCS_OBJS))
BUILD_INCLUDES := $(call sp_local_include_list,$(LOCAL_INCLUDES_DIRS),$(LOCAL_INCLUDES_OBJS),$(LOCAL_ABSOLUTE_INCLUDES))
BUILD_OBJS := $(call sp_local_object_list,$(BUILD_OUTDIR),$(BUILD_SRCS))

ifdef LOCAL_MAIN
BUILD_MAIN_SRC := $(realpath $(addprefix $(LOCAL_ROOT)/,$(LOCAL_MAIN)))
BUILD_MAIN_SRC := $(BUILD_MAIN_SRC:.c=.o)
BUILD_MAIN_SRC := $(BUILD_MAIN_SRC:.cpp=.o)
BUILD_MAIN_SRC := $(BUILD_MAIN_SRC:.mm=.o)
BUILD_MAIN_OBJ := $(addprefix $(BUILD_OUTDIR),$(BUILD_MAIN_SRC))
else
BUILD_MAIN_OBJ := 
endif

BUILD_CURRENT_COUNTER ?= 1
BUILD_FILES_COUNTER ?= 1

include $(BUILD_ROOT)/utils/resolve-modules.mk
include $(BUILD_ROOT)/utils/make-toolkit.mk

ifeq (4.1,$(firstword $(sort $(MAKE_VERSION) 4.1)))
sp_counter_text = [$(BUILD_LIBRARY): $$(($(BUILD_CURRENT_COUNTER)*100/$(BUILD_FILES_COUNTER)))% $(BUILD_CURRENT_COUNTER)/$(BUILD_FILES_COUNTER)]
else
sp_counter_text = 
endif

ifdef verbose
ifneq ($(verbose),1)
GLOBAL_QUIET_CC = @ echo $(call sp_counter_text) [$(notdir $(GLOBAL_CC))] $@ ;
GLOBAL_QUIET_CPP = @ echo $(call sp_counter_text) [$(notdir $(GLOBAL_CPP))] $@ ;
GLOBAL_QUIET_LINK = @ echo [Link] $@ ;
GLOBAL_QUIET_GLSLC = @ echo [$(notdir $(GLSLC))] $(notdir $(abspath $(dir $*)))/$(notdir $@) ;
GLOBAL_QUIET_SPIRV_LINK = @ echo [$(notdir $(SPIRV_LINK))] $(notdir $@) ;
GLOBAL_QUIET_SPIRV_EMBED = @ echo [embed] $(notdir $@) ;
endif
else
GLOBAL_QUIET_CC = @ echo $(call sp_counter_text) [$(notdir $(GLOBAL_CC))] $(notdir $@) ;
GLOBAL_QUIET_CPP = @ echo $(call sp_counter_text) [$(notdir $(GLOBAL_CPP))] $(notdir $@) ;
GLOBAL_QUIET_LINK = @ echo [Link] $@ ;
GLOBAL_QUIET_GLSLC = @ echo [$(notdir $(GLSLC))] $(notdir $(abspath $(dir $*)))/$(notdir $@) ;
GLOBAL_QUIET_SPIRV_LINK = @ echo [$(notdir $(SPIRV_LINK))] $(notdir $@) ;
GLOBAL_QUIET_SPIRV_EMBED = @ echo [embed] $(notdir $@) ;
endif

BUILD_CFLAGS += $(LOCAL_CFLAGS) $(TOOLKIT_CFLAGS)
BUILD_CXXFLAGS += $(LOCAL_CFLAGS) $(LOCAL_CXXFLAGS) $(TOOLKIT_CXXFLAGS)

# Progress counter
BUILD_COUNTER := 0
BUILD_WORDS := $(words $(BUILD_OBJS) $(BUILD_MAIN_OBJ))

define BUILD_template =
$(eval BUILD_COUNTER=$(shell echo $$(($(BUILD_COUNTER)+1))))
$(1):BUILD_CURRENT_COUNTER:=$(BUILD_COUNTER)
$(1):BUILD_FILES_COUNTER := $(BUILD_WORDS)
ifdef LOCAL_EXECUTABLE
$(1):BUILD_LIBRARY := $(notdir $(LOCAL_EXECUTABLE))
else
$(1):BUILD_LIBRARY := $(notdir $(LOCAL_LIBRARY))
endif
endef

$(foreach obj,$(BUILD_OBJS) $(BUILD_MAIN_OBJ),$(eval $(call BUILD_template,$(obj))))

BUILD_LOCAL_OBJS := $(BUILD_OBJS) $(BUILD_MAIN_OBJ)

BUILD_OBJS += $(TOOLKIT_OBJS)
BUILD_GCH += $(TOOLKIT_GCH)

BUILD_CFLAGS += $(addprefix -I,$(BUILD_INCLUDES))
BUILD_CXXFLAGS += $(addprefix -I,$(BUILD_INCLUDES))

BUILD_LOCAL_LIBS := $(foreach lib,$(LOCAL_LIBS),-L$(dir $(lib)) -l:$(notdir $(lib)))
BUILD_EXEC_LIBS := $(BUILD_LOCAL_LIBS) $(TOOLKIT_LIBS) $(GLOBAL_LDFLAGS) $(LOCAL_LDFLAGS) $(OSTYPE_EXEC_FLAGS)

ifeq ($(LOCAL_BUILD_SHARED),3)
BUILD_DSO_LIBS := $(BUILD_LOCAL_LIBS) $(GLOBAL_LDFLAGS) $(LOCAL_LDFLAGS) $(OSTYPE_STANDALONE_LDFLAGS)
else

ifeq ($(LOCAL_BUILD_SHARED),2)
BUILD_DSO_LIBS := $(BUILD_LOCAL_LIBS) $(TOOLKIT_LIBS) $(GLOBAL_LDFLAGS) $(LOCAL_LDFLAGS) $(OSTYPE_STANDALONE_LDFLAGS)
else
BUILD_DSO_LIBS := $(BUILD_LOCAL_LIBS) $(TOOLKIT_LIBS) $(GLOBAL_LDFLAGS) $(LOCAL_LDFLAGS) $(OSTYPE_LDFLAGS)
endif

endif

-include $(patsubst %.o,%.o.d,$(BUILD_OBJS) $(BUILD_MAIN_OBJ))

include $(BUILD_ROOT)/shaders/apply.mk

$(BUILD_OUTDIR)/%.o: /%.cpp $(BUILD_H_GCH) $(BUILD_GCH) $(BUILD_MODULES) $(BUILD_SHADERS_EMBEDDED)
	$(call sp_compile_cpp,$(BUILD_CXXFLAGS) $(BUILD_SHADERS_TARGET_INCLUDE))

$(BUILD_OUTDIR)/%.o: /%.mm $(BUILD_H_GCH) $(BUILD_GCH) $(BUILD_MODULES) $(BUILD_SHADERS_EMBEDDED)
	$(call sp_compile_mm,$(BUILD_CXXFLAGS) $(BUILD_SHADERS_TARGET_INCLUDE))

$(BUILD_OUTDIR)/%.o: /%.c $(BUILD_H_GCH) $(BUILD_GCH) $(BUILD_MODULES) $(BUILD_SHADERS_EMBEDDED)
	$(call sp_compile_c,$(BUILD_CFLAGS) $(BUILD_SHADERS_TARGET_INCLUDE))
