LLVMDIS   := $(LLVM_BIN_DIR)/llvm-dis
LLVMAS    := $(LLVM_BIN_DIR)/llvm-as
LLVMLINK  := $(LLVM_BIN_DIR)/llvm-link
LLC       := $(LLVM_BIN_DIR)/llc
OPT       := $(LLVM_BIN_DIR)/opt
CC        := $(LLVM_BIN_DIR)/clang
CLANG     := $(LLVM_BIN_DIR)/clang

STRIP     := $(CROSS_COMPILE)strip
L4RE_LINK := $(EXPRESSOS_SRC_DIR)/build/link-wrapper

DEPDIR           := .deps
CIL_PATH         := $(EXPRESSOS_BUILD_DIR)/obj
LIBGCC_DIR       := $(dir $(shell $(CROSS_COMPILE)gcc -print-libgcc-file-name))
CLANG_STDINC_DIR := $(shell echo "\#include <stdint.h>"|$(CLANG) -fsyntax-only -fshow-source-location -x c - -v 2>&1|grep "^ /.*clang/.*")

TARGET_EXE := $(CIL_PATH)/ExpressOS.Startup.dll
TARGET_BC  := ExpressOS.Startup.bc
TARGET     := expressos
TARGET_OBJ := expressos.o

VPATH += $(EXPRESSOS_SRC_DIR)/kernel/expressos/native

C_INCLUDES := $(CLANG_STDINC_DIR) \
              $(EXPRESSOS_SRC_DIR)/kernel/expressos/native/include \
              $(L4RE_L4_BUILD_DIR)/include/x86/l4f \
              $(L4RE_L4_BUILD_DIR)/include/l4f \
              $(L4RE_L4_BUILD_DIR)/include/x86 \
              $(L4RE_L4_BUILD_DIR)/include \

CFLAGS := -Wall -Wextra -Wno-unused-function -O2 -fno-strict-aliasing \
          -emit-llvm -nostdinc -m32 -fno-stack-protector $(addprefix -I,$(C_INCLUDES))

# Platform-specific
CFLAGS += -DSYSTEM_x86_pentium_l4f -DARCH_x86 -DCPUTYPE_pentium \
          -DL4API_l4f -D_GNU_SOURCE

DEPFLAGS    := $(CFLAGS) -MM
LDFLAGS     := -fno-omit-frame-pointer -m32
OPTFLAGS    := -internalize -internalize-public-api-list=main,memset,memcpy,strlen -mem2reg -O2
#OPTFLAGS += -disable-inlining
#-internalize -mem2reg -adce -disable-inlining

SLIKC_FLAGS := -target-triple $(TARGET_TRIPLE) -classpath $(CIL_PATH)

BCS := glue/main.bc glue/console.bc glue/control-block.bc glue/csharp-rt.bc glue/init.bc
BCS += glue/l4api.bc glue/task.bc glue/tls.bc
BCS += glue/panic.bc glue/sel4-pa.bc
BCS += glue/crt.bc
BCS += kernel/printk.bc kernel/vprintk.bc kernel/mm.bc kernel/sfs_md.bc
BCS += $(TARGET_BC)

all: $(TARGET)

$(TARGET): $(TARGET_OBJ)
	$(Q)echo "  LD	$@" && LIBGCC_DIR=$(LIBGCC_DIR) CROSS_COMPILE=$(CROSS_COMPILE) $(L4RE_LINK) -o $@ $^
#	$(STRIP) $@

$(TARGET_OBJ:.o=.bc): $(BCS)
	$(Q)echo "  LD	$@" && $(LLVMLINK) $^ -o -|$(OPT) $(OPTFLAGS) -f -o $@

$(TARGET_BC): $(TARGET_EXE)
	$(Q)echo "  SILK	$@" && $(SILKC) -classpath $(CIL_PATH) $(notdir $<) -o $@

$(DEPDIR)/%.d: %.c
	$(shell [ -d $(dir $@) ] || mkdir -p $(dir $@))
	$(Q)echo "  DEP	$@" && $(CC) $(DEPFLAGS) -MQ "$(subst $(DEPDIR)/,,$(@:.d=.bc))" $< -o $@

-include $(addprefix $(DEPDIR)/,$(patsubst %.bc,%.d,$(BCS)))

%.bc : %.c
	@( [ ! -d $(dir $@) ] && mkdir -p $(dir $@) ) || /bin/true
	$(Q)echo "  CC	$@" && $(CC) $(CFLAGS) -c $< -o $@

%.bc : %.ll
	@( [ ! -d $(dir $@) ] && mkdir -p $(dir $@) ) || /bin/true
	$(Q)echo "  AS	$@" && $(LLVMAS) $< -o $@

%.o: %.bc
	$(Q)echo "  CC	$@" && $(CC) $(LDFLAGS) -c $< -o $@

clean:
	$(Q)rm -rf $(DEPDIR) $(BCS)

.PHONY: clean
