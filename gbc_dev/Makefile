
GBCBASE=$(PWD)

include makefile.inc

BASE=$(shell pwd)
dirs=gbc-app

all: distbin build build/gbc-current subdirs

distbin:
	mkdir distbin

build:
	mkdir build

# Setup the GBC build env
build/gbc-current: 
	./gbc-setup.sh > gbc-setup.out

subdirs: $(dirs)
	@for dir in $^ ; do  \
		cd $(BASE)/$$dir && make all; \
	done

clean:
	rm $(DISTBIN)/gbc*.zip
