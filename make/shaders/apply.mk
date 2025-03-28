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

TOOLKIT_SHADERS_SRCS_DIRS_TARGETS := $(realpath $(foreach dir,$(TOOLKIT_SHADERS_DIR),$(wildcard $(dir)/*/*)))
TOOLKIT_SHADERS_SRCS_EXCLUDE := $(sort $(realpath $(dir $(TOOLKIT_SHADERS_SRCS_DIRS_TARGETS))))
TOOLKIT_SHADERS_SRCS_FILES_TARGETS := $(filter-out $(TOOLKIT_SHADERS_SRCS_EXCLUDE),$(realpath $(foreach dir,$(TOOLKIT_SHADERS_DIR),$(wildcard $(dir)/*.*))))
TOOLKIT_SHADERS_COMPILED := $(addprefix $(BUILD_SHADERS_OUTDIR)/compiled,$(TOOLKIT_SHADERS_SRCS_DIRS_TARGETS))
TOOLKIT_SHADERS_LINKED := $(addprefix $(BUILD_SHADERS_OUTDIR)/linked,$(TOOLKIT_SHADERS_SRCS_EXCLUDE))
TOOLKIT_SHADERS_EMBEDDED := $(addsuffix .h,\
	$(addprefix $(BUILD_SHADERS_OUTDIR)/embedded,$(notdir $(TOOLKIT_SHADERS_SRCS_EXCLUDE))) \
	$(addprefix $(BUILD_SHADERS_OUTDIR)/embedded_files/,$(notdir $(TOOLKIT_SHADERS_SRCS_FILES_TARGETS))))

TOOLKIT_SHADERS_TARGET_INCLUDE_DIR := $(BUILD_SHADERS_OUTDIR)/embedded
TOOLKIT_SHADERS_TARGET_INCLUDE_FILES := $(BUILD_SHADERS_OUTDIR)/embedded_files
TOOLKIT_SHADERS_TARGET_INCLUDE := $(addprefix -I,$(TOOLKIT_SHADERS_TARGET_INCLUDE_DIR) $(TOOLKIT_SHADERS_TARGET_INCLUDE_FILES))

BUILD_SHADERS_SRCS_DIRS_TARGETS := $(realpath $(foreach dir,$(LOCAL_SHADERS_DIR),$(wildcard $(dir)/*/*)))
BUILD_SHADERS_SRCS_EXCLUDE := $(sort $(realpath $(dir $(BUILD_SHADERS_SRCS_DIRS_TARGETS))))
BUILD_SHADERS_SRCS_FILES_TARGETS := $(filter-out $(BUILD_SHADERS_SRCS_EXCLUDE),$(realpath $(foreach dir,$(LOCAL_SHADERS_DIR),$(wildcard $(dir)/*.*))))
BUILD_SHADERS_COMPILED := $(addprefix $(BUILD_SHADERS_OUTDIR)/compiled,$(BUILD_SHADERS_SRCS_DIRS_TARGETS))
BUILD_SHADERS_LINKED := $(addprefix $(BUILD_SHADERS_OUTDIR)/linked,$(BUILD_SHADERS_SRCS_EXCLUDE))
BUILD_SHADERS_EMBEDDED := $(addsuffix .h,\
	$(addprefix $(BUILD_SHADERS_OUTDIR)/embedded,$(notdir $(BUILD_SHADERS_SRCS_EXCLUDE)))\
	$(addprefix $(BUILD_SHADERS_OUTDIR)/embedded_files/,$(notdir $(BUILD_SHADERS_SRCS_FILES_TARGETS))))

BUILD_SHADERS_TARGET_INCLUDE_DIR := $(BUILD_SHADERS_OUTDIR)/embedded
BUILD_SHADERS_TARGET_INCLUDE_FILES := $(BUILD_SHADERS_OUTDIR)/embedded_files
BUILD_SHADERS_TARGET_INCLUDE := $(addprefix -I,$(BUILD_SHADERS_TARGET_INCLUDE_DIR) $(BUILD_SHADERS_TARGET_INCLUDE_FILES))

BUILD_SHADERS_INCLUDE = $(addprefix -I,$(realpath $(LOCAL_SHADERS_INCLUDE) $(TOOLKIT_SHADERS_INCLUDE)))

BUILD_SHADERS_FLAGS := $(BUILD_SHADERS_INCLUDE) -DSP_GLSL=1

BUILD_SHADERS_TARGET_INCLUDE_ALL := $(sort \
	$(BUILD_SHADERS_TARGET_INCLUDE_DIR) $(BUILD_SHADERS_TARGET_INCLUDE_FILES) \
	$(TOOLKIT_SHADERS_TARGET_INCLUDE_DIR) $(TOOLKIT_SHADERS_TARGET_INCLUDE_FILES))

ifdef OSTYPE_IS_MACOS
BUILD_SHADERS_FLAGS += -DSP_MVK=1
endif

define BUILD_SHADERS_compile_rule
$(1) : $(subst $(BUILD_SHADERS_OUTDIR)/compiled,,$(1)) $$(LOCAL_MAKEFILE)
	$$(call sp_compile_glsl,$(1),$(subst $(BUILD_SHADERS_OUTDIR)/compiled,,$(1)),$(LOCAL_SHADERS_RULES))
endef

define BUILD_SHADERS_link_rule
$(1) : $(addprefix $(BUILD_SHADERS_OUTDIR)/compiled,$(wildcard $(subst $(BUILD_SHADERS_OUTDIR)/linked,,$(1))/*)) $$(LOCAL_MAKEFILE)
	$$(call sp_link_spirv)
endef

define BUILD_SHADERS_embed_rule
$(addsuffix .h,$(addprefix $(BUILD_SHADERS_OUTDIR)/embedded,$(notdir $(1)))) : $(addprefix $(BUILD_SHADERS_OUTDIR)/linked,$(1)) $$(LOCAL_MAKEFILE)
	$$(call sp_embed_spirv)
endef

define BUILD_SHADERS_compile_single_rule
$(2) : $(1) $$(LOCAL_MAKEFILE)
	$$(call sp_compile_glsl_header,$(2),$(1),$(LOCAL_SHADERS_RULES))
endef

$(foreach COMPILED,$(BUILD_SHADERS_COMPILED) $(TOOLKIT_SHADERS_COMPILED),\
	$(eval $(call BUILD_SHADERS_compile_rule,$(COMPILED))))

$(foreach LINKED,$(BUILD_SHADERS_LINKED) $(TOOLKIT_SHADERS_LINKED),\
	$(eval $(call BUILD_SHADERS_link_rule,$(LINKED))))

$(foreach EMBEDDED,$(BUILD_SHADERS_SRCS_EXCLUDE) $(TOOLKIT_SHADERS_SRCS_EXCLUDE),\
	$(eval $(call BUILD_SHADERS_embed_rule,$(EMBEDDED))))

$(foreach FILE,$(BUILD_SHADERS_SRCS_FILES_TARGETS) $(TOOLKIT_SHADERS_SRCS_FILES_TARGETS),\
	$(eval $(call BUILD_SHADERS_compile_single_rule,$(FILE),\
		$(addsuffix .h,$(addprefix $(BUILD_SHADERS_OUTDIR)/embedded_files/,$(notdir $(FILE))))\
	)))
