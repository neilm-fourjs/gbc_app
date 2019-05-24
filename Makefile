
ARCH=gbc_app320_gbc
GASALIAS=g320

all: gbc gar distbin/.deployed

gar:
	gsmake gbc_app.4pw

clean:
	find . -name \*.42? -delete
	find . -name \*.gar -delete

gbc_dev/build:
	mkdir $@
	cd gbc_dev && make

gbc: gbc_dev/build gbc_dev/build/gbc-current/dist/customization/gbc-app
	ln -s gbc_dev/build/gbc-current/dist/customization/gbc-app gbc

distbin/.deployed: gar deploy

undeploy: 
	cd distbin && gasadmin gar --disable-archive $(ARCH) | true
	cd distbin && gasadmin gar --undeploy-archive $(ARCH).gar
	rm -f distbin/.deployed

deploy: 
	cd distbin && gasadmin gar --deploy-archive $(ARCH).gar
	cd distbin && gasadmin gar --enable-archive $(ARCH)
	echo "deployed" > distbin/.deployed

redeploy: undeploy deploy

run:
	xdg-open http://localhost/$(GASALIAS)/ua/r/gbc_app
