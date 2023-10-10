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

OSTYPE_ARCH ?= x86_64
OSTYPE_PREBUILT_PATH := deps/linux/$(OSTYPE_ARCH)/lib
OSTYPE_INCLUDE :=  deps/linux/$(OSTYPE_ARCH)/include
OSTYPE_CFLAGS := -DLINUX -Wall -fPIC
OSTYPE_CPPFLAGS := -Wno-overloaded-virtual -frtti

OSTYPE_EXEC_SUFFIX :=

OSTYPE_LDFLAGS := -Wl,-z,defs -rdynamic
OSTYPE_EXEC_FLAGS :=

# ldgold only tested for x86_64 linux
# For others - use default ld
ifeq ($(OSTYPE_ARCH),x86_64)
	OSTYPE_LDFLAGS += -fuse-ld=gold
	OSTYPE_EXEC_FLAGS += -fuse-ld=gold
endif

ifeq ($(CLANG),1)
	OSTYPE_CPPFLAGS += -Wno-unneeded-internal-declaration -Wno-gnu-string-literal-operator-template
	OSTYPE_LDFLAGS +=
	OSTYPE_EXEC_FLAGS +=
else
	OSTYPE_CPPFLAGS += -Wno-class-memaccess
endif

ifeq ($(ASAN),1)
	OSTYPE_CFLAGS += -fsanitize=address
	OSTYPE_EXEC_FLAGS += -fsanitize=address -static-libasan
else

endif

LINUX := 1
