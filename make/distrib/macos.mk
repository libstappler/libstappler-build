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

MACOS_PROJECT_DIR := $(addsuffix proj.macos,$(dir $(realpath $(LOCAL_MAKEFILE))))

MACOS_CONSUMED_MODULES := $(sort $(foreach module,$(LOCAL_MODULES),$($(MODULE_$(module))_SHARED_CONSUME)))

ifdef LOCAL_EXPORT_MODULES
MACOS_MODULES := $(addsuffix .xcconfig,$(addprefix $(MACOS_PROJECT_DIR)/,\
	$(filter $(LOCAL_EXPORT_MODULES),$(filter-out $(MACOS_CONSUMED_MODULES),$(LOCAL_MODULES)))))
else
MACOS_MODULES := $(addsuffix .xcconfig,$(addprefix $(MACOS_PROJECT_DIR)/,\
	$(filter-out $(MACOS_CONSUMED_MODULES),$(LOCAL_MODULES))))
endif

MACOS_CONSUMED_LDFLAGS := $(foreach module,$(MACOS_CONSUMED_MODULES),$($(MODULE_$(module))_GENERAL_LDFLAGS))

sp_relpath_config = $(shell (echo "import os"; echo "print(os.path.relpath('$(abspath $(1))', '$(MACOS_PROJECT_DIR)'))" )| python3)

MACOS_GENERAL_CFLAGS := \
	$(OSTYPE_GENERAL_CFLAGS) \
	-DSTAPPLER -DSTAPPLER_SHARED \
	$(TOOLKIT_GENERAL_CFLAGS) \
	$(LOCAL_CFLAGS)

MACOS_GENERAL_CXXFLAGS := \
	$(OSTYPE_GENERAL_CXXFLAGS) \
	-DSTAPPLER -DSTAPPLER_SHARED \
	$(TOOLKIT_GENERAL_CXXFLAGS) \
	$(LOCAL_CXXFLAGS)

MACOS_EXEC_CFLAGS := \
	$(GLOBAL_EXEC_CFLAGS) \
	$(TOOLKIT_EXEC_CFLAGS)

MACOS_EXEC_CXXFLAGS := \
	$(GLOBAL_EXEC_CXXFLAGS) \
	$(TOOLKIT_EXEC_CXXFLAGS)

MACOS_LIB_CFLAGS := \
	$(GLOBAL_LIB_CFLAGS) \
	$(TOOLKIT_LIB_CFLAGS)

MACOS_LIB_CXXFLAGS := \
	$(GLOBAL_LIB_CXXFLAGS) \
	$(TOOLKIT_LIB_CXXFLAGS)

MACOS_GENERAL_LDFLAGS := \
	$(GLOBAL_GENERAL_LDFLAGS) \
	$(TOOLKIT_GENERAL_LDFLAGS) \
	$(LOCAL_LDFLAGS) \
	$(MACOS_CONSUMED_LDFLAGS)

MACOS_EXEC_LDFLAGS := \
	$(GLOBAL_EXEC_LDFLAGS) \
	$(TOOLKIT_EXEC_LDFLAGS)

MACOS_LIB_LDFLAGS := \
	$(GLOBAL_LIB_LDFLAGS) \
	$(TOOLKIT_LIB_LDFLAGS) \
	$(if $(filter-out $(LOCAL_BUILD_SHARED),1),$(OSTYPE_STANDALONE_LDFLAGS))

MACOS_HEADER_SEARCH_PATHS := \
	/usr/local/include \
	$(foreach include,$(TOOLKIT_INCLUDES),$(call sp_relpath_config, $(include))) \
	$(call sp_relpath_config,$(GLOBAL_ROOT)/deps/mac)/$$(CURRENT_ARCH)/include  \
	$(foreach include,$(BUILD_SHADERS_TARGET_INCLUDE_ALL),$(call sp_relpath_config, $(include)))

