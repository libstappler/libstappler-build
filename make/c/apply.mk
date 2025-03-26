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

# Список библиотек для включения в конечное приложение
# Для Android в пути к библоитеке используется символ-заместитель для архитектуры, потому используется abspath вместо realpath
ifndef BUILD_SHARED
ifdef ANDROID
BUILD_LIBS := $(call sp_toolkit_resolve_libs, $(abspath $(addprefix $(GLOBAL_ROOT)/,$(OSTYPE_PREBUILT_PATH))), $(TOOLKIT_LIBS)) $(LDFLAGS)
else
RPATH_PREFIX := -Wl,-rpath,
BUILD_LIBS := \
	$(if $(BUILD_HOST),$(addprefix -L,$(SHARED_LIBDIR)) $(if $(SHARED_RPATH),$(addprefix $(RPATH_PREFIX),$(SHARED_RPATH)))) \
	$(call sp_toolkit_resolve_libs, $(if $(SHARED_LIBDIR),,$(realpath $(addprefix $(GLOBAL_ROOT)/,$(OSTYPE_PREBUILT_PATH)))), $(TOOLKIT_LIBS)) $(LDFLAGS)
endif # ANDROID
else
BUILD_LIBS :=
endif # BUILD_SHARED


# Список полных путей к прекомпилируемым заголовкам
TOOLKIT_PRECOMPILED_HEADERS := $(call sp_toolkit_resolve_prefix_files,$(TOOLKIT_PRECOMPILED_HEADERS))

# Список полных путей к копиям прекомпилируемых заголовков в директории сборки
# Копирование необходимо, чтобы обеспечить приоритет включения предкомпилируемых заголовков
TOOLKIT_LIB_H_GCH := $(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/lib_objs,$(TOOLKIT_PRECOMPILED_HEADERS))
TOOLKIT_EXEC_H_GCH := $(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/exec_objs,$(TOOLKIT_PRECOMPILED_HEADERS))

# Список финальных предкомпилированных заголовков
TOOLKIT_LIB_GCH := $(addsuffix .gch,$(TOOLKIT_LIB_H_GCH))
TOOLKIT_EXEC_GCH := $(addsuffix .gch,$(TOOLKIT_EXEC_H_GCH))

# Cписок директорий для включения от фреймворка
TOOLKIT_INCLUDES := $(call sp_toolkit_include_list, $(TOOLKIT_INCLUDES_DIRS), $(TOOLKIT_INCLUDES_OBJS))

# Cписок директорий для включения от приложения
BUILD_INCLUDES := $(call sp_local_include_list,$(LOCAL_INCLUDES_DIRS),$(LOCAL_INCLUDES_OBJS))

BUILD_GENERAL_CFLAGS := \
	$(BUILD_TYPE_CFLAGS) \
	$(GLOBAL_GENERAL_CFLAGS) \
	$(TOOLKIT_GENERAL_CFLAGS) \
	$(LOCAL_CFLAGS) \
	$(addprefix -I,$(TOOLKIT_INCLUDES)) \
	$(addprefix -I,$(BUILD_INCLUDES)) \
	$(BUILD_SHADERS_TARGET_INCLUDE) \
	$(TOOLKIT_SHADERS_TARGET_INCLUDE)

BUILD_GENERAL_CXXFLAGS := \
	$(BUILD_TYPE_CXXFLAGS) \
	$(GLOBAL_GENERAL_CXXFLAGS) \
	$(TOOLKIT_GENERAL_CXXFLAGS) \
	$(LOCAL_CXXFLAGS) \
	$(addprefix -I,$(TOOLKIT_INCLUDES)) \
	$(addprefix -I,$(BUILD_INCLUDES)) \
	$(BUILD_SHADERS_TARGET_INCLUDE) \
	$(TOOLKIT_SHADERS_TARGET_INCLUDE)

BUILD_EXEC_CFLAGS := \
	$(addprefix -I,$(sort $(dir $(TOOLKIT_EXEC_GCH)))) \
	$(BUILD_GENERAL_CFLAGS) \
	$(GLOBAL_EXEC_CFLAGS) \
	$(TOOLKIT_EXEC_CFLAGS)

BUILD_EXEC_CXXFLAGS := \
	$(addprefix -I,$(sort $(dir $(TOOLKIT_EXEC_GCH)))) \
	$(BUILD_GENERAL_CXXFLAGS) \
	$(GLOBAL_EXEC_CXXFLAGS) \
	$(TOOLKIT_EXEC_CXXFLAGS)

BUILD_LIB_CFLAGS := \
	$(addprefix -I,$(sort $(dir $(TOOLKIT_LIB_GCH)))) \
	$(BUILD_GENERAL_CFLAGS) \
	$(GLOBAL_LIB_CFLAGS) \
	$(TOOLKIT_LIB_CFLAGS)

BUILD_LIB_CXXFLAGS := \
	$(addprefix -I,$(sort $(dir $(TOOLKIT_LIB_GCH)))) \
	$(BUILD_GENERAL_CXXFLAGS) \
	$(GLOBAL_LIB_CXXFLAGS) \
	$(TOOLKIT_LIB_CXXFLAGS)

