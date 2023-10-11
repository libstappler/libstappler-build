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

CLANG_VERSION := $(shell echo `clang --version | grep -Eo '[0-9]+\.[0-9]+' | head -1`)
CLANG_REQUIRED := 16.0

ifeq ($(CLANG_REQUIRED),$(firstword $(sort $(CLANG_VERSION) $(CLANG_REQUIRED))))
CLANG_CC := clang
CLANG_CXX := clang++
else
$(info Default clang below 16.0, C++ compiler set to clang-16)
CLANG_CC := clang-16
CLANG_CXX := clang++-16
endif

ifndef GLOBAL_CPP
GLOBAL_CPP := $(CLANG_CXX)
GLOBAL_CC := $(CLANG_CC)
CLANG := 1
endif

ifndef GLOBAL_CC
GLOBAL_CPP := $(CLANG_CXX)
GLOBAL_CC := $(CLANG_CC)
CLANG := 1
endif
