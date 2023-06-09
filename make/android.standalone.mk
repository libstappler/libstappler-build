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

.DEFAULT_GOAL := all
IS_LOCAL_BUILD := 1

BUILD_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

BUILD_OUTDIR := $(LOCAL_OUTDIR)/android

GLOBAL_ROOT := $(STAPPLER_ROOT)
GLOBAL_OUTPUT := $(BUILD_OUTDIR)

THIS_FILE := $(firstword $(MAKEFILE_LIST))

BUILD_LIBS_LIST := $(LOCAL_LIBS)

include $(GLOBAL_ROOT)/make/utils/compiler.mk

BUILD_OUTDIR := $(BUILD_OUTDIR)/$(BUILD_TYPE)/$(ANDROID_ARCH)
GLOBAL_OUTPUT := $(BUILD_OUTDIR)

ifeq ($(LOCAL_TOOLKIT),none)
BUILD_EXPORT_STATIC := $(BUILD_OUTDIR)/$(LOCAL_LIBRARY).a
else
BUILD_LIBRARY := $(BUILD_OUTDIR)/$(LOCAL_LIBRARY).so
BUILD_STATIC := $(BUILD_OUTDIR)/$(LOCAL_LIBRARY).a
ifndef ANDROID_EXPORT
LOCAL_SRCS_OBJS += $(realpath $(NDK)/sources/android/cpufeatures/cpu-features.c)
endif
endif

include $(GLOBAL_ROOT)/make/utils/compile-local.mk

LOCAL_ANDROID_TARGET ?= application
LOCAL_ANDROID_PLATFORM ?= android-24

BUILD_ANDROID_ARGS := \
	NDK_PROJECT_PATH=null \
	APP_BUILD_SCRIPT=$(LOCAL_ANDROID_MK) \
	NDK_OUT=$(BUILD_OUTDIR)/obj \
	NDK_LIBS_OUT=$(BUILD_OUTDIR)/libs \
	NDK_APPLICATION_MK:=$(LOCAL_APPLICATION_MK) \
	APP_PLATFORM=$(LOCAL_ANDROID_PLATFORM)

ifdef RELEASE
else
BUILD_ANDROID_ARGS += NDK_DEBUG=1
endif

all:
	+$(NDK)/ndk-build $(BUILD_ANDROID_ARGS) $(LOCAL_ANDROID_TARGET) --no-print-directory

clean_local:
	$(GLOBAL_RM) $(BUILD_OUTDIR)

clean: clean_local
.PHONY: clean_local clean .prebuild_local all static

.prebuild_local:
	@$(GLOBAL_MKDIR) $(BUILD_DIRS)
