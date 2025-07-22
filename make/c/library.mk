# Copyright (c) 2025 Stappler LLC <admin@stappler.dev>
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

BUILD_LIB_OBJS :=
BUILD_LIB_CONFIG :=

define BUILD_add_target_lib
BUILD_LIB_OBJS += $(1)
endef

ifndef SHARED_PREFIX
BUILD_LIB_CONFIG := $(BUILD_С_OUTDIR)/lib_objs/include/stappler-buildconfig.h
$(eval $(call BUILD_config_header,$(BUILD_LIB_CONFIG),buildconfig,$(BUILD_CONFIG_FLAGS) BUILD_LIBRARY,$(BUILD_CONFIG_VALUES),$(BUILD_CONFIG_STRINGS)))
endif

sp_build_c_lib_rule_counted = \
	$(eval \
		$(call BUILD_c_rule,$(1),$(2),$(TOOLKIT_LIB_GCH),$(BUILD_LIB_CFLAGS))\
		$(call BUILD_LIB_template,$(2),$(LOCAL_LIBRARY),$(BUILD_LIB_WORDS))\
	)\
	$(eval $(call BUILD_add_target_lib,$(2)))

sp_build_cpp_lib_rule_counted = \
	$(eval \
		$(call BUILD_cpp_rule,$(1),$(2),$(TOOLKIT_LIB_GCH),$(BUILD_LIB_CXXFLAGS))\
		$(call BUILD_LIB_template,$(2),$(LOCAL_LIBRARY),$(BUILD_LIB_WORDS))\
	)\
	$(eval $(call BUILD_add_target_lib,$(2)))

sp_build_mm_lib_rule_counted = \
	$(eval \
		$(call BUILD_mm_rule,$(1),$(2),$(TOOLKIT_LIB_GCH),$(BUILD_LIB_CXXFLAGS))\
		$(call BUILD_LIB_template,$(2),$(LOCAL_LIBRARY),$(BUILD_LIB_WORDS))\
	)\
	$(eval $(call BUILD_add_target_lib,$(2)))

$(foreach target,$(TOOLKIT_LIB_GCH),\
	$(eval $(call BUILD_gch_rule,$(target),$(BUILD_LIB_CXXFLAGS),$(BUILD_LIB_CONFIG)))\
	$(eval $(call BUILD_LIB_template,$(target),$(LOCAL_LIBRARY),$(BUILD_LIB_WORDS))))

$(foreach target,\
	$(sort $(filter %.c,$(BUILD_LIB_SRCS))),\
	$(call sp_build_c_lib_rule_counted,$(target),$(call sp_build_target_path,$(target),$(BUILD_С_OUTDIR)/lib_objs)))

$(foreach target,\
	$(sort $(filter %.cpp,$(BUILD_LIB_SRCS))),\
	$(call sp_build_cpp_lib_rule_counted,$(target),$(call sp_build_target_path,$(target),$(BUILD_С_OUTDIR)/lib_objs)))

$(foreach target,\
	$(sort $(filter %.mm,$(BUILD_LIB_SRCS))),\
	$(call sp_build_mm_lib_rule_counted,$(target),$(call sp_build_target_path,$(target),$(BUILD_С_OUTDIR)/lib_objs)))

BUILD_CDB_TARGET_SRCS += $(BUILD_LIB_SRCS)
BUILD_CDB_TARGET_OBJS += $(BUILD_LIB_OBJS)
