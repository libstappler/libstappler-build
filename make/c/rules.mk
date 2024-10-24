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

# Функции для вывода правил компиляции

ifeq ($(CLANG),1)
ifdef MSYS
# Записываем имя зависимости в формате unix, иначе make не сможет её сопоставить
sp_compile_dep = -MMD -MP -MF $1.d -MJ $1.json $(2) -MT$(shell cygpath -u $(abspath $(1)))
else
sp_compile_dep = -MMD -MP -MF $1.d -MJ $1.json $(2)
endif
else
sp_compile_dep = -MMD -MP -MF $1.d $(2) # -MT $(subst /,_,$1)
endif

sp_compile_gch = $(GLOBAL_QUIET_CPP) $(GLOBAL_MKDIR) $(dir $@); $(GLOBAL_CPP) \
	$(OSTYPE_GCH_FILE) $(call sp_compile_dep, $@, $(1)) -c -o $(call sp_convert_path,$@) $(call sp_convert_path,$<)

sp_compile_c = $(GLOBAL_QUIET_CC) $(GLOBAL_MKDIR) $(dir $@); $(GLOBAL_CC) \
	$(OSTYPE_C_FILE) $(call sp_compile_dep, $@, $(1)) -c -o $(call sp_convert_path,$@) $(call sp_convert_path,$<)

sp_compile_cpp = $(GLOBAL_QUIET_CPP) $(GLOBAL_MKDIR) $(dir $@); $(GLOBAL_CPP) \
	$(OSTYPE_CPP_FILE) $(call sp_compile_dep, $@, $(1))  -c -o $(call sp_convert_path,$@) $(call sp_convert_path,$<)

sp_compile_mm = $(GLOBAL_QUIET_CPP) $(GLOBAL_MKDIR) $(dir $@); $(GLOBAL_CPP) \
	$(OSTYPE_MM_FILE) $(call sp_compile_dep, $@, $(1)) -fobjc-arc -c -o $(call sp_convert_path,$@) $(call sp_convert_path,$<)

sp_copy_header = @@$(GLOBAL_MKDIR) $(dir $@); cp -f $< $@

# $(call sp_toolkit_source_list, $($(TOOLKIT_NAME)_SRCS_DIRS), $($(TOOLKIT_NAME)_SRCS_OBJS))

sp_toolkit_source_list_c = $(foreach f,\
	$(realpath $(foreach dir,$(filter /%,$(1)),$(shell find $(dir) \( -name "*.c" -or -name "*.cpp" \)))) \
	$(realpath $(foreach dir,$(filter-out /%,$(1)),$(shell find $(GLOBAL_ROOT)/$(dir) \( -name "*.c" -or -name "*.cpp" \)))) \
	$(abspath $(filter /%,$(filter-out %.mm,$(2)))) \
	$(abspath $(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(filter-out %.mm,$(2))))) \
	$(if $(BUILD_OBJC), \
		$(realpath $(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.mm'))) \
		$(realpath $(foreach dir,$(filter-out /%,$(1)),$(shell find $(GLOBAL_ROOT)/$(dir) -name '*.mm'))) \
		$(abspath $(filter /%,$(filter %.mm,$(2)))) \
		$(abspath $(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(filter %.mm,$(2))))) \
	)\
,$(call sp_unconvert_path,$(f)))

sp_toolkit_source_list = $(call sp_toolkit_source_list_c,$(1),$(filter-out %.wit,$(2)))

sp_toolkit_include_list = $(foreach f,$(realpath\
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -type d)) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(GLOBAL_ROOT)/$(dir) -type d)) \
	$(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(2))) \
	$(filter /%,$(2)) \
),$(call sp_unconvert_path,$(f)))

sp_toolkit_object_list = \
	$(addprefix $(1)/objs/,$(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(patsubst %.mm,%.o,$(notdir $(2))))))

sp_toolkit_resolve_prefix_files = \
	$(realpath $(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(1)))) \
	$(realpath $(filter /%,$(1)))

sp_toolkit_prefix_files_list = \
	$(abspath $(addprefix $(1)/include/,$(notdir $(2))))

sp_toolkit_include_flags = \
	$(addprefix -I,$(sort $(dir $(1)))) $(addprefix -I,$(2))

