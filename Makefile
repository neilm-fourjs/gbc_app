
all: gar

gbc:
	ln -s gbc_dev/build/gbc-current/dist/customization/gbc-app gbc

gar:
	gsmake gbc_app.4pw
