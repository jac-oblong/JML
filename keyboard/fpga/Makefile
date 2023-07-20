BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: test

# Test
counter_test.o: counter.v counter_tb.v
	iverilog -o counter_test.o -s counter_tb counter.v counter_tb.v

# Simulate
test: counter_test.o
	vvp counter_test.o

# Cleanup build artifacts
clean:
	rm counter_test.o

.PHONY: clean test
.INTERMEDIATE: counter_test.o
