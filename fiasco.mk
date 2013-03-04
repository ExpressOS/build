include build/definition.mk

L4RE_FIASCO_SOURCE_DIR := $(EXPRESSOS_SRC_DIR)/third_party/l4re/kernel/fiasco

TARGET := $(L4RE_FIASCO_BUILD_DIR)/fiasco

all: $(TARGET)

$(TARGET): $(L4RE_FIASCO_BUILD_DIR) FORCE
	$(Q)$(MAKE) -C $(L4RE_FIASCO_BUILD_DIR) SYSTEM_TARGET=$(CROSS_COMPILE)

$(L4RE_FIASCO_BUILD_DIR):
	$(Q)$(MAKE) -C $(L4RE_FIASCO_SOURCE_DIR) BUILDDIR=$@
	$(Q)$(CP) $(EXPRESSOS_TARGET_CONFIG_DIR)/l4re-fiasco-config  $@/globalconfig.out
	$(Q)$(MAKE) -C $(L4RE_FIASCO_BUILD_DIR) oldconfig

clean:
	$(Q)$(MAKE) -C $(L4RE_FIASCO_BUILD_DIR) clean

mrproper:
	$(Q)$(RM) -rf $(L4RE_FIASCO_BUILD_DIR)

.PHONY: all clean mrproper FORCE
