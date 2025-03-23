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

OSTYPE_IS_LINUX := 1

OSTYPE_ARCH ?= $(STAPPLER_ARCH)

ifndef BUILD_SHARED
OSTYPE_DEPS := deps/linux/$(OSTYPE_ARCH)
OSTYPE_PREBUILT_PATH := $(OSTYPE_DEPS)/lib
OSTYPE_INCLUDE := $(OSTYPE_DEPS)/include
else
OSTYPE_DEPS :=
OSTYPE_PREBUILT_PATH :=
OSTYPE_INCLUDE :=
endif

OSTYPE_EXEC_SUFFIX :=
OSTYPE_DSO_SUFFIX := .so
OSTYPE_LIB_SUFFIX := .a
OSTYPE_LIB_PREFIX := lib

OSTYPE_GENERAL_CFLAGS := -DLINUX -Wall -fvisibility=hidden
OSTYPE_LIB_CFLAGS := -fPIC -DPIC
OSTYPE_EXEC_CFLAGS :=

OSTYPE_GENERAL_CXXFLAGS :=  -DLINUX -Wall -Wno-overloaded-virtual -frtti -fvisibility=hidden -fvisibility-inlines-hidden
OSTYPE_LIB_CXXFLAGS := -fPIC -DPIC
OSTYPE_EXEC_CXXFLAGS :=

OSTYPE_GENERAL_LDFLAGS :=
OSTYPE_EXEC_LDFLAGS := 
OSTYPE_LIB_LDFLAGS := -rdynamic -Wl,--exclude-libs,ALL

$(info Build for $(STAPPLER_ARCH))

# ldgold only tested for x86_64 linux
# For others - use default ld
ifeq ($(OSTYPE_ARCH),x86_64)
	OSTYPE_GENERAL_LDFLAGS += -fuse-ld=gold
endif

ifeq ($(CLANG),1)
	OSTYPE_GENERAL_CXXFLAGS += -Wno-unneeded-internal-declaration -Wno-gnu-string-literal-operator-template \
		-Wno-vla-cxx-extension -Wno-unqualified-std-cast-call -Wno-unused-includes
else
	OSTYPE_GENERAL_CXXFLAGS += -Wno-class-memaccess
endif

ifeq ($(ASAN),1)
	OSTYPE_GENERAL_CFLAGS += -fsanitize=address
	OSTYPE_GENERAL_CXXFLAGS += -fsanitize=address
	OSTYPE_EXEC_LDFLAGS += -fsanitize=address -static-libasan
else

endif

ifeq ($(OSTYPE_ARCH),e2k)

# warning about new/delete pairing for exceptions is wrong, since placement new in stappler is noexcept
OSTYPE_GENERAL_CFLAGS += -w830 -DSP_DEDICATED_SIMD
OSTYPE_GENERAL_CXXFLAGS += -w830 -DSP_DEDICATED_SIMD

ifneq ($(OSTYPE_ARCH),$(UNAME_ARCH))

LCC_ROOT ?= /opt/mcst/lcc-1.26.20.e2k-v4.5.4
LOCAL_PATH := $(LCC_ROOT)/bin.toolchain:$(PATH)
export PATH = $(LOCAL_PATH)

endif
endif # ($(STAPPLER_ARCH),e2k)

ifdef BUILD_SHARED

OSTYPE_LIB_LDFLAGS += -Wl,-z,defs

endif # BUILD_SHARED