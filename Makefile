IVERILOG = iverilog
VVP = vvp
VERILATOR = verilator
YOSYS = yosys
CC = gcc

.PHONY: help clean

help:
@echo "BINARY LAB"
@echo "Available commands:"
@echo "  make help"
@echo "  make clean"

clean:
rm -rf build simulation/output
