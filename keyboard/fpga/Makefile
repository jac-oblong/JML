BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: test clean

# Test
receiver_test.o: counter.v receiver.v testbenches/receiver_tb.v
	iverilog -o receiver_test.o -s receiver_tb counter.v receiver.v testbenches/receiver_tb.v

# Simulate
test: receiver_test.o
	vvp receiver_test.o

# Cleanup build artifacts
clean: test
	rm receiver_test.o
	mv *.vcd ./waveforms

.PHONY: clean test
.INTERMEDIATE: receiver_test.o