BUILD_GENERAL_LDFLAGS := \
	$(BUILD_TYPE_LDFLAGS) \
	$(GLOBAL_GENERAL_LDFLAGS) \
	$(TOOLKIT_GENERAL_LDFLAGS) \
	$(LOCAL_LDFLAGS) \
	$(BUILD_LIBS) \
	$(call sp_toolkit_resolve_libs, $(LOCAL_LIBS))

BUILD_EXEC_LDFLAGS := \
	$(BUILD_GENERAL_LDFLAGS) \
	$(GLOBAL_EXEC_LDFLAGS) \
	$(TOOLKIT_EXEC_LDFLAGS)

BUILD_LIB_LDFLAGS := \
	$(BUILD_GENERAL_LDFLAGS) \
	$(GLOBAL_LIB_LDFLAGS) \
	$(TOOLKIT_LIB_LDFLAGS) \
	$(if $(filter-out $(LOCAL_BUILD_SHARED),1),$(OSTYPE_STANDALONE_LDFLAGS))

-include $(TOOLKIT_CACHED_FLAGS)

BUILD_ALL_FLAGS := $(BUILD_EXEC_CFLAGS) $(BUILD_EXEC_CXXFLAGS) $(BUILD_LIB_CFLAGS) $(BUILD_LIB_CXXFLAGS)
BUILD_ALL_FLAGS_CACHED := $(BUILD_EXEC_CFLAGS_CACHED) $(BUILD_EXEC_CXXFLAGS_CACHED) $(BUILD_LIB_CFLAGS_CACHED) $(BUILD_LIB_CXXFLAGS_CACHED)

ifneq ($(BUILD_ALL_FLAGS),$(BUILD_ALL_FLAGS_CACHED))
$(info [Compilation database] Need full rebuild, may take a while)
$(shell $(GLOBAL_MKDIR) $(BUILD_С_OUTDIR))
$(shell echo 'BUILD_EXEC_CFLAGS_CACHED:= $(BUILD_EXEC_CFLAGS)' > $(TOOLKIT_CACHED_FLAGS))
$(shell echo 'BUILD_EXEC_CXXFLAGS_CACHED:= $(BUILD_EXEC_CXXFLAGS)' >> $(TOOLKIT_CACHED_FLAGS))
$(shell echo 'BUILD_LIB_CFLAGS_CACHED:= $(BUILD_LIB_CFLAGS)' >> $(TOOLKIT_CACHED_FLAGS))
$(shell echo 'BUILD_LIB_CXXFLAGS_CACHED:= $(BUILD_LIB_CXXFLAGS)' >> $(TOOLKIT_CACHED_FLAGS))

$(TOOLKIT_CACHED_FLAGS):
	@$(GLOBAL_MKDIR) $(BUILD_С_OUTDIR)
	@echo 'BUILD_EXEC_CFLAGS_CACHED:= $(BUILD_EXEC_CFLAGS)' > $(TOOLKIT_CACHED_FLAGS)
	@echo 'BUILD_EXEC_CXXFLAGS_CACHED:= $(BUILD_EXEC_CXXFLAGS)' >> $(TOOLKIT_CACHED_FLAGS)
	@echo 'BUILD_LIB_CFLAGS_CACHED:= $(BUILD_LIB_CFLAGS)' >> $(TOOLKIT_CACHED_FLAGS)
	@echo 'BUILD_LIB_CXXFLAGS_CACHED:= $(BUILD_LIB_CXXFLAGS)' >> $(TOOLKIT_CACHED_FLAGS)

endif

$(foreach target,$(TOOLKIT_PRECOMPILED_HEADERS),\
	$(eval $(call BUILD_include_rule,$(target),\
		$(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/lib_objs,$(target)))\
	))

$(foreach target,$(TOOLKIT_PRECOMPILED_HEADERS),\
	$(eval $(call BUILD_include_rule,$(target),\
		$(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/exec_objs,$(target)))\
	))

# Список полных путей к компилируемым файлам фреймворка
TOOLKIT_SRCS := $(call sp_toolkit_source_list, $(TOOLKIT_SRCS_DIRS), $(TOOLKIT_SRCS_OBJS))

# Список полных путей к компилируемым файлам, для которых нужно скомпилировать шейдеры
TOOLKIT_SRCS_WITH_SHADERS := $(call sp_toolkit_source_list, $(TOOLKIT_SRCS_DIRS_WITH_SHADERS), $(TOOLKIT_SRCS_OBJS_WITH_SHADERS))

# Список полных путей к компилируемым файлам приложения
BUILD_SRCS := $(call sp_local_source_list,$(LOCAL_SRCS_DIRS),$(LOCAL_SRCS_OBJS))

BUILD_MAIN_SRC := $(if $(LOCAL_MAIN),$(realpath $(addprefix $(LOCAL_ROOT)/,$(LOCAL_MAIN))))

BUILD_EXEC_SRCS := \
	$(TOOLKIT_SRCS) \
	$(BUILD_SRCS) \
	$(BUILD_MAIN_SRC)

