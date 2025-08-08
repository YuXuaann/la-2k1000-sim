# General config
PROJECT := NoAxiom
MODE := release
KERNEL := kernel
TEST_TYPE := official
ARCH_NAME := loongarch64
TARGET := loongarch64-unknown-linux-gnu
ROOT := $(shell pwd)/../..

# for qemu
export DEBUG_UNALIGN=1

ERROR := "\e[31m"
WARN := "\e[33m"
NORMAL := "\e[32m"
RESET := "\e[0m"
RELEASE ?= false

TARGET_DIR := $(ROOT)/$(PROJECT)/target/$(TARGET)/$(MODE)
TEST_DIR := $(ROOT)/$(PROJECT)-OS-Test
KERNEL_ELF := $(TARGET_DIR)/$(KERNEL)
KERNEL_BIN := $(KERNEL_ELF).bin
KERNEL_UIMG := $(ROOT)/$(KERNEL)-la-uimage
FS_IMG := $(TEST_DIR)/$(TEST_TYPE)/tmp-img/fs-$(ARCH_NAME).fs.img
IMG_DIR := $(ROOT)/NoAxiom-OS-Utils/easy-fs-fuse
U_IMG := $(IMG_DIR)/uImage
IMG_NAME = rootfs.img
IMG := ${IMG_DIR}/$(IMG_NAME)
IMG_LN = $(shell readlink -f $(IMG_DIR))/$(IMG_NAME)
QEMU_2k1000_DIR := $(shell pwd)

LA_ENTRY_POINT = 0x9000000090000000
LA_LOAD_ADDR = 0x9000000090000000

BUILD_ARGS=ARCH_NAME=loongarch64 RELEASE=true FEAT_ON_QEMU=false

default: img uimage run

img:
	@mkdir -p $(IMG_DIR)
	@echo $(NORMAL)"[2k-1000 Test] Building filesystem image..."$(RESET)
	@cp $(FS_IMG) $(IMG)
# ./buildfs.sh "$(IMG)" "laqemu" $(MODE)

uimage:
	@echo $(NORMAL)"[2k-1000 Test] Building uImage..."$(RESET)
	./mkimage -A loongarch -O linux -T kernel -C none -a $(LA_LOAD_ADDR) -e $(LA_ENTRY_POINT) -n NoAxiom -d $(KERNEL_BIN) $(KERNEL_UIMG)
	@if [ -f $(U_IMG) ]; then rm $(U_IMG); fi
	@cp -f $(KERNEL_UIMG) $(U_IMG)

ON_SCREEN ?= true
LOG_DIR := ${shell pwd}/log
LOG_FILE := ${LOG_DIR}/$(shell date +%m_%d-%H_%M).log
RUN_OPTION :=
ifeq ($(ON_SCREEN),true)
RUN_OPTION += | tee $(LOG_FILE)
else ifeq ($(ON_SCREEN),false)
RUN_OPTION += > $(LOG_FILE)
endif

run:
	if [ -L $(QEMU_2k1000_DIR)/$(IMG_NAME) ]; then rm $(QEMU_2k1000_DIR)/$(IMG_NAME); fi
	ln -s $(IMG_LN) $(QEMU_2k1000_DIR)/$(IMG_NAME)
	@echo "========WARNING!========"
	@echo "The next command is expecting a modified runqemu2k1000 script where any potential and implicit \"current working directory\" has been replaced by a generated script storage path."
	mkdir -p ${LOG_DIR}
	@echo "log is saved to ${LOG_FILE}"
	./run_script ./runqemu2k1000 ${RUN_OPTION}
	@echo "log is saved to ${LOG_FILE}"