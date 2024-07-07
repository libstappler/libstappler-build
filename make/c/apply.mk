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

# Список библиотек для включения в конечное приложение
# Для Android в пути к библоитеке используется символ-заместитель для архитектуры, потому используется abspath вместо realpath
ifdef ANDROID
TOOLKIT_LIBS := $(call sp_toolkit_resolve_libs, $(abspath $(addprefix $(GLOBAL_ROOT)/,$(OSTYPE_PREBUILT_PATH))), $(TOOLKIT_LIBS)) $(LDFLAGS)
else
TOOLKIT_LIBS := $(call sp_toolkit_resolve_libs, $(realpath $(addprefix $(GLOBAL_ROOT)/,$(OSTYPE_PREBUILT_PATH))), $(TOOLKIT_LIBS)) $(LDFLAGS)
endif

# Список полных путей к прекомпилируемым заголовкам
TOOLKIT_PRECOMPILED_HEADERS := $(call sp_toolkit_resolve_prefix_files,$(TOOLKIT_PRECOMPILED_HEADERS))

# Список полных путей к копиям прекомпилируемых заголовков в директории сборки
# Копирование необходимо, чтобы обеспечить приоритет включения предкомпилируемых заголовков
TOOLKIT_LIB_H_GCH := $(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/lib,$(TOOLKIT_PRECOMPILED_HEADERS))
TOOLKIT_EXEC_H_GCH := $(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/exec,$(TOOLKIT_PRECOMPILED_HEADERS))

# Список финальных предкомпилированных заголовков
TOOLKIT_LIB_GCH := $(addsuffix .gch,$(TOOLKIT_LIB_H_GCH))
TOOLKIT_EXEC_GCH := $(addsuffix .gch,$(TOOLKIT_EXEC_H_GCH))

# Cписок директорий для включения от фреймворка
TOOLKIT_INCLUDES := $(call sp_toolkit_include_list, $(TOOLKIT_INCLUDES_DIRS), $(TOOLKIT_INCLUDES_OBJS))

# Cписок директорий для включения от приложения
BUILD_INCLUDES := $(call sp_local_include_list,$(LOCAL_INCLUDES_DIRS),$(LOCAL_INCLUDES_OBJS))

BUILD_GENERAL_CFLAGS := \
	$(GLOBAL_GENERAL_CFLAGS) \
	$(TOOLKIT_GENERAL_CFLAGS) \
	$(LOCAL_CFLAGS) \
	$(addprefix -I,$(TOOLKIT_INCLUDES)) \
	$(addprefix -I,$(BUILD_INCLUDES)) \
	$(BUILD_SHADERS_TARGET_INCLUDE) \
	$(TOOLKIT_SHADERS_TARGET_INCLUDE)

BUILD_GENERAL_CXXFLAGS := \
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
	$(GLOBAL_GENERAL_LDFLAGS) \
	$(TOOLKIT_GENERAL_LDFLAGS) \
	$(LOCAL_LDFLAGS) \
	$(TOOLKIT_LIBS) \
	$(call sp_toolkit_resolve_libs $(LOCAL_LIBS))

BUILD_EXEC_LDFLAGS := \
	$(BUILD_GENERAL_LDFLAGS) \
	$(GLOBAL_EXEC_LDFLAGS) \
	$(TOOLKIT_EXEC_LDFLAGS)

BUILD_LIB_LDFLAGS := \
	$(BUILD_GENERAL_LDFLAGS) \
	$(GLOBAL_LIB_LDFLAGS) \
	$(TOOLKIT_LIB_LDFLAGS) \
	$(if $(filter-out $(LOCAL_BUILD_SHARED),1),$(OSTYPE_STANDALONE_LDFLAGS))

$(foreach target,$(TOOLKIT_PRECOMPILED_HEADERS),\
	$(eval $(call BUILD_include_rule,$(target),\
		$(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/lib,$(target)))\
	))

$(foreach target,$(TOOLKIT_PRECOMPILED_HEADERS),\
	$(eval $(call BUILD_include_rule,$(target),\
		$(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR)/exec,$(target)))\
	))

$(foreach target,$(TOOLKIT_LIB_GCH),$(eval $(call BUILD_gch_rule,$(target),$(BUILD_LIB_CXXFLAGS))))
$(foreach target,$(TOOLKIT_EXEC_GCH),$(eval $(call BUILD_gch_rule,$(target),$(BUILD_EXEC_CXXFLAGS))))


# Список полных путей к компилируемым файлам фреймворка
TOOLKIT_SRCS := $(call sp_toolkit_source_list, $(TOOLKIT_SRCS_DIRS), $(TOOLKIT_SRCS_OBJS))

# Список полных путей к компилируемым файлам, для которых нужно скомпилировать шейдеры
TOOLKIT_SRCS_WITH_SHADERS := $(call sp_toolkit_source_list, $(TOOLKIT_SRCS_DIRS_WITH_SHADERS), $(TOOLKIT_SRCS_OBJS_WITH_SHADERS))

# Список полных путей к компилируемым файлам приложения
BUILD_SRCS := $(call sp_local_source_list,$(LOCAL_SRCS_DIRS),$(LOCAL_SRCS_OBJS))

