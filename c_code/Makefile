# linux下使用/bin/dash，echo -e 会将 -e 输出，windows下可删除此行
SHELL = /bin/bash

# 根据CPU的核心数提升编译速度
MAKEFLAGS := -j $(shell nproc)

# 设置中间文件路径和目标文件名称
BUILD_DIR := ./build/
TARGET := ./execute.exe

# 设置编译工具链路径和编译器路径
TOOLCHAIN_DIR := D:/workspace/path/w64devkit/
COMPILER_PATH := $(TOOLCHAIN_DIR)bin/

# 设置编译器
CC      := $(COMPILER_PATH)gcc
CX      := $(COMPILER_PATH)g++
LD      := $(COMPILER_PATH)g++
SZ      := $(COMPILER_PATH)size
AR      := $(COMPILER_PATH)ar
OBJCOPY := $(COMPILER_PATH)objcopy

# 设置编译器标志
CC_MARK := .xc
CX_MARK := .xc++
DEFINES :=
CC_FLAG := -xc -g $(DEFINES)
CX_FLAG := -xc++ -g $(DEFINES)
LD_FLAG :=
# LD_FLAG := -shared -fPIC

# 设置自定义源文件列表
HEAD_PATH :=
LIB_PATH :=
LIB_FLAG := -lpthread
SRC_LIB :=
SRC_CC :=
SRC_CX :=

# 设置自动搜索源文件格式
HEAD_TYPE := .h .hpp .hh
LIB_TYPE := .a .so
CC_TYPE := .c
CX_TYPE := .cpp
EXCLUDE_FILES :=

HEAD_TYPE_SIFT := $(patsubst .%,%,$(subst $(empty) .,\|,$(HEAD_TYPE)))
LIB_TYPE_SIFT := $(patsubst .%,%,$(subst $(empty) .,\|,$(LIB_TYPE)))
CC_TYPE_SIFT := $(patsubst .%,%,$(subst $(empty) .,\|,$(CC_TYPE)))
CX_TYPE_SIFT := $(patsubst .%,%,$(subst $(empty) .,\|,$(CX_TYPE)))

LOCAL_HEAD := $(shell find . -type f -regex ".*\.\($(HEAD_TYPE_SIFT)\)" -printf "%P ")
LOCAL_LIB := $(shell find . -type f -regex ".*\.\($(LIB_TYPE_SIFT)\)" -printf "%P ")
LOCAL_CC := $(shell find . -type f -regex ".*\.\($(CC_TYPE_SIFT)\)" -printf "%P ")
LOCAL_CX := $(shell find . -type f -regex ".*\.\($(CX_TYPE_SIFT)\)" -printf "%P ")

# 增加前缀并去重
HEAD_PATH += $(sort $(dir $(filter-out $(EXCLUDE_FILES),$(LOCAL_HEAD))))
SRC_LIB += $(sort $(filter-out $(EXCLUDE_FILES),$(LOCAL_LIB)))
SRC_CC += $(sort $(filter-out $(EXCLUDE_FILES),$(LOCAL_CC)))
SRC_CX += $(sort $(filter-out $(EXCLUDE_FILES),$(LOCAL_CX)))

# 生成中间文件列表
OBJ_CC := $(addprefix $(BUILD_DIR),$(notdir $(SRC_CC:%=%$(CC_MARK).o)))
OBJ_CX := $(addprefix $(BUILD_DIR),$(notdir $(SRC_CX:%=%$(CX_MARK).o)))

# 设置源文件查找路径
vpath $(addprefix %,$(CC_TYPE)) $(sort $(dir $(SRC_CC)))
vpath $(addprefix %,$(CX_TYPE)) $(sort $(dir $(SRC_CX)))

# 定义all依赖
all : $(TARGET) | Makefile
	@echo "  CHECK     $<"
	@$(SZ) $<

# 包含依赖文件
-include $(wildcard $(BUILD_DIR)*.d)

# 定义编译和链接命令和规则
$(TARGET) : $(OBJ_CC) $(OBJ_CX) $(SRC_LIB)
	@echo "  LN   $^ -> $@"
	@$(LD) $(LD_FLAG) -o $@ $^ $(addprefix -L,$(LIB_PATH)) $(LIB_FLAG) $(SRC_LIB)
# @$(AR) x $(SRC_LIB) --output=$(BUILD_DIR)
# @$(AR) $(AR_FLAG) rcs $@ $^

# 定义隐式规则
$(BUILD_DIR)%$(CC_MARK).o : % | $(BUILD_DIR)
	@echo "  CC   $<"
	@$(CC) $(CC_FLAG) $(addprefix -I,$(HEAD_PATH)) -MMD -MP -MF"$(@:%.o=%.d)" -c $< -o $@

$(BUILD_DIR)%$(CX_MARK).o : % | $(BUILD_DIR)
	@echo "  CX   $<"
	@$(CX) $(CX_FLAG) $(addprefix -I,$(HEAD_PATH)) -MMD -MP -MF"$(@:%.o=%.d)" -c $< -o $@

# 生成build目录
$(BUILD_DIR) :
	@echo "  MK   $@"
	@mkdir $@

# 定义生成compile_commands.json文件的规则
json: $(SRC_CC) $(SRC_CX)
	@echo "Generating compile_commands.json"
	@rm -f compile_commands.json
	@echo "[" > compile_commands.json
	@for file in $(SRC_CC); do \
		compile_cmd="$(CC) $(CC_FLAG) $(addprefix -I,$(HEAD_PATH)) -c $${file} -o $(addprefix $(BUILD_DIR),$$(basename $${file}$(CC_MARK).o))" \
		command_json=" { \"arguments\": [ \"$$compile_cmd\" ], \"directory\": \"${PWD}\", \"file\": \"$$file\" },"; \
		echo -e "$$command_json" >> compile_commands.json ; \
	done
	@for file in $(SRC_CX); do \
		compile_cmd="$(CX) $(CX_FLAG) $(addprefix -I,$(HEAD_PATH)) -c $${file} -o $(addprefix $(BUILD_DIR),$$(basename $${file}$(CX_MARK).o))" \
		command_json=" { \"arguments\": [ \"$$compile_cmd\" ], \"directory\": \"${PWD}\", \"file\": \"$$file\" },"; \
		echo -e "$$command_json" >> compile_commands.json ; \
	done
	@sed -i '$$ s/,$$/\n]/' compile_commands.json

# 定义清理规则
clean:
	rm -fR $(BUILD_DIR) $(TARGET)

# 定义伪目标
.PHONY: all clean json debug

# 定义调试输出
debug:
	@echo "LOCAL_CX: $(LOCAL_CX)"
	@echo "SRC_CX: $(SRC_CX)"