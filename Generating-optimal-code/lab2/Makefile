CXX := clang++
CXXFLAGS := -std=c++17

LLVM_CONFIG := llvm-config
LLVM_FLAGS := $(shell $(LLVM_CONFIG) --cxxflags --ldflags --system-libs --libs core)

SRC := main.cpp
TARGET := opt_lab2

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) $(LLVM_FLAGS) -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET)

rebuild: clean all

.PHONY: all run clean rebuild