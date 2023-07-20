BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: test

# Test
initial_response_test.o: counter.v initial_response.v initial_response_tb.v
	iverilog -o initial_response_test.o -s initial_response_tb counter.v initial_response.v initial_response_tb.v

# Simulate
test: initial_response_test.o
	vvp initial_response_test.o

# Cleanup build artifacts
clean:
	rm initial_response_test.o

.PHONY: clean test
.INTERMEDIATE: initial_response_test.o
