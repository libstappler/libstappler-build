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

# Usually we use NDK variable, transferred to make
# (like: `make android NDK=/path/to/ndk`)
# You can use ANDROID_NDK_ROOT env var
NDK ?= $(ANDROID_NDK_ROOT)

OSTYPE_DEPS := deps/android/universal
OSTYPE_PREBUILT_PATH := deps/android/$$(TARGET_ARCH_ABI)/lib
OSTYPE_INCLUDE :=  deps/android/$$(TARGET_ARCH_ABI)/include

OSTYPE_EXEC_SUFFIX :=
OSTYPE_DSO_SUFFIX := .so
OSTYPE_LIB_SUFFIX := .a
OSTYPE_LIB_PREFIX := lib

RESOLVE_LIBS_REALPATH := 1
GLOBAL_CC := ndk-build
GLOBAL_CPP := ndk-build

ANDROID_EXPORT_PREFIX ?= $(GLOBAL_ROOT)
ANDROID_EXPORT_PATH := $(if $(LOCAL_ROOT),,$(GLOBAL_ROOT)/)$(LOCAL_OUTDIR)/android

android_lib_list = \
	$(foreach lib,$(filter %.a,$(1)),$(2)_$(basename $(subst -,_,$(notdir $(lib))))_generic)

android_lib_defs = \
	$(foreach lib,$(1),\n\ninclude $$(CLEAR_VARS)\nLOCAL_MODULE := $(2)_$(basename $(subst -,_,$(notdir $(lib))))_generic\nLOCAL_SRC_FILES := $(abspath $(lib))\ninclude $$(PREBUILT_STATIC_LIBRARY))

android_filter_libs = \
	$(filter %.a,$(1))

$(ANDROID_EXPORT_PATH)/Android.mk.tmp:
	@$(GLOBAL_MKDIR) $(ANDROID_EXPORT_PATH)
	@echo '# Autogenerated by makefile' > $@
	@echo 'include $$(CLEAR_VARS)' >> $@
	@echo 'LOCAL_MODULE := stappler_application_generic' >> $@
	@echo 'LOCAL_CFLAGS := -DANDROID -DUSE_FILE32API -DSTAPPLER $(TOOLKIT_GENERAL_CFLAGS) $(TOOLKIT_LIB_CFLAGS)' >> $@
	@echo 'LOCAL_EXPORT_LDLIBS := -llog -lz -landroid' >> $@
	@echo -n 'LOCAL_SRC_FILES :=' >> $@
	@for file in $(realpath $(BUILD_LIB_SRCS)); do \
		printf " \\\\\n\t$$file" >> $@; \
	done
	@echo '' >> $@
	@echo -n 'LOCAL_C_INCLUDES :=' >> $@
	@for file in $(realpath $(BUILD_INCLUDES)) $(TOOLKIT_INCLUDES); do \
		printf " \\\\\n\t$$file" >> $@; \
	done
	@echo ' \\' >> $@
	@echo '\t$(BUILD_SHADERS_TARGET_INCLUDE_DIR) \\' >> $@
	@echo '\t$(TOOLKIT_SHADERS_TARGET_INCLUDE_DIR) \\' >> $@
	@echo '\t$(abspath $(GLOBAL_ROOT)/$(OSTYPE_INCLUDE))' >> $@
	@echo 'LOCAL_WHOLE_STATIC_LIBRARIES := cpufeatures $(call android_lib_list,$(sort $(TOOLKIT_LIBS)),build)' >> $@
	@echo 'include $$(BUILD_STATIC_LIBRARY)' >> $@
	@echo '$(call android_lib_defs,$(call android_filter_libs,$(sort $(TOOLKIT_LIBS))),build)' >> $@
	@echo '' >> $@
	@echo '$$(call import-module,android/cpufeatures)' >> $@

android-export: $(ANDROID_EXPORT_PATH)/Android.mk.tmp
	@if cmp -s "$(ANDROID_EXPORT_PATH)/Android.mk.tmp" "$(ANDROID_EXPORT_PATH)/Android.mk" ; then\
		echo "$(ANDROID_EXPORT_PATH)/Android.mk is up to date"; \
		$(GLOBAL_RM) $(ANDROID_EXPORT_PATH)/Android.mk.tmp; \
	else \
		$(GLOBAL_RM) $(ANDROID_EXPORT_PATH)/Android.mk; \
		mv $(ANDROID_EXPORT_PATH)/Android.mk.tmp $(ANDROID_EXPORT_PATH)/Android.mk; \
		touch $(ANDROID_EXPORT_PATH)/Android.mk; \
		echo "$(ANDROID_EXPORT_PATH)/Android.mk was updated"; \
	fi

.PHONY: android android-clean android-export
