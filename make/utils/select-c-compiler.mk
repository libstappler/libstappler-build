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

ifeq ($(UNAME),Darwin)

GLOBAL_CPP ?= clang++
GLOBAL_CC ?= clang

else

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
