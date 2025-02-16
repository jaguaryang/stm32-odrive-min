TARGET = odrive_min
BUILD_DIR = build

# Compiler settings
PREFIX = arm-none-eabi-
CXX = $(PREFIX)g++ -std=c++17 -Wno-register
CC = $(PREFIX)gcc -std=c99
AS = $(PREFIX)gcc -x assembler-with-cpp

# MCU settings
MCU = -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -DARM_MATH_CM4

# Core definitions
C_DEFS = -DSTM32F405xx -DHW_VERSION_MAJOR=3 -DHW_VERSION_MINOR=6 -DHW_VERSION_VOLTAGE=56 \
         -DUSE_HAL_DRIVER -DFIBRE_ENABLE_SERVER=1

# Include paths
C_INCLUDES = -I./ \
    -IThirdParty/CMSIS/Include \
    -IThirdParty/CMSIS/Device/ST/STM32F4xx/Include \
    -IThirdParty/STM32F4xx_HAL_Driver/Inc \
    -IThirdParty/FreeRTOS/Source/include \
    -IThirdParty/FreeRTOS/Source/CMSIS_RTOS \
    -IThirdParty/FreeRTOS/Source/portable/GCC/ARM_CM4F \
    -IThirdParty/STM32_USB_Device_Library/Core/Inc \
    -IThirdParty/STM32_USB_Device_Library/Class/CDC/Inc \
    -IBoard/v3/Inc \
    -IMotorControl \
    -Ifibre-cpp/include

# Compiler flags
CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) -Og \
    -Wall -fdata-sections -ffunction-sections \
    -Wdouble-promotion -Wfloat-conversion \
    -Wno-psabi -Wno-nonnull -g -MMD -MP

# Source files grouped by directory
C_SOURCES = \
    $(wildcard ThirdParty/STM32F4xx_HAL_Driver/Src/*.c) \
    $(wildcard ThirdParty/FreeRTOS/Source/*.c) \
    $(wildcard ThirdParty/FreeRTOS/Source/portable/GCC/ARM_CM4F/*.c) \
    $(wildcard ThirdParty/FreeRTOS/Source/portable/MemMang/*.c) \
    $(wildcard ThirdParty/FreeRTOS/Source/CMSIS_RTOS/*.c) \
    $(wildcard ThirdParty/STM32_USB_Device_Library/Core/Src/*.c) \
    $(wildcard ThirdParty/STM32_USB_Device_Library/Class/CDC/Src/*.c) \
    $(wildcard Board/v3/Src/*.c) \
    $(wildcard MotorControl/*.c) \
    $(wildcard Drivers/STM32/*.c) \
    $(wildcard communication/can/*.c) \
    $(wildcard *.c)

CPP_SOURCES = \
    $(wildcard MotorControl/*.cpp) \
    $(wildcard Drivers/STM32/*.cpp) \
    $(wildcard communication/*.cpp) \
    $(wildcard communication/can/*.cpp) \
    $(wildcard fibre-cpp/*.cpp) \
    $(wildcard Board/v3/*.cpp) \
    $(wildcard Drivers/DRV8301/*.cpp)

ASM_SOURCES = Board/v3/startup_stm32f405xx.s

# Set up search paths for source files
vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.cpp $(sort $(dir $(CPP_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

# Object files
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/__,$(notdir $(CPP_SOURCES:.cpp=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

# Library settings
LIBS = -lc -lm -lnosys -larm_cortexM4lf_math
LIBDIR = -L./ThirdParty/CMSIS/Lib/GCC
LDFLAGS = $(MCU) -specs=nosys.specs -T Board/v3/STM32F405RGTx_FLASH.ld $(LIBDIR) $(LIBS) \
    -Wl,--gc-sections -u _printf_float -u _scanf_float -Wl,--undefined=uxTopUsedPriority

# Build rules
all: $(BUILD_DIR)/$(TARGET).elf

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) | $(BUILD_DIR)
	$(CXX) $(OBJECTS) $(LDFLAGS) -o $@

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/__%.o: %.cpp | $(BUILD_DIR)
	$(CXX) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)

-include $(wildcard $(BUILD_DIR)/*.d)
