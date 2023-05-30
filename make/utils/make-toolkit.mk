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

TOOLKIT_LIBS := $(call sp_toolkit_resolve_libs, $(GLOBAL_ROOT)/$(OSTYPE_PREBUILT_PATH), $(TOOLKIT_LIBS)) $(LDFLAGS)
TOOLKIT_SRCS := $(call sp_toolkit_source_list, $(TOOLKIT_SRCS_DIRS), $(TOOLKIT_SRCS_OBJS))\
	$(call sp_toolkit_source_list_abs, $(TOOLKIT_SRCS_DIRS_ABS), $(TOOLKIT_SRCS_OBJS_ABS))
TOOLKIT_INCLUDES := $(call sp_toolkit_include_list, $(TOOLKIT_INCLUDES_DIRS), $(TOOLKIT_INCLUDES_OBJS))

TOOLKIT_PRECOMPILED_HEADERS :=  $(call sp_toolkit_resolve_prefix_files,$(TOOLKIT_PRECOMPILED_HEADERS))
TOOLKIT_H_GCH := $(call sp_toolkit_prefix_files_list,$(BUILD_OUTDIR),$(TOOLKIT_PRECOMPILED_HEADERS))
TOOLKIT_GCH := $(addsuffix .gch,$(TOOLKIT_H_GCH))

TOOLKIT_OBJS := $(call sp_toolkit_object_list,$(BUILD_OUTDIR),$(TOOLKIT_SRCS))

TOOLKIT_INPUT_CFLAGS := $(call sp_toolkit_include_flags,$(TOOLKIT_GCH),$(TOOLKIT_INCLUDES))

TOOLKIT_CXXFLAGS := $(GLOBAL_CXXFLAGS) $(TOOLKIT_FLAGS) $(TOOLKIT_INPUT_CFLAGS)
TOOLKIT_CFLAGS := $(GLOBAL_CFLAGS) $(TOOLKIT_FLAGS) $(TOOLKIT_INPUT_CFLAGS)

TOOLKIT_MODULES := $(BUILD_OUTDIR)/modules.info

COUNTER_WORDS := $(words $(TOOLKIT_GCH) $(TOOLKIT_OBJS))
COUNTER_NAME := toolkit

include $(BUILD_ROOT)/utils/counter.mk

$(foreach obj,$(TOOLKIT_GCH) $(TOOLKIT_OBJS),$(eval $(call counter_template,$(obj))))

$(shell \
	$(GLOBAL_MKDIR) $(BUILD_OUTDIR); \
	echo 'modules: $(LOCAL_MODULES)' > $(TOOLKIT_MODULES).tmp; \
	if cmp -s "$(TOOLKIT_MODULES).tmp" "$(TOOLKIT_MODULES)" ; then \
		$(GLOBAL_RM) $(TOOLKIT_MODULES).tmp; \
	else \
		$(GLOBAL_RM) $(TOOLKIT_MODULES); \
		mv $(TOOLKIT_MODULES).tmp $(TOOLKIT_MODULES); \
		touch $(TOOLKIT_MODULES); \
	fi \
)

# include dependencies
-include $(patsubst %.o,%.o.d,$(TOOLKIT_OBJS))
-include $(patsubst %.h.gch,%.h.gch.d,$(TOOLKIT_GCH))

# $(1) is a parameter to substitute. The $$ will expand as $.

define TOOLKIT_include_rule
$(2): $(1) $$(LOCAL_MAKEFILE) $$($TOOLKIT_MODULES)
	$$(call sp_copy_header,$(1),$(2))
endef

define TOOLKIT_gch_rule
$(1): $(patsubst %.h.gch,%.h,$(1)) $(call sp_make_dep,$(1)) $$(LOCAL_MAKEFILE) $$($TOOLKIT_MODULES)
	$$(call sp_compile_gch,$(2))
endef

define TOOLKIT_c_rule
$(abspath $(addprefix $(2),$(patsubst %.c,%.o,$(1)))): $(1) $$(TOOLKIT_H_GCH) $$(TOOLKIT_GCH) \
		$(call sp_make_dep,$(abspath $(addprefix $(2),$(patsubst %.c,%.o,$(1))))) $$(LOCAL_MAKEFILE) $$(TOOLKIT_MODULES)
	$$(call sp_compile_c,$(3))
endef

define TOOLKIT_cpp_rule
$(abspath $(addprefix $(2),$(patsubst %.cpp,%.o,$(1)))): $(1) $$(TOOLKIT_H_GCH) $$(TOOLKIT_GCH) \
		$(call sp_make_dep,$(abspath $(addprefix $(2),$(patsubst %.cpp,%.o,$(1))))) $$(LOCAL_MAKEFILE) $$(TOOLKIT_MODULES)
	$$(call sp_compile_cpp,$(3))
endef

define TOOLKIT_mm_rule
$(abspath $(addprefix $(2),$(patsubst %.mm,%.o,$(1)))): $(1) $$(TOOLKIT_H_GCH) $$(TOOLKIT_GCH) \
		$(call sp_make_dep,$(abspath $(addprefix $(2),$(patsubst %.mm,%.o,$(1))))) $$(LOCAL_MAKEFILE) $$(TOOLKIT_MODULES)
	$$(call sp_compile_mm,$(3))
endef

$(foreach target,$(TOOLKIT_PRECOMPILED_HEADERS),$(eval $(call TOOLKIT_include_rule,$(target),\
	$(call sp_toolkit_prefix_files_list,$(BUILD_OUTDIR),$(target)))))

$(foreach target,$(TOOLKIT_GCH),$(eval $(call TOOLKIT_gch_rule,$(target),$(TOOLKIT_CXXFLAGS))))

$(foreach target,\
	$(filter %.c,$(TOOLKIT_SRCS)),\
	$(eval $(call TOOLKIT_c_rule,$(target),$(BUILD_OUTDIR),$(TOOLKIT_CFLAGS))))

$(foreach target,\
	$(filter %.cpp,$(TOOLKIT_SRCS)),\
	$(eval $(call TOOLKIT_cpp_rule,$(target),$(BUILD_OUTDIR),$(TOOLKIT_CXXFLAGS))))

$(foreach target,\
	$(filter %.mm,$(TOOLKIT_SRCS)),\
	$(eval $(call TOOLKIT_mm_rule,$(target),$(BUILD_OUTDIR),$(TOOLKIT_CXXFLAGS))))

ifeq ($(UNAME),Msys)
.INTERMEDIATE: $(subst /,_,$(TOOLKIT_GCH) $(TOOLKIT_OBJS))

$(subst /,_,$(TOOLKIT_GCH) $(TOOLKIT_OBJS)):
	@touch $@

endif
