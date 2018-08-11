# Variables to override
#
# CC            C compiler. MUST be set if crosscompiling
# CFLAGS        compiler flags for compiling all C files
# LDFLAGS       linker flags for linking all binaries

DEFAULT_TARGETS ?= priv priv/ntpd_script

LDFLAGS +=
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c99

.PHONY: all clean

all: $(DEFAULT_TARGETS)

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

priv:
	mkdir -p priv

priv/ntpd_script: src/ntpd_script.o
	$(CC) $^ $(LDFLAGS) -o $@

clean:
	rm -f priv/ntpd_script src/*.o
