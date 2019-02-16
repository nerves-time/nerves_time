# Makefile for building the ntpd helper "script"
#
# Makefile targets:
#
# all/install   build and install
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_COMPILE_PATH path to the build's ebin directory
# CC            C compiler. MUST be set if crosscompiling
# CFLAGS        compiler flags for compiling all C files
# LDFLAGS       linker flags for linking all binaries

PREFIX = $(MIX_COMPILE_PATH)/../priv
BUILD  = $(MIX_COMPILE_PATH)/../obj

NTPD_SCRIPT = $(PREFIX)/ntpd_script

LDFLAGS +=
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c99

SRC = src/ntpd_script.c
OBJ = $(SRC:src/%.c=$(BUILD)/%.o)

calling_from_make:
	mix compile

all: install

install: $(PREFIX) $(BUILD) $(NTPD_SCRIPT)

$(OBJ): Makefile

$(BUILD)/%.o: src/%.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(NTPD_SCRIPT): $(OBJ)
	$(CC) $^ $(LDFLAGS) -o $@

$(PREFIX):
	mkdir -p $@

$(BUILD):
	mkdir -p $@

clean:
	$(RM) $(NTPD_SCRIPT) $(BUILD)/*.o

.PHONY: all clean calling_from_make install
