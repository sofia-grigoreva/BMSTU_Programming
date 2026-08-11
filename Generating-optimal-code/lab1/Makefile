BREW_PREFIX ?= /opt/homebrew
GCC_VERSION ?= 15
CC := $(BREW_PREFIX)/bin/gcc-$(GCC_VERSION)
CXX := $(BREW_PREFIX)/bin/g++-$(GCC_VERSION)
PLUGIN_DIR := $(shell $(CC) -print-file-name=plugin)
PLUGIN_INCLUDE := $(PLUGIN_DIR)/include

PHI_DEBUG_CXXFLAGS := -g -Wall -Wextra -std=c++14 -fPIC -fno-rtti -I$(PLUGIN_INCLUDE) -I$(BREW_PREFIX)/include
PHI_DEBUG_LDFLAGS := -shared -Wl,-undefined,dynamic_lookup

phi-debug:
	mkdir -p plugin
	$(CXX) $(PHI_DEBUG_CXXFLAGS) src/phi-debug/phi-debug.cpp -o plugin/phi-debug.so $(PHI_DEBUG_LDFLAGS)

test:
	$(CC) -fplugin=plugin/phi-debug.so -O0 src/test/test.c -o src/test/test
	./src/test/test

clean:
	rm -rf plugin src/test/test

.PHONY: clean test phi-debug