MACOS_LIBRARY_SEARCH_PATHS := /usr/local/lib $(addsuffix /$$(CURRENT_ARCH)/lib,$(call sp_relpath_config,$(GLOBAL_ROOT)/deps/mac))

MACOS_LIBS := $(call sp_toolkit_transform_lib_ldflag, $(TOOLKIT_LIBS))

$(MACOS_PROJECT_DIR)/%.xcconfig:
	@$(GLOBAL_MKDIR) $(dir $@)
	@echo '// Autogenerated by makefile' > $@
	@echo 'STAPPLER_MODULE_NAME = $*' >> $@
	@echo 'STAPPLER_MODULES_ENABLED = $(foreach module,$(GLOBAL_MODULES),$(MODULE_$(module)))' >> $@
	@echo 'STAPPLER_MODULES_CONSUMED = $($(MODULE_$*)_SHARED_CONSUME)' >> $@
	@echo 'STAPPLER_MACOS_GENERAL_CFLAGS = $(MACOS_GENERAL_CFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_GENERAL_CXXFLAGS = $(MACOS_GENERAL_CXXFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_GENERAL_LDFLAGS = $($(MODULE_$*)_GENERAL_LDFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_CONDUMED_LDFLAGS = $(foreach module,$($(MODULE_$*)_SHARED_CONSUME),$($(MODULE_$(module))_GENERAL_LDFLAGS))' >> $@
	@echo 'STAPPLER_MACOS_EXEC_CFLAGS = $(MACOS_EXEC_CFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_EXEC_CXXFLAGS = $(MACOS_EXEC_CXXFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_LIB_CFLAGS = $(MACOS_LIB_CFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_LIB_CXXFLAGS = $(MACOS_LIB_CXXFLAGS)' >> $@
	@echo 'OTHER_LDFLAGS = $(GLOBAL_GENERAL_LDFLAGS) $(LOCAL_LDFLAGS) $(call sp_toolkit_transform_lib_ldflag, $($(MODULE_$*)_LIBS))' >> $@
	@echo 'OTHER_LIBTOOLFLAGS = $(call sp_toolkit_transform_lib_ldflag, $($(MODULE_$*)_LIBS) $(foreach module,$($(MODULE_$*)_SHARED_CONSUME),$($(MODULE_$(module))_LIBS)))' >> $@
	@echo 'OTHER_CFLAGS = $$(STAPPLER_MACOS_GENERAL_CFLAGS)' >> $@
	@echo 'OTHER_CPLUSPLUSFLAGS = $$(STAPPLER_MACOS_GENERAL_CXXFLAGS)' >> $@
	@echo 'HEADER_SEARCH_PATHS = $(MACOS_HEADER_SEARCH_PATHS)' >> $@
	@echo 'LIBRARY_SEARCH_PATHS = $(MACOS_LIBRARY_SEARCH_PATHS)' >> $@
	@echo 'SDKROOT = macOS' >> $@
	@echo 'SUPPORTED_PLATFORMS = macosx' >> $@
	@echo 'GCC_PREPROCESSOR_DEFINITIONS[config=Debug] = DEBUG=1' >> $@
	@echo 'GCC_PREPROCESSOR_DEFINITIONS[config=Release] = NDEBUG=1' >> $@
	@echo 'MACOSX_DEPLOYMENT_TARGET = $(MACOSX_DEPLOYMENT_TARGET)' >> $@
	@echo 'CLANG_CXX_LANGUAGE_STANDARD = $(GLOBAL_STDXX)' >> $@
	@echo 'GCC_C_LANGUAGE_STANDARD = $(GLOBAL_STD)' >> $@
	@echo 'MACH_O_TYPE = staticlib' >> $@
	@echo 'MAKE_MERGEABLE = YES' >> $@
    @echo 'MERGEABLE_LIBRARY = YES' >> $@
    @echo 'ONLY_ACTIVE_ARCH = NO' >> $@

