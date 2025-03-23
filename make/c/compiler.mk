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

include $(BUILD_ROOT)/utils/select-c-compiler.mk

# Выбираем оптимизацию по умолчанию

GLOBAL_OPTIMIZATION := $(LOCAL_OPTIMIZATION)

ifdef LOCAL_LOG_LEVEL

ifeq ($(LOCAL_LOG_LEVEL),errors)
GLOBAL_LOG_LEVEL := 1
else ifeq ($(LOCAL_LOG_LEVEL),all)
GLOBAL_LOG_LEVEL := 2
else ifeq ($(LOCAL_LOG_LEVEL),none)
GLOBAL_LOG_LEVEL := 0
else
GLOBAL_LOG_LEVEL := $(LOCAL_LOG_LEVEL)
endif

else # LOCAL_LOG_LEVEL

ifeq ($(BUILD_TYPE),release)
GLOBAL_LOG_LEVEL := 1
else
GLOBAL_LOG_LEVEL := 2
endif

endif # LOCAL_LOG_LEVEL

OSTYPE_GCH_FILE := -x c++-header
OSTYPE_C_FILE := -x c
OSTYPE_CPP_FILE := -x c++
OSTYPE_MM_FILE := -x objective-c++

# загружаем предустановки для систем
ifeq ($(STAPPLER_TARGET),android)
	include $(BUILD_ROOT)/os/android.mk
else ifeq ($(STAPPLER_TARGET),xwin)
	include $(BUILD_ROOT)/os/xwin.mk
else ifeq ($(UNAME),Darwin)
	include $(BUILD_ROOT)/os/darwin.mk
else ifeq ($(UNAME),Msys)
	include $(BUILD_ROOT)/os/msys.mk
else
	include $(BUILD_ROOT)/os/linux.mk
endif

BUILD_TYPE_CFLAGS := -DSTAPPLER_LOG_LEVEL=$(GLOBAL_LOG_LEVEL)
BUILD_TYPE_CXXFLAGS := -DSTAPPLER_LOG_LEVEL=$(GLOBAL_LOG_LEVEL)
BUILD_TYPE_LDFLAGS :=

BUILD_TYPE_CFLAGS_RELEASE := $(GLOBAL_OPTIMIZATION) -DNDEBUG
BUILD_TYPE_CXXFLAGS_RELEASE := $(GLOBAL_OPTIMIZATION) -DNDEBUG
BUILD_TYPE_LDFLAGS_RELEASE :=

BUILD_TYPE_CFLAGS_DEBUG := -g -DDEBUG -DSTAPPLER_ROOT='$(realpath $(GLOBAL_ROOT))'
BUILD_TYPE_CXXFLAGS_DEBUG := -g -DDEBUG -DSTAPPLER_ROOT='$(realpath $(GLOBAL_ROOT))'
BUILD_TYPE_LDFLAGS_DEBUG :=

BUILD_TYPE_CFLAGS_COVERAGE := -g -DNDEBUG -fprofile-arcs -ftest-coverage -DCOVERAGE
BUILD_TYPE_CXXFLAGS_COVERAGE := -g -DNDEBUG -fprofile-arcs -ftest-coverage -DCOVERAGE
BUILD_TYPE_LDFLAGS_COVERAGE := -fprofile-arcs -ftest-coverage

# Вычисляем базовый набор флагов
ifeq ($(BUILD_TYPE),release)
	BUILD_TYPE_CFLAGS := $(BUILD_TYPE_CFLAGS) $(BUILD_TYPE_CFLAGS_RELEASE)
	BUILD_TYPE_CXXFLAGS := $(BUILD_TYPE_CXXFLAGS) $(BUILD_TYPE_CXXFLAGS_RELEASE)
	BUILD_TYPE_LDFLAGS := $(BUILD_TYPE_LDFLAGS) $(BUILD_TYPE_LDFLAGS_RELEASE)
endif

ifeq ($(BUILD_TYPE),debug)
	BUILD_TYPE_CFLAGS := $(BUILD_TYPE_CFLAGS) $(BUILD_TYPE_CFLAGS_DEBUG)
	BUILD_TYPE_CXXFLAGS := $(BUILD_TYPE_CXXFLAGS) $(BUILD_TYPE_CXXFLAGS_DEBUG)
	BUILD_TYPE_LDFLAGS := $(BUILD_TYPE_LDFLAGS) $(BUILD_TYPE_LDFLAGS_DEBUG)
endif # ifdef RELEASE

ifeq ($(BUILD_TYPE),coverage)
	BUILD_TYPE_CFLAGS := $(BUILD_TYPE_CFLAGS) $(BUILD_TYPE_CFLAGS_COVERAGE)
	BUILD_TYPE_CXXFLAGS := $(BUILD_TYPE_CXXFLAGS) $(BUILD_TYPE_CXXFLAGS_COVERAGE)
	BUILD_TYPE_LDFLAGS := $(BUILD_TYPE_LDFLAGS) $(BUILD_TYPE_LDFLAGS_COVERAGE)
endif

GLOBAL_LIB_CFLAGS := $(OSTYPE_LIB_CFLAGS)
GLOBAL_LIB_CXXFLAGS := $(OSTYPE_LIB_CXXFLAGS)
GLOBAL_LIB_LDFLAGS := $(OSTYPE_LIB_LDFLAGS)

GLOBAL_EXEC_CFLAGS := $(OSTYPE_EXEC_CFLAGS)
GLOBAL_EXEC_CXXFLAGS := $(OSTYPE_EXEC_CXXFLAGS)
GLOBAL_EXEC_LDFLAGS := $(OSTYPE_EXEC_LDFLAGS)

ifdef STAPPLER_VERSION_PREFIX
GLOBAL_GENERAL_CFLAGS += -DSTAPPLER_VERSION_PREFIX=$(STAPPLER_VERSION_PREFIX)
endif

GLOBAL_GENERAL_CXXFLAGS := $(GLOBAL_GENERAL_CXXFLAGS) -DSTAPPLER -std=$(GLOBAL_STDXX) $(OSTYPE_GENERAL_CXXFLAGS)
GLOBAL_GENERAL_CFLAGS := $(GLOBAL_GENERAL_CFLAGS) -DSTAPPLER -std=$(GLOBAL_STD) $(OSTYPE_GENERAL_CFLAGS)
GLOBAL_GENERAL_LDFLAGS := $(OSTYPE_GENERAL_LDFLAGS)

ifdef BUILD_SHARED
GLOBAL_GENERAL_CXXFLAGS += -DSTAPPLER_SHARED
GLOBAL_GENERAL_CFLAGS += -DSTAPPLER_SHARED
endif

include $(BUILD_ROOT)/c/rules.mk

BUILD_С_OUTDIR := $(BUILD_OUTDIR)/$(GLOBAL_CC)

BUILD_COMPILATION_DATABASE := ./compile_commands.json
