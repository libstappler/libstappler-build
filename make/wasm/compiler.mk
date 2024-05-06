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

WIT_BINDGEN ?= wit-bindgen

WASI_SDK ?= /opt/wasi-sdk
WASI_SDK_CC ?= $(WASI_SDK)/bin/clang
WASI_SDK_CXX ?= $(WASI_SDK)/bin/clang++
WASI_THREADS ?= 1

GLOBAL_WASM_OPTIMIZATION ?= -Os

BUILD_WIT_OUTDIR := $(BUILD_OUTDIR)/$(notdir $(WIT_BINDGEN))/$(BUILD_TYPE)
BUILD_WASM_OUTDIR := $(BUILD_OUTDIR)/wasm/$(notdir $(WASI_SDK_CC))/$(BUILD_TYPE)

ifeq ($(WASI_THREADS),1)
BUILD_WASM_CFLAGS_DEFAULT := -DSTAPPLER -DWASM -mreference-types -mbulk-memory -msign-ext -mmultivalue -mtail-call \
	 --target=wasm32-wasi-threads
else
BUILD_WASM_CFLAGS_DEFAULT := -DSTAPPLER -DWASM -mreference-types -mbulk-memory -msign-ext -mmultivalue -mtail-call \
	 --target=wasm32-wasi
endif

ifdef WASI_SYSROOT
BUILD_WASM_CFLAGS_DEFAULT += --sysroot=$(WASI_SYSROOT)
endif

ifeq ($(GLOBAL_WASM_DEBUG),1)
$(info WASM debug enabled)
ifdef RELEASE
BUILD_WASM_CFLAGS_DEFAULT += $(GLOBAL_WASM_OPTIMIZATION) -DNDEBUG
else
BUILD_WASM_CFLAGS_DEFAULT += -g -DDEBUG
endif # ifdef RELEASE
else
BUILD_WASM_CFLAGS_DEFAULT += $(GLOBAL_WASM_OPTIMIZATION) -DNDEBUG
endif

# Force WASI to export memory allocation functions
BUILD_WASM_LDFLAGS := -z stack-size=4096 -Wl,--no-entry -Wl,--export=malloc -Wl,--export=free -Wl,--export=realloc -mexec-model=reactor

BUILD_WASM_CFLAGS_INIT := $(BUILD_WASM_CFLAGS_DEFAULT) -std=$(GLOBAL_STD)
BUILD_WASM_CXXFLAGS_INIT := $(BUILD_WASM_CFLAGS_DEFAULT) -std=$(GLOBAL_STDXX) -fno-exceptions

sp_compile_wasm_c = $(GLOBAL_QUIET_WASM_CC) $(GLOBAL_MKDIR) $(dir $@); $(WASI_SDK_CC) \
	$(OSTYPE_C_FILE) $(call sp_compile_dep, $@, $(1)) -c -o $(call sp_convert_path,$@) $(call sp_convert_path,$<)

sp_compile_wasm_cpp = $(GLOBAL_QUIET_WASM_CXX) $(GLOBAL_MKDIR) $(dir $@); $(WASI_SDK_CXX) \
	$(OSTYPE_CPP_FILE) $(call sp_compile_dep, $@, $(1))  -c -o $(call sp_convert_path,$@) $(call sp_convert_path,$<)

sp_toolkit_wit_list = $(foreach f,\
	$(realpath $(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.wit'))) \
	$(realpath $(foreach dir,$(filter-out /%,$(1)),$(shell find $(GLOBAL_ROOT)/$(dir) -name '*.wit'))) \
	$(abspath $(filter /%,$(filter %.wit,$(2)))) \
	$(abspath $(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(filter %.wit,$(2))))) \
,$(call sp_unconvert_path,$(f)))

sp_toolkit_wit_list_abs = $(foreach f,$(abspath\
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.wit')) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(GLOBAL_ROOT)/$(dir) -name '*.wit')) \
	$(filter /%,$(filter %.wit,$(2))) \
	$(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(filter %.wit,$(2)))) \
),$(call sp_unconvert_path,$(f)))

sp_local_wit_list = \
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.wit')) \
	$(filter /%,$(filter %.wit,$(2))) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(LOCAL_ROOT)/$(dir) -name '*.wit')) \
	$(addprefix $(LOCAL_ROOT)/,$(filter-out /%,$(filter %.wit,$(2))))

sp_wasm_srcs_list = \
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.cpp')) \
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -name '*.c')) \
	$(filter /%,$(2)) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(3)/$(dir) -name '*.cpp')) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(3)/$(dir) -name '*.c')) \
	$(addprefix $(GLOBAL_ROOT)/,$(filter-out /%,$(2))) \

sp_wasm_include_list = $(foreach f,$(realpath\
	$(foreach dir,$(filter /%,$(1)),$(shell find $(dir) -type d)) \
	$(foreach dir,$(filter-out /%,$(1)),$(shell find $(3)/$(dir) -type d)) \
	$(addprefix $(3)/,$(filter-out /%,$(2))) \
	$(filter /%,$(2)) \
),$(call sp_unconvert_path,$(f)))

sp_wasm_object_list = \
	$(addprefix $(1),$(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(realpath $(2)))))

sp_copy_wit = $(GLOBAL_QUIET_WIT) $(GLOBAL_MKDIR) $(BUILD_WIT_OUTDIR)/wit; $(GLOBAL_CP) $(1) $(BUILD_WIT_OUTDIR)/wit/$(notdir $(1))