BUILD_LIB_SRCS := \
	$(BUILD_SRCS) \
	$(if $(filter-out $(LOCAL_BUILD_SHARED),3),$(TOOLKIT_SRCS))

# Список объектных файлов, относящихся к фреймворку
TOOLKIT_LIB_OBJS := $(call sp_toolkit_object_list,$(BUILD_С_OUTDIR)/lib_objs,$(TOOLKIT_SRCS))
TOOLKIT_EXEC_OBJS := $(call sp_toolkit_object_list,$(BUILD_С_OUTDIR)/exec_objs,$(TOOLKIT_SRCS))

BUILD_MAIN_OBJ := $(call sp_toolkit_object_list,$(BUILD_С_OUTDIR)/exec_objs,$(BUILD_MAIN_SRC))

# Список терминов для подсчёта прогресса
BUILD_LIB_WORDS := $(words $(sort $(TOOLKIT_LIB_GCH) $(BUILD_LIB_SRCS)))
BUILD_EXEC_WORDS := $(words $(sort $(TOOLKIT_EXEC_GCH) $(BUILD_EXEC_SRCS)))

# Настраиваем шаблон прогресса
include $(BUILD_ROOT)/utils/verbose.mk

BUILD_LIB_OBJS :=
BUILD_EXEC_OBJS :=

define BUILD_add_target_lib
BUILD_LIB_OBJS += $(1)
endef

define BUILD_add_target_exec
BUILD_EXEC_OBJS += $(1)
endef

ifdef LOCAL_LIBRARY
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
	$(eval $(call BUILD_gch_rule,$(target),$(BUILD_LIB_CXXFLAGS)))\
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
endif

ifdef LOCAL_EXECUTABLE
sp_build_c_exec_rule_counted = \
	$(eval \
		$(call BUILD_c_rule,$(1),$(2),$(TOOLKIT_EXEC_GCH),$(BUILD_EXEC_CFLAGS))\
		$(call BUILD_EXEC_template,$(2),$(LOCAL_EXECUTABLE),$(BUILD_EXEC_WORDS))\
	)\
	$(eval $(call BUILD_add_target_exec,$(2)))

sp_build_cpp_exec_rule_counted = \
	$(eval \
		$(call BUILD_cpp_rule,$(1),$(2),$(TOOLKIT_EXEC_GCH),$(BUILD_EXEC_CXXFLAGS))\
		$(call BUILD_EXEC_template,$(2),$(LOCAL_EXECUTABLE),$(BUILD_EXEC_WORDS))\
	)\
	$(eval $(call BUILD_add_target_exec,$(2)))

sp_build_mm_exec_rule_counted = \
	$(eval \
		$(call BUILD_mm_rule,$(1),$(2),$(TOOLKIT_EXEC_GCH),$(BUILD_EXEC_CXXFLAGS))\
		$(call BUILD_EXEC_template,$(2),$(LOCAL_EXECUTABLE),$(BUILD_EXEC_WORDS))\
	)\
	$(eval $(call BUILD_add_target_exec,$(2)))

$(foreach target,$(TOOLKIT_EXEC_GCH),\
	$(eval $(call BUILD_gch_rule,$(target),$(BUILD_EXEC_CXXFLAGS)))\
	$(eval $(call BUILD_EXEC_template,$(target),$(LOCAL_EXECUTABLE),$(BUILD_EXEC_WORDS))))

$(foreach target,\
	$(sort $(filter %.c,$(BUILD_EXEC_SRCS))),\
	$(call sp_build_c_exec_rule_counted,$(target),$(call sp_build_target_path,$(target),$(BUILD_С_OUTDIR)/exec_objs)))

$(foreach target,\
	$(sort $(filter %.cpp,$(BUILD_EXEC_SRCS))),\
	$(call sp_build_cpp_exec_rule_counted,$(target),$(call sp_build_target_path,$(target),$(BUILD_С_OUTDIR)/exec_objs)))

$(foreach target,\
	$(sort $(filter %.mm,$(BUILD_EXEC_SRCS))),\
	$(call sp_build_mm_exec_rule_counted,$(target),$(call sp_build_target_path,$(target),$(BUILD_С_OUTDIR)/exec_objs)))
endif

# include dependencies
-include $(patsubst %.o,%.o.d,$(BUILD_EXEC_OBJS) $(BUILD_LIB_OBJS))
-include $(patsubst %.h.gch,%.h.gch.d,$(TOOLKIT_EXEC_GCH) $(TOOLKIT_LIB_GCH))

# CDB info
ifdef LOCAL_EXECUTABLE
BUILD_CDB_TARGET_SRCS := $(BUILD_EXEC_SRCS)
BUILD_CDB_TARGET_OBJS := $(BUILD_EXEC_OBJS)
else
BUILD_CDB_TARGET_SRCS := $(BUILD_LIB_SRCS)
BUILD_CDB_TARGET_OBJS := $(BUILD_LIB_OBJS)
endif

BUILD_CDB_TARGET_JSON := $(addsuffix .json,$(BUILD_CDB_TARGET_OBJS))
