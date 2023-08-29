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

BUILD_SHADERS_SRCS := $(realpath $(foreach dir,$(LOCAL_SHADERS_DIR),$(wildcard $(dir)/*/*)))
BUILD_SHADERS_COMPILED := $(addprefix $(BUILD_SHADERS_OUTDIR)/compiled,$(BUILD_SHADERS_SRCS))
BUILD_SHADERS_LINKED := $(addprefix $(BUILD_SHADERS_OUTDIR)/linked,$(realpath $(foreach dir,$(LOCAL_SHADERS_DIR),$(wildcard $(dir)/*))))
BUILD_SHADERS_EMBEDDED := $(addprefix $(BUILD_SHADERS_OUTDIR)/embedded,$(realpath $(foreach dir,$(LOCAL_SHADERS_DIR),$(wildcard $(dir)/*))))
BUILD_SHADERS_TARGET_INCLUDE_DIR := $(abspath $(addprefix $(BUILD_SHADERS_OUTDIR)/embedded,$(realpath $(LOCAL_SHADERS_DIR))))
BUILD_SHADERS_TARGET_INCLUDE := $(addprefix -I,$(BUILD_SHADERS_TARGET_INCLUDE_DIR))

BUILD_SHADERS_INCLUDE = $(addprefix -I,$(realpath $(LOCAL_SHADERS_INCLUDE) $(TOOLKIT_SHADERS_INCLUDE)))

$(BUILD_SHADERS_OUTDIR)/compiled/% : /%
	$(call sp_compile_glsl)

$(BUILD_SHADERS_OUTDIR)/linked/% : $(BUILD_SHADERS_COMPILED) $(TOOLKIT_SHADERS_COMPILED)
	$(call sp_link_spirv)

$(BUILD_SHADERS_OUTDIR)/embedded/% : $(BUILD_SHADERS_OUTDIR)/linked/%
	$(call sp_embed_spirv)
