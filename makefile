RM=rm
PORT=/dev/ttyUSB0
SUDO=

BINARY=f256_life
LOADER=loader.bin
FLASHIMAGE=cart_life.bin
FORCE=-f
PYTHON=python
ONBOARDPREFIX=life_
CP=cp
DIST=dist


ifdef WIN
RM=del
PORT=COM3
SUDO=
FORCE=
endif


.PHONY: all
all: pgz

.PHONY: pgz
pgz: $(BINARY).pgz

.PHONY: dist
dist: clean pgz cartridge onboard
	$(RM) $(FORCE) $(DIST)/*
	$(CP) $(BINARY).pgz $(DIST)/
	$(CP) $(FLASHIMAGE) $(DIST)/
	$(CP) $(ONBOARDPREFIX)*.bin $(DIST)/


$(BINARY): *.asm
	64tass --nostart -o $(BINARY) main.asm

clean: 
	$(RM) $(FORCE) $(BINARY)
	$(RM) $(FORCE) $(BINARY).pgz
	$(RM) $(FORCE) tests/bin/*.bin
	$(RM) $(FORCE) $(LOADER)
	$(RM) $(FORCE) $(FLASHIMAGE)
	$(RM) $(FORCE) $(ONBOARDPREFIX)*.bin
	$(RM) $(FORCE) $(DIST)/*


upload: $(BINARY).pgz
	$(SUDO) $(PYTHON) fnxmgr.zip --port $(PORT) --run-pgz $(BINARY).pgz

$(BINARY).pgz: $(BINARY)
	$(PYTHON) make_pgz.py $(BINARY)

test:
	6502profiler verifyall -c config.json -trapaddr 0x07FF

.PHONY: cartridge
cartridge: $(FLASHIMAGE)


$(LOADER): flashloader.asm
	64tass --nostart -o $(LOADER) flashloader.asm


$(FLASHIMAGE): $(BINARY) $(LOADER)
	$(PYTHON) pad_binary.py $(BINARY) $(LOADER) $(FLASHIMAGE)


.PHONY: onboard
onboard: $(FLASHIMAGE)
	$(PYTHON) split8k.py $(FLASHIMAGE) $(ONBOARDPREFIX)