TARGET = rsa.dsk
RSABIN = RSA.BIN
TESTBINS = TSTPR.BIN TSTMUL.BIN TSTEXP.BIN TSTDIV.BIN TSTREM.BIN TSTSTK.BIN TSTDSK.BIN TSTLIC.BIN

all: clean $(TARGET)

clean:
	rm -f $(TARGET) $(TESTBINS) $(RSABIN)

$(TARGET): diskgen $(RSABIN)
	decb copy $(RSABIN) $(TARGET),$(RSABIN) -2 -b
	decb copy COPYING $(TARGET),COPYING -1 -a

tests: clean diskgen $(TARGET) $(TESTBINS)
	decb copy TSTPR.BIN $(TARGET),TSTPR.BIN -2 -b
	decb copy TSTMUL.BIN $(TARGET),TSTMUL.BIN -2 -b
	decb copy TSTEXP.BIN $(TARGET),TSTEXP.BIN -2 -b
	decb copy TSTDIV.BIN $(TARGET),TSTDIV.BIN -2 -b
	decb copy TSTREM.BIN $(TARGET),TSTREM.BIN -2 -b
	decb copy TSTSTK.BIN $(TARGET),TSTSTK.BIN -2 -b
	decb copy TSTDSK.BIN $(TARGET),TSTDSK.BIN -2 -b
	decb copy TSTLIC.BIN $(TARGET),TSTLIC.BIN -2 -b

diskgen:
	decb dskini $(TARGET)

RSA.BIN: src/rsa.asm
	lwasm -9 --decb -o $@ $<

TSTPR.BIN: src/tstpr.asm
	lwasm -9 --decb -o $@ $<

TSTMUL.BIN: src/tstmul.asm
	lwasm -9 --decb -o $@ $<

TSTDIV.BIN: src/tstdiv.asm
	lwasm -9 --decb -o $@ $<

TSTREM.BIN: src/tstrem.asm
	lwasm -9 --decb -o $@ $<

TSTSTK.BIN: src/tststk.asm
	lwasm -9 --decb -o $@ $<

TSTEXP.BIN: src/tstexp.asm
	lwasm -9 --decb -o $@ $<

TSTDSK.BIN: src/tstdsk.asm
	lwasm -9 --decb -o $@ $<

TSTLIC.BIN: src/tstlic.asm
	lwasm -9 --decb -o $@ $<


