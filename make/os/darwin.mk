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

ifeq ($(UNAME),Darwin)

ifndef MACOS_ARCH
MACOS_ARCH := $(shell arch)
endif

OS_VERSION_TARGET := 11.0

OSTYPE_PREBUILT_PATH := libs/mac/$(MACOS_ARCH)/lib
OSTYPE_INCLUDE :=  libs/mac/$(MACOS_ARCH)/include
OSTYPE_CFLAGS := -DMACOS -DUSE_FILE32API -Wall -fPIC -Wno-missing-braces \
		-Wno-gnu-string-literal-operator-template -mmacosx-version-min=$(OS_VERSION_TARGET)
OSTYPE_CPPFLAGS :=  -frtti -Wno-unneeded-internal-declaration

OSTYPE_COMMON_LIBS :=

OSTYPE_LDFLAGS := -mmacosx-version-min=$(OS_VERSION_TARGET)
OSTYPE_EXEC_FLAGS := -mmacosx-version-min=$(OS_VERSION_TARGET)
CLANG := 1
BUILD_OBJC := 1
RESOLVE_LIBS_REALPATH := 1

OSTYPE_XCCONFIG_DIR = $(realpath .)

#sp_relpath = $(info echo $(1) $(2))
sp_relpath_config = $(shell (echo "import os"; echo "print(os.path.relpath('$(abspath $(1))', '$(OSTYPE_XCCONFIG_DIR)'))" )| python3)

$(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig.tmp:
	@echo '// Autogenerated by makefile' > $@
	@echo 'PROJECT_INCLUDES = $(foreach include,$(BUILD_INCLUDES),$(call sp_relpath_config, $(include)))' >> $@
	@echo 'TOOLKIT_INCLUDES = $(foreach include,$(TOOLKIT_INCLUDES),$(call sp_relpath_config, $(include)))' >> $@
	@echo 'LIB_INCLUDES =  $(call sp_relpath_config, $(GLOBAL_ROOT)/libs/mac)/$$(CURRENT_ARCH)/include' >> $@
	@echo 'PROJECT_SRCS = $(foreach include,$(BUILD_SRCS),$(call sp_relpath_config, $(include)))' >> $@
	@echo 'TOOLKIT_SRCS = $(foreach include,$(TOOLKIT_SRCS),$(call sp_relpath_config, $(include)))' >> $@
	@echo 'MODULES_ENABLED = $(foreach module,$(GLOBAL_MODULES),$(MODULE_$(module)))' >> $@
	@echo 'MODULES_DEFS = $(foreach module,$(GLOBAL_MODULES),-D$(MODULE_$(module)))' >> $@

mac-export: $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig.tmp
	@if cmp -s "$(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig.tmp" "$(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig" ; then\
		echo "[OSConfig:Darwin] $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig is up to date"; \
		$(GLOBAL_RM) $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig.tmp; \
	else \
		$(GLOBAL_RM) $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig; \
		mv $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig.tmp $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig; \
		touch $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig; \
		echo "[OSConfig:Darwin] $(OSTYPE_XCCONFIG_DIR)/macos.projectconfig.xcconfig was updated"; \
	fi

.PHONY: mac-export

endif