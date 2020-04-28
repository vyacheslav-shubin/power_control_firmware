MCU = attiny13
F_CPU = 4800000

FORMAT = ihex 
SRC = main

AVRDUDE = avrdude -p $(MCU) -c usbasp -B 1 -U


REMOVE = rm -f


all: asm

asm:
	avra $(SRC).asm

list:
	avra $(SRC).asm --listmac $(SRC).list

clean: begin clean_list end
	

clean_list:
	$(REMOVE) $(SRC).hex
	$(REMOVE) $(SRC).cof
	$(REMOVE) $(SRC).eep.hex
	$(REMOVE) $(SRC).hex
	$(REMOVE) $(SRC).obj

program:  asm
	$(AVRDUDE) flash:w:$(SRC).hex

read-fuse:
	$(AVRDUDE) lfuse:r:-:h -U hfuse:r:-:h

write-fuse:
	$(AVRDUDE) lfuse:w:0x31:m -U hfuse:w:0xFF:m
