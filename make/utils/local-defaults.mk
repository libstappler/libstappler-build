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

LOCAL_ROOT ?= .
LOCAL_OUTDIR ?= stappler-build
LOCAL_BUILD_SHARED ?= 1
LOCAL_BUILD_STATIC ?= 1
LOCAL_ANDROID_TARGET ?= application
LOCAL_ANDROID_PLATFORM ?= android-24

ifdef BUILD_HOST
LOCAL_INSTALL_DIR ?= $(LOCAL_OUTDIR)/host
BUILD_OUTDIR := $(LOCAL_OUTDIR)/host
endif

ifdef BUILD_ANDROID
LOCAL_INSTALL_DIR ?= $(LOCAL_OUTDIR)/android
BUILD_OUTDIR := $(LOCAL_OUTDIR)/android
endif

ifdef BUILD_XWIN
LOCAL_INSTALL_DIR ?= $(LOCAL_OUTDIR)/xwin
BUILD_OUTDIR := $(LOCAL_OUTDIR)/xwin
endif

GLOBAL_ROOT := $(STAPPLER_ROOT)
GLOBAL_OUTPUT := $(BUILD_OUTDIR)
