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

ifdef LOCAL_LIBRARY

ifeq ($(LOCAL_BUILD_STATIC),1)
BUILD_STATIC_LIBRARY := $(BUILD_С_OUTDIR)/$(OSTYPE_LIB_PREFIX)$(LOCAL_LIBRARY)$(OSTYPE_LIB_SUFFIX)
BUILD_INSTALL_STATIC_LIBRARY := $(LOCAL_INSTALL_DIR)/$(OSTYPE_LIB_PREFIX)$(LOCAL_LIBRARY)$(OSTYPE_LIB_SUFFIX)
$(info Build static library: $(BUILD_STATIC_LIBRARY))
endif

ifeq ($(LOCAL_BUILD_SHARED),1)
BUILD_SHARED_LIBRARY := $(BUILD_С_OUTDIR)/$(OSTYPE_LIB_PREFIX)$(LOCAL_LIBRARY)$(OSTYPE_DSO_SUFFIX)
BUILD_INSTALL_SHARED_LIBRARY := $(LOCAL_INSTALL_DIR)/$(OSTYPE_LIB_PREFIX)$(LOCAL_LIBRARY)$(OSTYPE_DSO_SUFFIX)
$(info Build shared library: $(BUILD_SHARED_LIBRARY))
endif

ifeq ($(LOCAL_BUILD_SHARED),2)
BUILD_SHARED_LIBRARY := $(BUILD_С_OUTDIR)/$(OSTYPE_LIB_PREFIX)$(LOCAL_LIBRARY)$(OSTYPE_DSO_SUFFIX)
BUILD_INSTALL_SHARED_LIBRARY := $(LOCAL_INSTALL_DIR)/$(OSTYPE_LIB_PREFIX)$(LOCAL_LIBRARY)$(OSTYPE_DSO_SUFFIX)
$(info Build standalone shared library: $(BUILD_SHARED_LIBRARY))
endif

endif

ifdef LOCAL_EXECUTABLE
BUILD_EXECUTABLE := $(BUILD_С_OUTDIR)/$(LOCAL_EXECUTABLE)$(OSTYPE_EXEC_SUFFIX)
BUILD_INSTALL_EXECUTABLE := $(LOCAL_INSTALL_DIR)/$(LOCAL_EXECUTABLE)$(OSTYPE_EXEC_SUFFIX)
$(info Build executable: $(BUILD_EXECUTABLE))
endif

ifdef LOCAL_WASM_MODULE
BUILD_WASM_MODULE := $(BUILD_WASM_OUTDIR)/$(LOCAL_WASM_MODULE)
BUILD_INSTALL_WASM_MODULE :=  $(LOCAL_INSTALL_DIR)/$(LOCAL_WASM_MODULE)
$(info Build wasm: $(BUILD_WASM_MODULE))
endif
