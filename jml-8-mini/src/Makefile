##
# JML-8 Mini
##

ZASM_ARGS=-o jml-8-mini-firmware.bin -b

all: jml-8-mini-firmware.bin

clean:
	rm -f *.out
	rm -f *.bin
	rm -f *.lst
	rm -f ../include/*.out
	rm -f ../include/*.bin
	rm -f ../include/*.lst

jml-8-mini-firmware.bin: jml-8-mini-firmware.s clean
	zasm ${ZASM_ARGS} jml-8-mini-firmware.s

# end
