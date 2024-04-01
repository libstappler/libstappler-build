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

GLOBAL_ROOT ?= .

# Проверяем хостовую систему, у Darwin нет опции -o для uname
UNAME := $(shell uname)

ifneq ($(UNAME),Darwin)
	UNAME := $(shell uname -o)
endif

ifeq ($(findstring MSYS_NT,$(UNAME)),MSYS_NT)
	UNAME := $(shell uname -o)
endif

# Выбираем компиляторы, предпочитаем gcc/g++ если не заданы
# Устанавливаем флаг, если компилируем с clang

UNAME_ARCH ?= $(shell uname -m)

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
GLOBAL_CPP := aarch64-linux-gnu-g++
GLOBAL_CC := aarch64-linux-gnu-gcc
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

LOCAL_OPTIMIZATION ?= -Os
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
ifdef RELEASE
	BUILD_TYPE := release
	GLOBAL_CFLAGS := $(GLOBAL_OPTIMIZATION) -DNDEBUG $(OSTYPE_CFLAGS) $(GLOBAL_CFLAGS)
else
	BUILD_TYPE := debug
	GLOBAL_CFLAGS := -g -DDEBUG -DSTAPPLER_ROOT=$(realpath $(GLOBAL_ROOT))  $(OSTYPE_CFLAGS) $(GLOBAL_CFLAGS)
endif # ifdef RELEASE

ifdef STAPPLER_VERSION_PREFIX
GLOBAL_CFLAGS += -DSTAPPLER_VERSION_PREFIX=$(STAPPLER_VERSION_PREFIX)
endif

GLOBAL_CXXFLAGS := $(GLOBAL_CFLAGS) -DSTAPPLER -std=$(GLOBAL_STDXX) $(OSTYPE_CPPFLAGS)
GLOBAL_CFLAGS := $(GLOBAL_CFLAGS) -DSTAPPLER -std=$(GLOBAL_STD)
GLOBAL_LDFLAGS :=

# Если запрошено покрытие тестами  добавляем флаги профпайлинга
ifdef COVERAGE
	ifndef CLANG
		BUILD_TYPE := coverage
		GLOBAL_CFLAGS += -fprofile-arcs -ftest-coverage
		GLOBAL_CXXFLAGS += -fprofile-arcs -ftest-coverage
		GLOBAL_LDFLAGS += -fprofile-arcs -ftest-coverage
	endif
endif

GLOBAL_RM ?= rm -f
GLOBAL_CP ?= cp -f
GLOBAL_MAKE ?= make
GLOBAL_MKDIR ?= mkdir -p
GLOBAL_AR ?= ar rcs

include $(BUILD_ROOT)/c/rules.mk

BUILD_С_OUTDIR := $(BUILD_OUTDIR)/$(GLOBAL_CC)/$(BUILD_TYPE)
