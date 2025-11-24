HOME ?= $(shell echo $$HOME)  # Fallback if not set
LVGL_DIR = $(HOME)/lvgl

# Collect all .c sources under lvgl/src (recursively)
LVGL_SOURCES := $(shell find $(LVGL_DIR)/src -name "*.c")


LVGL_OBJECTS := $(patsubst %.c, %.o, $(LVGL_SOURCES))



#LVGL_OBJECTS = $(LVGL_SOURCES:.c=.o)
OBJECTS += $(LVGL_OBJECTS)

VPATH += $(sort $(dir $(LVGL_SOURCES)))
	

LIBGCC := $(shell riscv64-unknown-elf-gcc -print-libgcc-file-name)

LIBGCC_OBJS += $(HOME)/litex_venv/litex/litex/soc/software/socmel_1/libgcc_objs/_ffssi2.o


OBJECTS += $(LIBGCC_OBJS)

CFLAGS += -I$(SOC_DIRECTORY)/software/include


BUILD_DIR?=../build/

include $(BUILD_DIR)/software/include/generated/variables.mak
include $(SOC_DIRECTORY)/software/common.mak

LIBGCC_OBJDIR := ../libgcc_objs

CFLAGS += -DLV_CONF_INCLUDE_SIMPLE
CFLAGS += -I$(LVGL_DIR) 
CFLAGS  += -Os -ffunction-sections -fdata-sections

OBJECTS   += crt0.o main.o army_panel.o lv_font_scoreboard_32.o 


all: sdr_v1.bin


%.bin: %.elf
	$(OBJCOPY) -O binary $< $@
ifneq ($(OS),Windows_NT)
	chmod -x $@
endif

vpath %.a $(PACKAGES:%=../%)

sdr_v1.elf: $(OBJECTS)
	$(CC) $(LDFLAGS) -T linker.ld -N -o $@ \
		$(OBJECTS) \
		$(PACKAGES:%=-L$(BUILD_DIR)/software/%) \
		-Wl,--whole-archive \
		-Wl,--gc-sections \
		-Wl,-s -Wl,-Map,$@.map \
		$(LIBS:lib%=-l%) 

ifneq ($(OS),Windows_NT)
	chmod -x $@
endif

# pull in dependency info for *existing* .o files
-include $(OBJECTS:.o=.d)

donut.o: CFLAGS   += -w

isr.o: $(HOME)/socmel_1/litex/litex/soc/software/libbase/isr.c
	$(CC) $(CFLAGS) -c -o $@ $<

army_panel.o: $(HOME)/socmel_1/litex/litex/soc/software/socmel_1/sdr_v1/army_panel.c
	$(CC) $(CFLAGS) -c -o $@ $<

lv_font_14_seg_led_32.o: $(HOME)/socmel_1/litex/litex/soc/software/socmel_1/sdr_v1/lv_font_scoreboard_32.c
	$(CC) $(CFLAGS) -c -o $@ $<

VPATH = $(BIOS_DIRECTORY):$(BIOS_DIRECTORY)/cmds:$(CPU_DIRECTORY)


%.o: %.cpp
	$(compilexx)

%.o: %.c
	$(compile)

%.o: %.S
	$(assemble)

clean:
	$(RM) $(OBJECTS) sdr_v1.elf sdr_v1.bin .*~ *~

.PHONY: all clean


# Rule: extract _ffssi2.o from the right libgcc.a
$(LIBGCC_OBJS):
	mkdir -p $(LIBGCC_OBJDIR)
	cd $(LIBGCC_OBJDIR) && ar x /usr/lib/gcc/riscv64-unknown-elf/13.2.0/rv32im/ilp32/libgcc.a _ffssi2.o
$(OUTPUT_FILE): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^ \
	    -Wl,--start-group -lm -Wl,--end-group

