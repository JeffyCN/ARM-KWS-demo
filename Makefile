# This file was modified from mbed.org automagically generated Makefile. For
# more information, see http://mbed.org/handbook/Exporting-to-GCC-ARM-Embedded

###############################################################################
# Boiler-plate

V ?= 0
DEBUG ?= 0
PLATFORM ?= linux
CPU ?= a9
HARDFP ?= 1
REALTIME ?= 0

# Use 'make V=1' to see the full commands
ifeq ($(V),1)
Q =
else
Q = @
endif

OBJDIR := BUILD
MKFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
TOPDIR := $(dir $(MKFILE))

# Move to the top directory
ifneq ($(TOPDIR),$(CURDIR)/)
.SUFFIXES:
.PHONY: _all $(MAKECMDGOALS)
$(MAKECMDGOALS): _all
	@:

MAKETARGET = '$(MAKE)' --no-print-directory -C $(TOPDIR) -f '$(MKFILE)' \
	     $(MAKECMDGOALS)
_all:
	+$(Q)$(MAKETARGET)
else

# Boiler-plate
###############################################################################
# Objects and Paths

KWS_SRC_DIR = KWS/Deployment/Source/

SOURCE_DIRS += CMSIS_5/Source/ \
	       $(KWS_SRC_DIR)/KWS_C/ \
	       $(KWS_SRC_DIR)/MFCC_C/ \
	       $(KWS_SRC_DIR)/NN_C/ \
	       $(KWS_SRC_DIR)/local_NN/

ifeq ($(REALTIME),1)
SOURCE_DIRS += realtime_test/
else
SOURCE_DIRS += simple_test/
endif

C_SOURCES += $(shell find $(SOURCE_DIRS) -name '*.c')
CXX_SOURCES += $(shell find $(SOURCE_DIRS) -name "*.cpp")

OBJECTS += $(addprefix $(OBJDIR)/,$(C_SOURCES:.c=.o) $(CXX_SOURCES:.cpp=.o))

INCLUDE_PATHS += $(shell find $(SOURCE_DIRS) -type d) \
		 CMSIS_5/Include \

# Objects and Paths
###############################################################################
# Project settings

ifeq ($(REALTIME),1)
PROJECT := kws_realtime_test
else
PROJECT := kws_test
endif

# Project settings
###############################################################################
# Tools and Flags

ifeq ($(CPU),x86)
DEFINES += -D__ARM_FEATURE_DSP=0 -DNO_ASM
else ifeq ($(CPU),m4)
CPU_FLAGS += -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16
DEFINES += -D__FPU_PRESENT=1 -DARM_MATH_CM4
HARDFP = 0
else
DEFINES += -D__FPU_PRESENT=1
HARDFP = 1
endif

TARGET ?= $(PROJECT)

ifeq ($(CPU),x86)
CROSS_COMPILE ?=

else ifeq ($(PLATFORM),linux)
ifeq ($(HARDFP),1)
CROSS_COMPILE ?= arm-linux-gnueabihf-
else
CROSS_COMPILE ?= arm-linux-gnueabi-
endif
LD_FLAGS += -static

else
CROSS_COMPILE ?= arm-none-eabi-
HARDFP = 0
LD_LIBS += -lnosys
LD_FLAGS += -Wl,-n
endif

AS = $(CROSS_COMPILE)gcc
CC = $(CROSS_COMPILE)gcc
CPP = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)gcc
ELF2BIN = $(CROSS_COMPILE)objcopy
PREPROC = $(CROSS_COMPILE)cpp

ifeq ($(DEBUG),1)
DEBUG_FLAGS += -O0 -g
else
DEBUG_FLAGS += -fomit-frame-pointer -O3 -g1
endif

ifneq ($(CPU),x86)
ifeq ($(HARDFP),1)
CPU_FLAGS += -mfloat-abi=hard
else
CPU_FLAGS += -mfloat-abi=softfp
endif
endif

COMMON_FLAGS += $(CPU_FLAGS)

BUILD_FLAGS += -Wall -Wextra -Wno-unused-parameter -Wno-strict-aliasing \
	       -Wno-missing-field-initializers -fmessage-length=0 \
	       -fno-exceptions -fno-builtin -ffunction-sections \
	       -fdata-sections -funsigned-char -MMD \
	       -fno-delete-null-pointer-checks \
	       $(addprefix -I,$(INCLUDE_PATHS)) \
	       $(DEBUG_FLAGS) $(DEFINES) $(COMMON_FLAGS)

C_FLAGS += -std=gnu99 -c $(BUILD_FLAGS)
CXX_FLAGS += -std=gnu++98 -c -fno-rtti -Wvla $(BUILD_FLAGS)
ASM_FLAGS += -c -x assembler-with-cpp $(BUILD_FLAGS)
LD_FLAGS += -Wl,--gc-sections $(COMMON_FLAGS)
LD_LIBS += -lm -lc -lgcc

# Tools and Flags
###############################################################################
# Rules

.PHONY: all

all: $(TARGET)

clean:
	+$(Q)$(shell rm -rf '$(OBJDIR)' $(PROJECT)*)

$(foreach obj,$(OBJECTS),$(eval $(obj): | $(dir $(obj))))

$(OBJDIR)%/:
	$(Q)$(shell mkdir -p '$@')

$(OBJDIR)/%.o: %.s
	+$(Q)echo "Assemble: $(notdir $<)"
	$(Q)$(AS) -c $(ASM_FLAGS) -o $@ $<
  
$(OBJDIR)/%.o: %.S
	+$(Q)echo "Assemble: $(notdir $<)"
	$(Q)$(AS) -c $(ASM_FLAGS) -o $@ $<

$(OBJDIR)/%.o: %.c
	+$(Q)echo "Compile: $(notdir $<)"
	$(Q)$(CC) $(C_FLAGS) -o $@ $<

$(OBJDIR)/%.o: %.cpp
	+$(Q)echo "Compile: $(notdir $<)"
	$(Q)$(CPP) $(CXX_FLAGS) -o $@ $<

$(PROJECT): $(OBJECTS)
	+$(Q)echo "link: $(notdir $@)"
	$(Q)$(LD) $(LD_FLAGS) --output $@ $(filter %.o, $^) \
		-Wl,--start-group $(LD_LIBS) -Wl,--end-group

# Rules
###############################################################################
# Dependencies

DEPS = $(OBJECTS:.o=.d)
-include $(DEPS)
endif

# Dependencies
###############################################################################