BUILD_MAIN_SRC := $(if $(LOCAL_MAIN),$(realpath $(addprefix $(LOCAL_ROOT)/,$(LOCAL_MAIN))))

BUILD_ALL_SRCS := \
	$(TOOLKIT_SRCS) \
	$(BUILD_SRCS) \
	$(BUILD_MAIN_SRC)

$(foreach target,\
	$(sort $(filter %.c,$(BUILD_ALL_SRCS))),\
	$(eval $(call BUILD_c_rule,$(target),$(BUILD_С_OUTDIR)/lib,$(TOOLKIT_LIB_GCH),$(BUILD_LIB_CFLAGS))))

$(foreach target,\
	$(sort $(filter %.cpp,$(BUILD_ALL_SRCS))),\
	$(eval $(call BUILD_cpp_rule,$(target),$(BUILD_С_OUTDIR)/lib,$(TOOLKIT_LIB_GCH),$(BUILD_LIB_CXXFLAGS))))

$(foreach target,\
	$(sort $(filter %.mm,$(BUILD_ALL_SRCS))),\
	$(eval $(call BUILD_mm_rule,$(target),$(BUILD_С_OUTDIR)/lib,$(TOOLKIT_LIB_GCH),$(BUILD_LIB_CXXFLAGS))))

$(foreach target,\
	$(sort $(filter %.c,$(BUILD_ALL_SRCS))),\
	$(eval $(call BUILD_c_rule,$(target),$(BUILD_С_OUTDIR)/exec,$(TOOLKIT_EXEC_GCH),$(BUILD_EXEC_CFLAGS))))

$(foreach target,\
	$(sort $(filter %.cpp,$(BUILD_ALL_SRCS))),\
	$(eval $(call BUILD_cpp_rule,$(target),$(BUILD_С_OUTDIR)/exec,$(TOOLKIT_EXEC_GCH),$(BUILD_EXEC_CXXFLAGS))))

$(foreach target,\
	$(sort $(filter %.mm,$(BUILD_ALL_SRCS))),\
	$(eval $(call BUILD_mm_rule,$(target),$(BUILD_С_OUTDIR)/exec,$(TOOLKIT_EXEC_GCH),$(BUILD_EXEC_CXXFLAGS))))

# Список объектных файлов, относящихся к фреймворку
TOOLKIT_LIB_OBJS := $(call sp_toolkit_object_list,$(BUILD_С_OUTDIR)/lib,$(TOOLKIT_SRCS))
TOOLKIT_EXEC_OBJS := $(call sp_toolkit_object_list,$(BUILD_С_OUTDIR)/exec,$(TOOLKIT_SRCS))

# Список объектных файлов приложения
BUILD_LIB_OBJS := $(call sp_local_object_list,$(BUILD_С_OUTDIR)/lib,$(BUILD_SRCS))
BUILD_EXEC_OBJS := $(call sp_local_object_list,$(BUILD_С_OUTDIR)/exec,$(BUILD_SRCS))

BUILD_MAIN_OBJ := $(call sp_local_object_list,$(BUILD_С_OUTDIR)/exec,$(BUILD_MAIN_SRC))

# Список терминов для подсчёта прогресса
BUILD_LIB_WORDS := $(words $(TOOLKIT_LIB_GCH) $(BUILD_LIB_OBJS) $(TOOLKIT_LIB_OBJS))
BUILD_EXEC_WORDS := $(words $(TOOLKIT_EXEC_GCH) $(BUILD_EXEC_OBJS) $(BUILD_MAIN_OBJ) $(TOOLKIT_EXEC_OBJS))

# Настраиваем шаблон прогресса
include $(BUILD_ROOT)/utils/verbose.mk

$(foreach obj,$(TOOLKIT_EXEC_GCH) $(BUILD_EXEC_OBJS) $(TOOLKIT_EXEC_OBJS) $(BUILD_MAIN_OBJ),\
	$(eval $(call BUILD_EXEC_template,$(obj),$(LOCAL_EXECUTABLE),$(BUILD_EXEC_WORDS))))

$(foreach obj,$(TOOLKIT_LIB_GCH) $(BUILD_LIB_OBJS) $(TOOLKIT_LIB_OBJS),\
	$(eval $(call BUILD_LIB_template,$(obj),$(LOCAL_LIBRARY),$(BUILD_LIB_WORDS))))

BUILD_EXEC_OBJS := \
	$(BUILD_EXEC_OBJS) \
	$(TOOLKIT_EXEC_OBJS) \
	$(BUILD_MAIN_OBJ)

BUILD_LIB_OBJS := \
	$(BUILD_LIB_OBJS) \
	$(if $(filter-out $(LOCAL_BUILD_SHARED),3),$(TOOLKIT_LIB_OBJS))

# include dependencies
-include $(patsubst %.o,%.o.d,$(BUILD_EXEC_OBJS) $(BUILD_LIB_OBJS))
-include $(patsubst %.h.gch,%.h.gch.d,$(TOOLKIT_EXEC_GCH) $(TOOLKIT_LIB_GCH))
