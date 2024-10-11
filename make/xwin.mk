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

.DEFAULT_GOAL := all

BUILD_XWIN := 1
XWIN := 1
WIN32 := 1

BUILD_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

include $(BUILD_ROOT)/general/compile.mk

all: $(BUILD_SHARED_LIBRARY) $(BUILD_EXECUTABLE) $(BUILD_STATIC_LIBRARY)

ifdef LOCAL_FORCE_INSTALL
all: install
endif

$(BUILD_EXECUTABLE) : $(BUILD_EXEC_OBJS) $(BUILD_WASM_OUTPUT)
	$(GLOBAL_QUIET_LINK) $(GLOBAL_CPP) $(BUILD_EXEC_OBJS) $(BUILD_EXEC_LDFLAGS) -o $(BUILD_EXECUTABLE)

$(BUILD_SHARED_LIBRARY): $(BUILD_LIB_OBJS) $(BUILD_WASM_OUTPUT)
	$(GLOBAL_QUIET_LINK) $(GLOBAL_CPP) -shared $(BUILD_LIB_OBJS) $(BUILD_LIB_LDFLAGS) -o $(BUILD_SHARED_LIBRARY)

$(BUILD_STATIC_LIBRARY): $(BUILD_LIB_OBJS) $(BUILD_WASM_OUTPUT)
	$(GLOBAL_QUIET_LINK) $(GLOBAL_AR) $(BUILD_STATIC_LIBRARY) $(BUILD_LIB_OBJS)

$(BUILD_INSTALL_SHARED_LIBRARY): $(BUILD_SHARED_LIBRARY)
	@$(GLOBAL_MKDIR) $(dir $(BUILD_INSTALL_SHARED_LIBRARY))
	$(GLOBAL_CP) $(BUILD_SHARED_LIBRARY) $(BUILD_INSTALL_SHARED_LIBRARY)

$(BUILD_INSTALL_STATIC_LIBRARY): $(BUILD_STATIC_LIBRARY)
	@$(GLOBAL_MKDIR) $(dir $(BUILD_INSTALL_STATIC_LIBRARY))
	$(GLOBAL_CP) $(BUILD_STATIC_LIBRARY) $(BUILD_INSTALL_STATIC_LIBRARY)

$(BUILD_INSTALL_EXECUTABLE): $(BUILD_EXECUTABLE) $(BUILD_EXECUTABLE_DSYM_GOAL)
	@$(GLOBAL_MKDIR) $(dir $(BUILD_INSTALL_EXECUTABLE))
	$(GLOBAL_CP) $(BUILD_EXECUTABLE) $(BUILD_INSTALL_EXECUTABLE)

$(BUILD_INSTALL_WASM_MODULE): $(BUILD_WASM_MODULE)
	@$(GLOBAL_MKDIR) $(dir $(BUILD_INSTALL_WASM_MODULE))
	$(GLOBAL_CP) $(BUILD_WASM_MODULE) $(BUILD_INSTALL_WASM_MODULE)

install: $(BUILD_INSTALL_SHARED_LIBRARY) $(BUILD_INSTALL_EXECUTABLE) $(BUILD_INSTALL_STATIC_LIBRARY)

clean:
	$(GLOBAL_RM) -r $(BUILD_С_OUTDIR) $(BUILD_SHADERS_OUTDIR)

.PHONY: all install clean