$(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig.tmp:
	@$(GLOBAL_MKDIR) $(dir $@)
	@echo '// Autogenerated by makefile' > $@
	@echo 'STAPPLER_SRCS = $(foreach include,$(TOOLKIT_SRCS),$(call sp_relpath_config, $(include)))' >> $@
	@echo 'STAPPLER_MODULES_ENABLED = $(foreach module,$(GLOBAL_MODULES),$(MODULE_$(module)))' >> $@
	@echo 'STAPPLER_MODULES_DEFS = $(foreach module,$(GLOBAL_MODULES),-D$(MODULE_$(module)))' >> $@
	@echo 'STAPPLER_MACOS_GENERAL_CFLAGS = $(MACOS_GENERAL_CFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_GENERAL_CXXFLAGS = $(MACOS_GENERAL_CXXFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_GENERAL_LDFLAGS = $(MACOS_GENERAL_LDFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_EXEC_CFLAGS = $(MACOS_EXEC_CFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_EXEC_CXXFLAGS = $(MACOS_EXEC_CXXFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_EXEC_LDFLAGS = $(MACOS_EXEC_LDFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_LIB_CFLAGS = $(MACOS_LIB_CFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_LIB_CXXFLAGS = $(MACOS_LIB_CXXFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_LIB_LDFLAGS = $(MACOS_LIB_LDFLAGS)' >> $@
	@echo 'STAPPLER_MACOS_LIBS = $(MACOS_LIBS)' >> $@
	@echo 'STAPPLER_MACOS_SHADERS = $(sort $(foreach include,$(BUILD_SHADERS_EMBEDDED) $(TOOLKIT_SHADERS_EMBEDDED),$(call sp_relpath_config, $(include))))' >> $@
	@echo 'SUPPORTED_PLATFORMS = macosx' >> $@
	@echo 'OTHER_LDFLAGS = $$(STAPPLER_MACOS_GENERAL_LDFLAGS)' >> $@
	@echo 'OTHER_LIBTOOLFLAGS = $$(STAPPLER_MACOS_LIBS)' >> $@
	@echo 'OTHER_CFLAGS = $$(STAPPLER_MACOS_GENERAL_CFLAGS)' >> $@
	@echo 'OTHER_CPLUSPLUSFLAGS = $$(STAPPLER_MACOS_GENERAL_CXXFLAGS)' >> $@
	@echo 'GCC_PREPROCESSOR_DEFINITIONS[config=Debug] = DEBUG=1' >> $@
	@echo 'GCC_PREPROCESSOR_DEFINITIONS[config=Release] = NDEBUG=1' >> $@
	@echo 'MACOSX_DEPLOYMENT_TARGET = $(MACOSX_DEPLOYMENT_TARGET)' >> $@
	@echo 'HEADER_SEARCH_PATHS = $(MACOS_HEADER_SEARCH_PATHS)' >> $@
	@echo 'LIBRARY_SEARCH_PATHS = $(MACOS_LIBRARY_SEARCH_PATHS)' >> $@
	@echo 'CLANG_CXX_LANGUAGE_STANDARD = $(GLOBAL_STDXX)' >> $@
	@echo 'GCC_C_LANGUAGE_STANDARD = $(GLOBAL_STD)' >> $@

mac-export: $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig.tmp $(BUILD_SHADERS_EMBEDDED) $(TOOLKIT_SHADERS_EMBEDDED)
	@if cmp -s "$(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig.tmp" "$(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig" ; then\
		echo "[OSConfig:Darwin] $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig is up to date"; \
		$(GLOBAL_RM) $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig.tmp; \
	else \
		$(GLOBAL_RM) $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig; \
		mv $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig.tmp $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig; \
		touch $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig; \
		echo "[OSConfig:Darwin] $(MACOS_PROJECT_DIR)/macos.projectconfig.xcconfig was updated"; \
	fi

mac-shaders: $(BUILD_SHADERS_EMBEDDED) $(TOOLKIT_SHADERS_EMBEDDED)

mac-modules: $(MACOS_MODULES) mac-export

.PHONY: mac-export mac-shaders mac-modules