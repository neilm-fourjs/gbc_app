
all: gbc gar

gar:
	gsmake gbc_app.4pw

clean:
	find . -name \*.42? -delete
	find . -name \*.gar -delete

gbc_dev/build:
	mkdir $@
	cd gbc_dev
	make

gbc: gbc_dev/build gbc_dev/build/gbc-current/dist/customization/gbc-app
	ln -s gbc_dev/build/gbc-current/dist/customization/gbc-app gbc