sp_local_source_list_c = \
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.cpp')) \
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.c')) \
	$(filter /%,$(filter-out %.mm,$(2))) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(LOCAL_ROOT)/$(dir) -name '*.cpp')) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(LOCAL_ROOT)/$(dir) -name '*.c')) \
	$(addprefix $(LOCAL_ROOT)/,$(filter-out /%,$(filter-out %.mm,$(2)))) \
	$(if $(BUILD_OBJC),\
		$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.mm'))\
		$(foreach dir,$(filter-out /%,$(1)),$(shell find $(LOCAL_ROOT)/$(dir) -name '*.mm'))\
		$(filter /%,$(filter %.mm,$(2)))\
		$(addprefix $(LOCAL_ROOT)/,$(filter-out /%,$(filter %.mm,$(2))))\
	)

sp_local_source_list = $(call sp_local_source_list_c,$(1),$(filter-out %.wit,$(2)))

sp_local_include_list = \
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -type d)) \
	$(filter /%,$(2)) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(LOCAL_ROOT)/$(dir) -type d)) \
	$(addprefix $(LOCAL_ROOT)/,$(filter-out /%,$(2)))

sp_local_object_list = \
	$(addprefix $(1)/objs/,$(patsubst %.mm,%.o,$(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(notdir $(2))))))

sp_toolkit_transform_lib_ldflag = \
	$(patsubst -l:lib%.a,-l%,$(1))

ifdef OSTYPE_IS_WIN32
sp_toolkit_transform_lib = $(sp_toolkit_transform_lib_ldflag)
else
sp_toolkit_transform_lib = $(1)
endif

ifdef RESOLVE_LIBS_REALPATH
sp_toolkit_resolve_libs = \
	$(subst -l:,$(abspath $(1))/,$(call sp_toolkit_transform_lib,$(2)))
else
sp_toolkit_resolve_libs = \
	$(addprefix -L,$(1)) $(call sp_toolkit_transform_lib,$(2))
endif

# $(1) - source path
# $(2) - target path
define BUILD_include_rule
$(2): $(1) $$(LOCAL_MAKEFILE) $$($TOOLKIT_MODULES)
	$$(call sp_copy_header,$(1),$(2))
endef

# $(1) - source path
# $(2) - compilation flags
define BUILD_gch_rule
$(1): $(patsubst %.h.gch,%.h,$(1)) $$(LOCAL_MAKEFILE) $$($TOOLKIT_MODULES)
	$$(call sp_compile_gch,$(2))
endef

# $(1) - source path
# $(2) - target build dir
# $(3) - precompiled headers
# $(4) - compilation flags
define BUILD_c_rule
$(addprefix $(2)/objs/,$(patsubst %.c,%.o,$(notdir $(1)))): \
		$(1) $(3) \
		$(if $(findstring $(1),$(TOOLKIT_SRCS_WITH_SHADERS)),$$(TOOLKIT_SHADERS_EMBEDDED) $$(TOOLKIT_SHADERS_LINKED) $$(TOOLKIT_SHADERS_COMPILED)) \
		$$(LOCAL_MAKEFILE) $$(TOOLKIT_MODULES) $$(BUILD_SHADERS_EMBEDDED)
	$$(call sp_compile_c,$(4))
endef

# $(1) - source path
# $(2) - target build dir
# $(3) - precompiled headers
# $(4) - compilation flags
define BUILD_cpp_rule
$(addprefix $(2)/objs/,$(patsubst %.cpp,%.o,$(notdir $(1)))): \
		$(1) $(3) \
		$(if $(findstring $(1),$(TOOLKIT_SRCS_WITH_SHADERS)),$$(TOOLKIT_SHADERS_EMBEDDED) $$(TOOLKIT_SHADERS_LINKED) $$(TOOLKIT_SHADERS_COMPILED)) \
		$$(LOCAL_MAKEFILE) $$(TOOLKIT_MODULES) $$(BUILD_SHADERS_EMBEDDED)
	$$(call sp_compile_cpp,$(4))
endef

# $(1) - source path
# $(2) - target build dir
# $(3) - precompiled headers
# $(4) - compilation flags
define BUILD_mm_rule
$(addprefix $(2)/objs/,$(patsubst %.mm,%.o,$(notdir $(1)))): \
		$(1) $(3) \
		$(if $(findstring $(1),$(TOOLKIT_SRCS_WITH_SHADERS)),$$(TOOLKIT_SHADERS_EMBEDDED) $$(TOOLKIT_SHADERS_LINKED) $$(TOOLKIT_SHADERS_COMPILED)) \
		$$(LOCAL_MAKEFILE) $$(TOOLKIT_MODULES) $$(BUILD_SHADERS_EMBEDDED)
	$$(call sp_compile_mm,$(4))
endef

