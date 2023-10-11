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

.DEFAULT_GOAL := all
IS_LOCAL_BUILD := 1

BUILD_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

LOCAL_ROOT ?= .

BUILD_OUTDIR := $(LOCAL_OUTDIR)/host
LOCAL_INSTALL_DIR ?= $(LOCAL_OUTDIR)/host

GLOBAL_ROOT := $(STAPPLER_ROOT)
GLOBAL_OUTPUT := $(BUILD_OUTDIR)

include $(BUILD_ROOT)/compiler/compiler.mk

ifdef LOCAL_LIBRARY
BUILD_STATIC_LIBRARY := $(BUILD_OUTDIR)/$(LOCAL_LIBRARY).a
BUILD_INSTALL_STATIC_LIBRARY := $(LOCAL_INSTALL_DIR)/$(LOCAL_LIBRARY).a
BUILD_SHARED_LIBRARY := $(BUILD_OUTDIR)/$(LOCAL_LIBRARY).so
BUILD_INSTALL_SHARED_LIBRARY := $(LOCAL_INSTALL_DIR)/$(LOCAL_LIBRARY).so
endif

ifdef LOCAL_EXECUTABLE
BUILD_EXECUTABLE := $(BUILD_OUTDIR)/$(LOCAL_EXECUTABLE)$(OSTYPE_EXEC_SUFFIX)
BUILD_INSTALL_EXECUTABLE := $(LOCAL_INSTALL_DIR)/$(LOCAL_EXECUTABLE)$(OSTYPE_EXEC_SUFFIX)
endif

include $(BUILD_ROOT)/compiler/apply.mk

all: $(BUILD_SHARED_LIBRARY) $(BUILD_EXECUTABLE) $(BUILD_STATIC_LIBRARY) $(BUILD_EXECUTABLE_DSYM_GOAL)

ifdef LOCAL_FORCE_INSTALL
all: install
endif

$(BUILD_EXECUTABLE) : $(BUILD_OBJS) $(BUILD_MAIN_OBJ)
	$(GLOBAL_QUIET_LINK) $(GLOBAL_CPP) $(BUILD_OBJS) $(BUILD_MAIN_OBJ) $(BUILD_LIBS) $(OSTYPE_EXEC_FLAGS) -o $(BUILD_EXECUTABLE)

ifdef MACOS_ARCH
ifneq ($(RELEASE),1)
ifdef BUILD_EXECUTABLE
BUILD_EXECUTABLE_DSYM := $(BUILD_EXECUTABLE).dSYM

# Цель должна указывать на конкретный файл, чтобы сравнить даты создания
BUILD_EXECUTABLE_DSYM_GOAL := $(BUILD_EXECUTABLE_DSYM)/Contents/Resources/DWARF/$(notdir $(BUILD_EXECUTABLE))

$(BUILD_EXECUTABLE_DSYM_GOAL) : $(BUILD_EXECUTABLE)
	dsymutil $(BUILD_EXECUTABLE) -o $(BUILD_EXECUTABLE_DSYM)
endif
endif

all: mac-export
install: mac-export
endif

$(BUILD_SHARED_LIBRARY): $(BUILD_OBJS)
	$(GLOBAL_QUIET_LINK) $(GLOBAL_CPP) -shared  $(BUILD_OBJS) $(BUILD_LIBS) $(BUILD_LIB_FLAGS) $(OSTYPE_EXEC_FLAGS) -o $(BUILD_SHARED_LIBRARY)

$(BUILD_STATIC_LIBRARY): $(BUILD_OBJS)
	$(GLOBAL_QUIET_LINK) $(GLOBAL_AR) $(BUILD_STATIC_LIBRARY) $(BUILD_OBJS)

$(BUILD_INSTALL_SHARED_LIBRARY): $(BUILD_SHARED_LIBRARY)
	@$(GLOBAL_MKDIR) $(dir $(BUILD_INSTALL_SHARED_LIBRARY))
	$(GLOBAL_CP) $(BUILD_SHARED_LIBRARY) $(BUILD_INSTALL_SHARED_LIBRARY)

$(BUILD_INSTALL_EXECUTABLE): $(BUILD_EXECUTABLE) $(BUILD_EXECUTABLE_DSYM_GOAL)
	@$(GLOBAL_MKDIR) $(dir $(BUILD_INSTALL_EXECUTABLE))
	$(GLOBAL_CP) $(BUILD_EXECUTABLE) $(BUILD_INSTALL_EXECUTABLE)

report: $(BUILD_OBJS) $(BUILD_EXECUTABLE)
	$(BUILD_EXECUTABLE)
	$(GLOBAL_MKDIR) $(BUILD_OUTDIR)/gcov
	lcov --capture --directory . --output-file $(BUILD_OUTDIR)/gcov/coverage.info \
		--exclude '/usr/include/*' --exclude '/usr/lib/*' \
		--exclude $(realpath $(STAPPLER_ROOT))/'libs/*' \
		--exclude $(realpath $(STAPPLER_ROOT))/'tests/*' \
		--exclude $(realpath $(STAPPLER_ROOT))/'thirdparty/*'
	genhtml $(BUILD_OUTDIR)/gcov/coverage.info --output-directory $(BUILD_OUTDIR)/html

install: $(BUILD_INSTALL_SHARED_LIBRARY) $(BUILD_INSTALL_EXECUTABLE) $(BUILD_INSTALL_STATIC_LIBRARY)

clean:
	$(GLOBAL_RM) -r $(BUILD_OUTDIR) $(BUILD_SHADERS_OUTDIR)

.PHONY: all report install clean

#ifeq ($(UNAME),Msys)
#
#define LOCAL_make_dep_rule
#$(1): $(call sp_make_dep,$(1))
#endef

#$(foreach target,$(BUILD_LOCAL_OBJS),$(eval $(call LOCAL_make_dep_rule,$(target))))

#.INTERMEDIATE: $(subst /,_,$(BUILD_LOCAL_OBJS))

#$(subst /,_,$(BUILD_LOCAL_OBJS)):
#	@touch $@

#endif
