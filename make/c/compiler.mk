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

# Выбираем компиляторы, предпочитаем gcc/g++ если не заданы
# Устанавливаем флаг, если компилируем с clang

ifdef XWIN
# Для XWIN нужен clang не менее 16.0, другие компиляторы не поддерживаются
include $(BUILD_ROOT)/utils/define-clang-16.mk
endif

ifeq ($(UNAME),Msys)
# Для XWIN нужен clang не менее 16.0, другие компиляторы не поддерживаются
include $(BUILD_ROOT)/utils/define-clang-16.mk
endif

ifeq ($(STAPPLER_ARCH),e2k)
ifneq ($(STAPPLER_ARCH),$(UNAME_ARCH))
GLOBAL_CPP ?= e2k-linux-l++
GLOBAL_CC ?= e2k-linux-lcc
endif
endif

ifeq ($(STAPPLER_ARCH),aarch64)
ifneq ($(STAPPLER_ARCH),$(UNAME_ARCH))
GLOBAL_CPP ?= aarch64-linux-gnu-g++
GLOBAL_CC ?= aarch64-linux-gnu-gcc
endif
endif

ifndef GLOBAL_CPP
	ifdef MINGW
		GLOBAL_CPP := $(MINGW)-g++
	else
		GLOBAL_CPP := g++
	endif # ifdef MINGW
else
	ifneq (,$(findstring clang,$(GLOBAL_CPP)))
		CLANG := 1
	endif
endif # ifndef GLOBAL_CPP

ifndef GLOBAL_CC
	ifdef MINGW
		GLOBAL_CC := $(MINGW)-gcc
	else
		GLOBAL_CC := gcc
	endif # ifdef MINGW
else
	ifneq (,$(findstring clang,$(GLOBAL_CC)))
		CLANG := 1
	endif
endif # ifndef GLOBAL_CC

# Выбираем оптимизацию по умолчанию

GLOBAL_OPTIMIZATION := $(LOCAL_OPTIMIZATION)

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

# Вычисляем базовый набор флагов
ifeq ($(BUILD_TYPE),release)
	GLOBAL_GENERAL_CFLAGS := $(GLOBAL_OPTIMIZATION) -DNDEBUG $(OSTYPE_GENERAL_CFLAGS) $(GLOBAL_GENERAL_CFLAGS)
	GLOBAL_GENERAL_CXXFLAGS := $(GLOBAL_OPTIMIZATION) -DNDEBUG $(OSTYPE_GENERAL_CXXFLAGS) $(GLOBAL_GENERAL_CXXFLAGS)
	GLOBAL_GENERAL_LDFLAGS := $(OSTYPE_GENERAL_LDFLAGS)
endif

ifeq ($(BUILD_TYPE),debug)
	GLOBAL_GENERAL_CFLAGS := -g -DDEBUG -DSTAPPLER_ROOT=$(realpath $(GLOBAL_ROOT))  $(OSTYPE_GENERAL_CFLAGS) $(GLOBAL_GENERAL_CFLAGS)
	GLOBAL_GENERAL_CXXFLAGS := -g -DDEBUG -DSTAPPLER_ROOT=$(realpath $(GLOBAL_ROOT))  $(OSTYPE_GENERAL_CXXFLAGS) $(GLOBAL_GENERAL_CXXFLAGS)
	GLOBAL_GENERAL_LDFLAGS := $(OSTYPE_GENERAL_LDFLAGS)
endif # ifdef RELEASE

ifeq ($(BUILD_TYPE),coverage)
	GLOBAL_GENERAL_CFLAGS := -g -DNDEBUG $(OSTYPE_GENERAL_CFLAGS) $(GLOBAL_GENERAL_CFLAGS) -fprofile-arcs -ftest-coverage -DCOVERAGE
	GLOBAL_GENERAL_CXXFLAGS := -g -DNDEBUG $(OSTYPE_GENERAL_CXXFLAGS) $(GLOBAL_GENERAL_CXXFLAGS) -fprofile-arcs -ftest-coverage -DCOVERAGE
	GLOBAL_GENERAL_LDFLAGS := $(OSTYPE_GENERAL_LDFLAGS) -fprofile-arcs -ftest-coverage
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

GLOBAL_GENERAL_CXXFLAGS := $(GLOBAL_GENERAL_CXXFLAGS) -DSTAPPLER -std=$(GLOBAL_STDXX)
GLOBAL_GENERAL_CFLAGS := $(GLOBAL_GENERAL_CFLAGS) -DSTAPPLER -std=$(GLOBAL_STD)
GLOBAL_GENERAL_LDFLAGS := $(OSTYPE_GENERAL_LDFLAGS)

include $(BUILD_ROOT)/c/rules.mk

BUILD_С_OUTDIR := $(BUILD_OUTDIR)/$(GLOBAL_CC)
