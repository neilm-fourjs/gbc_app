
GBCPROJDIR=/opt/fourjs/gbc-current
ARCH=gbc_app320_gbc
GASALIAS=g320
GASCFG=$(FGLASDIR)/etc/as.xcf
#GASCFG=$(FGLASDIR)/etc/isv_as320.xcf
export FGLLDPATH=../g2_lib/bin:$(GREDIR)/lib

all: gbc gbc_mdi/distbin/gbc-mdi.zip gar distbin/.deployed

lib:
	cd g2_lib && gsmake g2_lib.4pw

gar: lib
	gsmake gbc_app.4pw

clean:
	find . -name \*.42? -delete
	find . -name \*.gar -delete
	find . -name \*.zip -delete

gbc: 
	ln -s $(GBCPROJDIR)/dist/customization/gbc-mdi gbc

gbc_mdi/gbc-current:
	cd gbc_mdi && ln -s $(GBCPROJDIR) && ./gbc-setup.sh

gbc_mdi/distbin/gbc-mdi.zip: gbc_mdi/gbc-current
	cd gbc_mdi && make

distbin/.deployed: gar deploy

undeploy: 
	cd distbin && gasadmin gar -f $(GASCFG) --disable-archive $(ARCH) | true
	cd distbin && gasadmin gar -f $(GASCFG) --undeploy-archive $(ARCH).gar
	rm -f distbin/.deployed

deploy: 
	cd distbin && gasadmin gar -f $(GASCFG) --deploy-archive $(ARCH).gar
	cd distbin && gasadmin gar -f $(GASCFG) --enable-archive $(ARCH)
	echo "deployed" > distbin/.deployed

redeploy: undeploy deploy

run:
	xdg-open http://localhost/$(GASALIAS)/ua/r/gbc_app
