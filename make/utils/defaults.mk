# Copyright (c) 2024 Stappler LLC <admin@stappler.dev>
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

GLOBAL_STDXX ?= gnu++2a
GLOBAL_STD ?= gnu11

LOCAL_ROOT ?= .
LOCAL_OUTDIR ?= stappler-build
LOCAL_BUILD_SHARED ?= 1
LOCAL_BUILD_STATIC ?= 1
LOCAL_ANDROID_TARGET ?= application
LOCAL_ANDROID_PLATFORM ?= android-24
LOCAL_OPTIMIZATION ?= -Os

BUILD_WORKDIR = $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))

ifdef BUILD_HOST
LOCAL_INSTALL_DIR ?= $(LOCAL_OUTDIR)/host
BUILD_OUTDIR := $(LOCAL_OUTDIR)/host/$(BUILD_TYPE)
endif

ifdef BUILD_ANDROID
LOCAL_INSTALL_DIR ?= $(LOCAL_OUTDIR)/android
BUILD_OUTDIR := $(LOCAL_OUTDIR)/android/$(BUILD_TYPE)
endif

ifdef BUILD_XWIN
LOCAL_INSTALL_DIR ?= $(LOCAL_OUTDIR)/xwin
BUILD_OUTDIR := $(LOCAL_OUTDIR)/xwin/$(BUILD_TYPE)
endif

ifdef SHARED_PREFIX
GLOBAL_ROOT := $(SHARED_PREFIX)
else
ifdef STAPPLER_ROOT
GLOBAL_ROOT := $(STAPPLER_ROOT)
else
GLOBAL_ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))/../../..)
endif
endif

GLOBAL_OUTPUT := $(BUILD_OUTDIR)

GLOBAL_RM ?= rm -f
GLOBAL_CP ?= cp -f
GLOBAL_MAKE ?= make
GLOBAL_MKDIR ?= mkdir -p
GLOBAL_AR ?= ar rcs

# Проверяем хостовую систему, у Darwin нет опции -o для uname
UNAME := $(shell uname)

ifneq ($(UNAME),Darwin)
	UNAME := $(shell uname -o)
endif

ifeq ($(findstring MSYS_NT,$(UNAME)),MSYS_NT)
	UNAME := $(shell uname -o)
endif

UNAME_ARCH ?= $(shell uname -m)

#
# WebAssebmly
#

WIT_BINDGEN ?= wit-bindgen

WASI_SDK ?= /opt/wasi-sdk
WASI_SDK_CC ?= $(WASI_SDK)/bin/clang
WASI_SDK_CXX ?= $(WASI_SDK)/bin/clang++
WASI_THREADS ?= 1

GLOBAL_WASM_OPTIMIZATION ?= -Os

# Отладка WebAssembly фактически останавливает выполнение приложения
# в ожидании подключения отладчика LLDB. Потому, это поведение необходимо
# явно включать, оно не включается автоматически в отладочной форме приложения
GLOBAL_WASM_DEBUG ?= 0

ifdef MSYS
sp_os_path = $(shell cygpath -u $(abspath $(1)))
else
sp_os_path = $(1)
endif

ifeq (4.1,$(firstword $(sort $(MAKE_VERSION) 4.1)))
MAKE_4_1 := 1
else
$(info COMPATIBILITY MODE: Some functions may not work. Minimal required make version: 4.1)
endif