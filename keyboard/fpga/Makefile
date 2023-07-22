BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: test clean

# Test
reset_keyboard_test.o: counter.v receiver.v initial_response.v testbenches/reset_keyboard_tb.v
	iverilog -o reset_keyboard_test.o -s reset_keyboard_tb counter.v receiver.v \
		initial_response.v testbenches/reset_keyboard_tb.v

# Simulate
test: reset_keyboard_test.o
	vvp reset_keyboard_test.o

# Cleanup build artifacts
clean: test
	rm reset_keyboard_test.o
	mv *.vcd ./waveforms

.PHONY: clean test
.INTERMEDIATE: reset_keyboard_test.o
