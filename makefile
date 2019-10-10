
BIN=../njm_app_bin
PROG=gbc_app
GBCPROJDIR=/opt/fourjs/gbc-current
ARCH=gbc_app320_gbc
GASALIAS=g320
GASCFG=$(FGLASDIR)/etc/as.xcf
#GASCFG=$(FGLASDIR)/etc/isv_as320.xcf

export CUSTOM_DB=../custom_db.json
export DBNAME=njm_demo_db
export FGLRESOURCEPATH=$(PWD)/etc
export FGLLDPATH=../g2_lib/bin:$(GREDIR)/lib

all: gbc gbc_mdi/distbin/gbc-mdi.zip gar distbin/.deployed

gar:
	gsmake gbc_app.4pw

clean:
	gsmake -c gbc_app.4pw

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
	cd $(BIN) && fglrun $(PROG)

rungas:
	xdg-open http://localhost/$(GASALIAS)/ua/r/gbc_app
