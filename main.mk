MAKEFLAGS += -rR --no-print-directory --include-dir=$(EXPRESSOS_SRC_DIR)
export MAKEFLAGS

VPATH := $(EXPRESSOS_SRC_DIR)

include $(EXPRESSOS_SRC_DIR)/build/definition.mk

EXPRESSOS_TARGET_CONFIG_DIR := $(EXPRESSOS_SRC_DIR)/build/target/$(EXPRESSOS_TARGET)
include $(EXPRESSOS_TARGET_CONFIG_DIR)/config.mk
export EXPRESSOS_TARGET_CONFIG_DIR L4RE_VARIANT TARGET_TRIPLE

ifeq ($(V),1)
  quiet :=
  Q :=
else
  quiet := quiet-
  Q := @
endif

export quiet Q
export VPATH EXPRESSOS_SRC_DIR EXPRESSOS_BUILD_DIR

# L4RE_L4_BUILD_DIR is used in multiple places, so let's export it here
L4RE_L4_BUILD_DIR     := $(EXPRESSOS_BUILD_DIR)/third_party/l4re/l4
L4RE_FIASCO_BUILD_DIR := $(EXPRESSOS_BUILD_DIR)/third_party/l4re/fiasco
L4ANDROID_BUILD_DIR   := $(EXPRESSOS_BUILD_DIR)/third_party/l4android

PATH                  := $(CROSS_COMPILER_PATH)/bin:$(PATH)
SILKC                 := $(EXPRESSOS_SRC_DIR)/build/bin/linux-x86/silkc

export L4RE_L4_BUILD_DIR L4RE_FIASCO_BUILD_DIR L4ANDROID_BUILD_DIR
export PATH LLVM_BIN_DIR SILKC

L4RE_L4_SOURCE_DIR  := $(EXPRESSOS_SRC_DIR)/third_party/l4re/l4

TARGET_NAME ?= expressos
ISO_IMAGE := $(EXPRESSOS_BUILD_DIR)/out/target/$(L4RE_VARIANT)/$(TARGET_NAME)-$(L4RE_VARIANT).iso
MODULE_LIST_FILE := $(EXPRESSOS_TARGET_CONFIG_DIR)/modules.list

ISO_IMAGE_SEARCH_PATH := $(L4RE_L4_BUILD_DIR)/bin/$(L4RE_VARIANT)
ISO_IMAGE_SEARCH_PATH += :$(L4RE_L4_BUILD_DIR)/bin/$(L4RE_VARIANT)/l4f
ISO_IMAGE_SEARCH_PATH += :$(L4RE_FIASCO_BUILD_DIR):$(L4ANDROID_BUILD_DIR)
ISO_IMAGE_SEARCH_PATH += :$(EXPRESSOS_TARGET_CONFIG_DIR)
ISO_IMAGE_SEARCH_PATH += :$(EXPRESSOS_BUILD_DIR)/kernel
ISO_IMAGE_SEARCH_PATH += :$(EXPRESSOS_SRC_DIR)/../prebuilts/android-images

all: build_all

fiasco:
	$(Q)$(MAKE) -f $(EXPRESSOS_SRC_DIR)/build/fiasco.mk CROSS_COMPILE=$(CROSS_COMPILE)

l4re:
	$(Q)$(MAKE) -f $(EXPRESSOS_SRC_DIR)/build/l4re.mk CROSS_COMPILE=$(CROSS_COMPILE)

l4android:
	$(Q)$(MAKE) -f $(EXPRESSOS_SRC_DIR)/build/l4android.mk L4ARCH=$(L4ARCH) CROSS_COMPILE=$(CROSS_COMPILE)

kern: FORCE
	$(Q)$(shell [ -d $(EXPRESSOS_BUILD_DIR)/kernel ] || mkdir -p $(EXPRESSOS_BUILD_DIR)/kernel)
	$(Q)$(MAKE) -C $(EXPRESSOS_BUILD_DIR)/kernel -f $(EXPRESSOS_SRC_DIR)/build/kernel.mk CROSS_COMPILE=$(CROSS_COMPILE)

.NOTPARALLEL: build_all

build_all: fiasco l4re l4android kern

isoimage: $(ISO_IMAGE)

$(ISO_IMAGE): FORCE
	$(Q)$(MKDIR) -p $(dir $@)
	$(Q)L4DIR=$(L4RE_L4_SOURCE_DIR) \
	SEARCHPATH="$(ISO_IMAGE_SEARCH_PATH)" \
        $(L4RE_L4_SOURCE_DIR)/tool/bin/gengrub2iso --timeout=0 $(MODULE_LIST_FILE) \
             $@ $(TARGET_NAME)

mrproper:
	$(Q)rm -rf $(EXPRESSOS_BUILD_DIR)/third_party $(EXPRESSOS_BUILD_DIR)/kernel
	$(Q)$(MAKE) -C $(L4ANDROID_BUILD_DIR) M=$(EXPRESSOS_SRC_DIR)/kernel/kmod-expressos clean

.PHONY: mrproper FORCE
