CC=clang
LD=arm-none-eabi-gcc
AS=arm-none-eabi-gcc
SIZE=arm-none-eabi-size

INCLUDES += -I./Core/Inc
INCLUDES += -I./Drivers/BSP/Components/Common
INCLUDES += -I./Drivers/BSP/Components/Common/mfxstm32l152
INCLUDES += -I./Drivers/BSP/STM32H7B3I-EVAL
INCLUDES += -I./Drivers/CMSIS/Device/ST/STM32H7xx/Include
INCLUDES += -I./Drivers/CMSIS/Include
INCLUDES += -I./Drivers/STM32H7xx_HAL_Driver/Inc
INCLUDES += -I./Drivers/STM32H7xx_HAL_Driver/Inc/Legacy
INCLUDES += -I./Middlewares/ST/STM32_USB_Host_Library/Class/MSC/Inc
INCLUDES += -I./Middlewares/ST/STM32_USB_Host_Library/Core/Inc
INCLUDES += -I./Middlewares/Third_Party/FatFs/src
INCLUDES += -I./Middlewares/Third_Party/FatFs/src/Drivers
INCLUDES += -I./USB_Host/App
INCLUDES += -I./USB_Host/Target
INCLUDES += -I$(MCU_SANITIZER_WORKDIR)/include
INCLUDES += -I$(MCU_SANITIZER_WORKDIR)/include/target

ASFLAGS = -x assembler-with-cpp -mcpu=cortex-m4 -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb

CFLAGS = --target=arm-none-eabi --sysroot=$(TOOLCHAIN_DIR)/arm-none-eabi -g -O0 -std=gnu11 -march=armv7e-m -mcpu=cortex-m4 -DDEBUG -DUSE_HAL_DRIVER -DSTM32H7B3xxQ -DUSE_USB_HS_IN_FS -DENABLE_FUZZ -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -ffunction-sections -fdata-sections -fshort-enums
LLVM = -flegacy-pass-manager -Xclang -load -Xclang $(MCU_SANITIZER_WORKDIR)/llvmpass/build/uSan/usan.so

LIBS = -lc -lm -lmcuasan-rt
LDFLAGS = -mcpu=cortex-m4 -T./STM32CubeIDE/STM32H7B3LIHXQ_FLASH.ld --specs=nano.specs -Wl,--gc-sections -static --specs=nosys.specs -mfpu=fpv5-d16 -mfloat-abi=hard -mthumb -L$(MCU_SANITIZER_WORKDIR)/compiler-rt -Wl,--start-group $(LIBS) -Wl,--end-group

CORE_C_SRC = $(wildcard Core/Src/*.c)
CORE_C_OBJ = $(CORE_C_SRC:.c=.o)

HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_cortex.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_exti.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_gpio.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_i2c.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_i2c_ex.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_pwr.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_pwr_ex.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_rcc.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_rcc_ex.c
HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_uart.c
HAL_C_OBJ = $(HAL_C_SRC:.c=.o)

USB_HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_hal_hcd.c
USB_HAL_C_SRC += Drivers/STM32H7xx_HAL_Driver/Src/stm32h7xx_ll_usb.c
USB_HAL_C_OBJ = $(USB_HAL_C_SRC:.c=.o)

DRIVERS_C_SRC += $(wildcard Drivers/BSP/STM32H7B3I-EVAL/*.c)
DRIVERS_C_SRC += $(wildcard Drivers/BSP/Components/mfxstm32l152/*.c)
DRIVERS_C_OBJ = $(DRIVERS_C_SRC:.c=.o)

MIDDLEWARES_C_SRC += $(wildcard Middlewares/ST/STM32_USB_Host_Library/Class/MSC/Src/*.c)
MIDDLEWARES_C_SRC += $(wildcard Middlewares/ST/STM32_USB_Host_Library/Core/Src/*.c)
MIDDLEWARES_C_SRC += $(wildcard Middlewares/Third_Party/FatFs/src/*.c)
MIDDLEWARES_C_OBJ = $(MIDDLEWARES_C_SRC:.c=.o)

USB_HOST_C_SRC += $(wildcard USB_Host/App/*.c)
USB_HOST_C_SRC += $(wildcard USB_Host/Target/*.c)
USB_HOST_C_OBJ = $(USB_HOST_C_SRC:.c=.o)

SYS_C_SRC = $(wildcard STM32CubeIDE/Application/Core/*.c)
SYS_C_OBJ = $(SYS_C_SRC:.c=.o)

STARTUP_AS_SRC += $(wildcard STM32CubeIDE/Application/Startup/*.s)
STARTUP_AS_OBJ = $(STARTUP_AS_SRC:.s=.o)

TARGET = STM32H7_USB_MSC

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(CORE_C_OBJ) $(DRIVERS_C_OBJ) $(HAL_C_OBJ) $(USB_HAL_C_OBJ) $(MIDDLEWARES_C_OBJ) $(USB_HOST_C_OBJ) $(SYS_C_OBJ) $(STARTUP_AS_OBJ)
	$(LD) $^ -o $(TARGET).elf $(LDFLAGS)
	$(SIZE) $(TARGET).elf

$(CORE_C_OBJ): %.o: %.c
	$(CC) $(CFLAGS) $(LLVM) $(INCLUDES) -c $^ -o $@

$(DRIVERS_C_OBJ): %.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $^ -o $@

$(HAL_C_OBJ): %.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $^ -o $@

$(USB_HAL_C_OBJ): %.o: %.c
	$(CC) $(CFLAGS) $(LLVM) $(INCLUDES) -c $^ -o $@

$(MIDDLEWARES_C_OBJ): %.o: %.c
	$(CC) $(CFLAGS) $(LLVM) $(INCLUDES) -c $^ -o $@

$(USB_HOST_C_OBJ): %.o: %.c
	$(CC) $(CFLAGS) $(LLVM) $(INCLUDES) -c $^ -o $@

$(SYS_C_OBJ): %.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $^ -o $@

$(STARTUP_AS_OBJ): %.o: %.s
	$(AS) $(ASFLAGS) -c $^ -o $@

clean:
	find ./ -name *.o -exec rm -f {} \;
	rm -f $(TARGET).elf
