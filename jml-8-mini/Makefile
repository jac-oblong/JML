##
# JML-8 Mini
##

#ZASM_ARGS="-I ./lib -o jml-8-mini-os.bin -b"
ZASM_ARGS=-o jml-8-mini-os.bin -b

all: jml-8-mini-os.bin

clean:
	rm -f *.out
	rm -f *.bin
	rm -f *.lst

jml-8-mini-os.bin: jml-8-mini-os.s clean
	zasm ${ZASM_ARGS} jml-8-mini-os.s

# end
