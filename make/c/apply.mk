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

# Список полных путей к компилируемым файлам фреймворка
TOOLKIT_SRCS := $(call sp_toolkit_source_list, $(TOOLKIT_SRCS_DIRS), $(TOOLKIT_SRCS_OBJS)) \
	$(call sp_toolkit_source_list_abs, $(TOOLKIT_SRCS_DIRS_ABS), $(TOOLKIT_SRCS_OBJS_ABS))

# Список полных путей к компилируемым файлам, для которых нужно скомпилировать шейдеры
TOOLKIT_SRCS_WITH_SHADERS := $(call sp_toolkit_source_list, $(TOOLKIT_SRCS_DIRS_WITH_SHADERS), $(TOOLKIT_SRCS_OBJS_WITH_SHADERS)) \
	$(call sp_toolkit_source_list_abs, $(TOOLKIT_SRCS_DIRS_ABS), $(TOOLKIT_SRCS_OBJS_ABS))

# Список полных путей к прекомпилируемым заголовкам
TOOLKIT_PRECOMPILED_HEADERS :=  $(call sp_toolkit_resolve_prefix_files,$(TOOLKIT_PRECOMPILED_HEADERS))

# Список полных путей к копиям прекомпилируемых заголовков в директории сборки
# Копирование необходимо, чтобы обеспечить приоритет включения предкомпилируемых заголовков
TOOLKIT_H_GCH := $(call sp_toolkit_prefix_files_list,$(BUILD_С_OUTDIR),$(TOOLKIT_PRECOMPILED_HEADERS))

# Список финальных предкомпилированных заголовков
TOOLKIT_GCH := $(addsuffix .gch,$(TOOLKIT_H_GCH))

# Список объектных файлов, относящихся к фреймворку
TOOLKIT_OBJS := $(call sp_toolkit_object_list,$(BUILD_С_OUTDIR),$(TOOLKIT_SRCS))

# Список полных путей к компилируемым файлам приложения
BUILD_SRCS := $(call sp_local_source_list,$(LOCAL_SRCS_DIRS),$(LOCAL_SRCS_OBJS))

# Список объектных файлов приложения
BUILD_OBJS := $(call sp_local_object_list,$(BUILD_С_OUTDIR),$(BUILD_SRCS))

# Определяем объектный файл для файла, содержащего функцию main платформы
ifdef LOCAL_MAIN
BUILD_MAIN_SRC := $(realpath $(addprefix $(LOCAL_ROOT)/,$(LOCAL_MAIN)))
BUILD_MAIN_SRC := $(BUILD_MAIN_SRC:.c=.o)
BUILD_MAIN_SRC := $(BUILD_MAIN_SRC:.cpp=.o)
BUILD_MAIN_SRC := $(BUILD_MAIN_SRC:.mm=.o)
BUILD_MAIN_OBJ := $(addprefix $(BUILD_С_OUTDIR),$(BUILD_MAIN_SRC))
else
BUILD_MAIN_OBJ := 
endif

# Список терминов для подсчёта прогресса
BUILD_WORDS := $(words $(BUILD_OBJS) $(BUILD_MAIN_OBJ) $(TOOLKIT_OBJS) $(TOOLKIT_GCH))

# Настраиваем шаблон прогресса
include $(BUILD_ROOT)/utils/verbose.mk

$(foreach obj,$(TOOLKIT_GCH) $(BUILD_OBJS) $(TOOLKIT_OBJS) $(BUILD_MAIN_OBJ),$(eval $(call BUILD_template,$(obj))))

# Cписок директорий для включения от фреймворка
TOOLKIT_INCLUDES := $(call sp_toolkit_include_list, $(TOOLKIT_INCLUDES_DIRS), $(TOOLKIT_INCLUDES_OBJS))

# Cписок директорий для включения от приложения
BUILD_INCLUDES := $(call sp_local_include_list,$(LOCAL_INCLUDES_DIRS),$(LOCAL_INCLUDES_OBJS),$(LOCAL_ABSOLUTE_INCLUDES))

TOOLKIT_INPUT_CFLAGS := $(call sp_toolkit_include_flags,$(TOOLKIT_GCH),$(TOOLKIT_INCLUDES)) $(TOOLKIT_SHADERS_TARGET_INCLUDE)

TOOLKIT_CFLAGS := $(GLOBAL_CFLAGS) $(TOOLKIT_FLAGS) $(TOOLKIT_INPUT_CFLAGS)
TOOLKIT_CXXFLAGS := $(GLOBAL_CXXFLAGS) $(TOOLKIT_FLAGS) $(TOOLKIT_INPUT_CFLAGS)

BUILD_CFLAGS += $(LOCAL_CFLAGS) $(TOOLKIT_CFLAGS)
BUILD_CXXFLAGS += $(LOCAL_CFLAGS) $(LOCAL_CXXFLAGS) $(TOOLKIT_CXXFLAGS)

ifneq ($(LOCAL_BUILD_SHARED),3)
BUILD_OBJS += $(TOOLKIT_OBJS)
endif
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

include $(BUILD_ROOT)/utils/make-toolkit.mk

-include $(patsubst %.o,%.o.d,$(BUILD_OBJS) $(BUILD_MAIN_OBJ))

$(BUILD_С_OUTDIR)/%.o: /%.cpp $(BUILD_H_GCH) $(BUILD_GCH) $(BUILD_MODULES) $(BUILD_SHADERS_EMBEDDED)
	$(call sp_compile_cpp,$(BUILD_CXXFLAGS) $(BUILD_SHADERS_TARGET_INCLUDE))

$(BUILD_С_OUTDIR)/%.o: /%.mm $(BUILD_H_GCH) $(BUILD_GCH) $(BUILD_MODULES) $(BUILD_SHADERS_EMBEDDED)
	$(call sp_compile_mm,$(BUILD_CXXFLAGS) $(BUILD_SHADERS_TARGET_INCLUDE))

$(BUILD_С_OUTDIR)/%.o: /%.c $(BUILD_H_GCH) $(BUILD_GCH) $(BUILD_MODULES) $(BUILD_SHADERS_EMBEDDED)
	$(call sp_compile_c,$(BUILD_CFLAGS) $(BUILD_SHADERS_TARGET_INCLUDE))
