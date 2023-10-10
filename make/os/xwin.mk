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

OSTYPE_IS_WIN32 := 1

OSTYPE_ARCH ?= x86_64
OSTYPE_ARCH_LOCAL ?= x64
OSTYPE_TARGET ?= x86_64-windows-msvc

ifeq ($(RELEASE),1)
OSTYPE_BUILD_TYPE := release
else
OSTYPE_BUILD_TYPE := debug
endif

XWIN_PATH ?= deps/xwin

XWIN_REPLACEMENTS_INCLUDE := $(XWIN_PATH)/../windows/replacements/include
XWIN_REPLACEMENTS_BIN := $(XWIN_PATH)/../windows/replacements/bin

XWIN_CRT_INCLUDE += \
	$(XWIN_PATH)/splat/crt/include \
	$(XWIN_PATH)/splat/sdk/include/ucrt \
	$(XWIN_PATH)/splat/sdk/include/um \
	$(XWIN_PATH)/splat/sdk/include/shared

XWIN_CRT_LIB += \
	$(XWIN_PATH)/splat/crt/lib/$(OSTYPE_ARCH) \
	$(XWIN_PATH)/splat/sdk/lib/um/$(OSTYPE_ARCH) \
	$(XWIN_PATH)/splat/sdk/lib/ucrt/$(OSTYPE_ARCH) \
	$(XWIN_PATH)/.xwin-cache/unpack/ucrt.msi/lib/ucrt/$(OSTYPE_ARCH_LOCAL) \
	$(XWIN_PATH)/.xwin-cache/unpack/Microsoft.VC.14.37.17.7.CRT.$(OSTYPE_ARCH_LOCAL).Desktop.base.vsix/lib/$(OSTYPE_ARCH_LOCAL)

OSTYPE_PREBUILT_PATH := deps/windows/$(OSTYPE_ARCH)/$(OSTYPE_BUILD_TYPE)/lib $(XWIN_CRT_LIB)
OSTYPE_INCLUDE := deps/windows/$(OSTYPE_ARCH)/$(OSTYPE_BUILD_TYPE)/include  $(XWIN_REPLACEMENTS_INCLUDE) $(XWIN_CRT_INCLUDE)
OSTYPE_CFLAGS :=  -DWIN32 -DXWIN -Wall --target=$(OSTYPE_TARGET) -m64 -msse2 -D_MT \
	-Wno-unqualified-std-cast-call -Wno-microsoft-include -Wno-nonportable-include-path
OSTYPE_CPPFLAGS := -Wno-overloaded-virtual -frtti

OSTYPE_EXEC_SUFFIX := .exe

ifeq ($(RELEASE),1)
OSTYPE_CFLAGS +=
OSTYPE_LDFLAGS_BUILDTYPE :=  -llibucrt -llibvcruntime -llibcmt -llibcpmt
else
OSTYPE_CFLAGS += -D_DEBUG -Xclang -gcodeview
OSTYPE_LDFLAGS_BUILDTYPE := -g -Xclang -gcodeview -llibucrtd -llibvcruntimed -llibcmtd -llibcpmtd
endif

OSTYPE_LDFLAGS :=  --target=$(OSTYPE_TARGET) -fuse-ld=lld -Xlinker -nodefaultlib $(OSTYPE_LDFLAGS_BUILDTYPE) -lkernel32 -lws2_32
OSTYPE_EXEC_FLAGS := --target=$(OSTYPE_TARGET) -fuse-ld=lld -Xlinker -nodefaultlib $(OSTYPE_LDFLAGS_BUILDTYPE) -lkernel32 -lws2_32

XWIN := 1
WIN32 := 1
	