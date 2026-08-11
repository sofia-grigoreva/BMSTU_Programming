CXX := clang++
CXXFLAGS := -std=c++17 -Wall -Wextra -pedantic

TARGET := compiler
SRC := compiler.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $<

run: $(TARGET)
	./$(TARGET)

png: run
	dot -Tpng cfg.dot -o cfg.png

clean:
	rm -f $(TARGET) *.o cfg.dot cfg.png

.PHONY: all run png clean
