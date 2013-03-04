include build/definition.mk

L4RE_L4_SOURCE_DIR := $(EXPRESSOS_SRC_DIR)/third_party/l4re/l4

TARGET := $(L4RE_L4_BUILD_DIR)/bin/$(L4RE_VARIANT)/l4f/l4re

all: $(TARGET)

$(TARGET): $(L4RE_L4_BUILD_DIR) FORCE
	echo "CROSS_COMPILE: $(CROSS_COMPILE)"
	$(Q)$(MAKE) -C $(L4RE_L4_BUILD_DIR) SYSTEM_TARGET=$(CROSS_COMPILE)

$(L4RE_L4_BUILD_DIR):
	$(Q)$(MAKE) -C $(L4RE_L4_SOURCE_DIR) B=$@
	$(Q)$(CP) $(EXPRESSOS_TARGET_CONFIG_DIR)/l4re-l4-config $@/.kconfig
	$(Q)$(MAKE) -C $(L4RE_L4_BUILD_DIR) oldconfig SYSTEM_TARGET=$(CROSS_COMPILE)

clean:
	$(Q)$(MAKE) -C $(L4RE_L4_BUILD_DIR) clean

mrproper:
	$(Q)$(RM) -rf $(L4RE_L4_BUILD_DIR)

.PHONY: all clean mrproper FORCE
