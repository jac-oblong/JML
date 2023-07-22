BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

all: load clean

# Synthesis
toplevel.json: counter.v initial_response.v receiver.v toplevel.v
	yosys -p "read_verilog counter.v initial_response.v receiver.v toplevel.v; synth_gowin -top toplevel -json toplevel.json"

# Place and Route
toplevel_pnr.json: toplevel.json
	nextpnr-gowin --json toplevel.json --freq 27 --write toplevel_pnr.json \
		--device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
toplevel.fs: toplevel_pnr.json
	gowin_pack -d ${FAMILY} -o toplevel.fs toplevel_pnr.json

# Program Board
load: toplevel.fs
	openFPGALoader -b ${BOARD} toplevel.fs -f


# Cleanup build artifacts
clean: load
	rm toplevel.fs

.PHONY: clean load
.INTERMEDIATE: toplevel.json toplevel_pnr.json
