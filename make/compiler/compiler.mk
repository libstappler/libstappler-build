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

ifndef GLOBAL_CPP
	ifdef XWIN
		# XWIN может использовать только clang версии 16+ для компиляции
		CLANG_VERSION_GE_16 := $(shell echo `clang --version | grep -Eo '[0-9]+\.[0-9]+' | head -1` \>= 16.0 | bc)
		ifeq ($(CLANG_VERSION_GE_16),1)
			GLOBAL_CPP := clang++
		else
$(info Default clang below 16.0, C++ compiler set to clang++-16)
			GLOBAL_CPP := clang++-16
		endif
		CLANG := 1
	else
		ifdef MINGW
			GLOBAL_CPP := $(MINGW)-g++
		else
			GLOBAL_CPP := g++
		endif # ifdef MINGW
	endif
else
	ifneq (,$(findstring clang,$(GLOBAL_CPP)))
		CLANG := 1
	endif
endif # ifndef GLOBAL_CPP

ifndef GLOBAL_CC
	ifdef XWIN
		# XWIN может использовать только clang версии 16+ для компиляции
		CLANG_VERSION_GE_16 := $(shell echo `clang --version | grep -Eo '[0-9]+\.[0-9]+' | head -1` \>= 16.0 | bc)
		ifeq ($(CLANG_VERSION_GE_16),1)
			GLOBAL_CC := clang
		else
$(info Default clang below 16.0, C compiler set to clang-16)
			GLOBAL_CC := clang-16
		endif
		CLANG := 1
	else
		ifdef MINGW
			GLOBAL_CC := $(MINGW)-gcc
		else
			GLOBAL_CC := gcc
		endif # ifdef MINGW
	endif
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

GLOBAL_STDXX ?= gnu++2a
GLOBAL_STD ?= gnu11

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

include $(BUILD_ROOT)/compiler/rules.mk
include $(BUILD_ROOT)/shaders/compiler.mk

BUILD_OUTDIR := $(BUILD_OUTDIR)/$(GLOBAL_CC)/$(BUILD_TYPE)
