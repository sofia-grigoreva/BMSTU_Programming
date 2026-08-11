CXX := clang++
CXXFLAGS := -std=c++17 -fPIC -fexceptions
LLVM_CONFIG := $(shell brew --prefix llvm)/bin/llvm-config
LLVM_CXXFLAGS := $(shell $(LLVM_CONFIG) --cxxflags | sed 's/-fno-exceptions//g')
LLVM_LDFLAGS := $(shell $(LLVM_CONFIG) --ldflags --libs core irreader support)

TARGET := compiler
SRC := compiler.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) -o $@ $< $(LLVM_LDFLAGS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) *.o

.PHONY: all run clean