BOARD			=		tangnano9k
FAMILY		=		GW1N-9C
DEVICE		=		GW1NR-LV9QN88PC6/I5

SRC_DIR		=		.
TB_DIR		=		testbench
WAVE_DIR	=		waveform

SRCS			=		$(wildcard $(SRC_DIR)/*.v)
TESTS			=		$(wildcard $(TB_DIR)/*_tb.v)
TEST_OBJS	=		$(TESTS:$(TB_DIR)/%_tb.v=%_tb.o)
WAVES			=		$(TESTS:$(TB_DIR)/%_tb.v=$(WAVE_DIR)/%.vcd)


all : make_clean toplevel.fs

# Synthesis
toplevel.json : $(SRCS)
	@yosys -p "read_verilog $(SRCS); synth_gowin -top toplevel -json toplevel.json"

# Place and Route
toplevel_pnr.json : toplevel.json
	@nextpnr-gowin --json toplevel.json --freq 27 --write \
		toplevel_pnr.json --device ${DEVICE} --family ${FAMILY} \
		--cst ${BOARD}.cst

# Generate Bitstream
toplevel.fs : toplevel_pnr.json
	@gowin_pack -d ${FAMILY} -o toplevel.fs toplevel_pnr.json

# Programming Board
program : toplevel.fs
	@openFPGALoader -b ${BOARD} toplevel.fs -f


# Testing
%_tb.o : $(TB_DIR)/%_tb.v $(SRCS)
	@iverilog -o $@ -s test $(SRCS) $<

$(WAVE_DIR)/%.vcd : %_tb.o
	@vvp $< -o $@

test : $(WAVES)


# Cleanup build artifacts
clean :
	rm -f ./*.fs
	rm -f ./*.o
	rm -f ./*.json
	rm -f ./*.vcd
	rm -f waveform/*

make_clean :
	@rm -f ./*.fs
	@rm -f ./*.o
	@rm -f ./*.json

.PHONY: clean program test make_clean
.INTERMEDIATE: toplevel.json toplevel_pnr.json $(TEST_OBJS)
