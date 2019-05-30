
GBCPROJDIR=/opt/fourjs/gbc-current
ARCH=gbc_app320_gbc
GASALIAS=g320
GASCFG=$(FGLASDIR)/etc/as.xcf
#GASCFG=$(FGLASDIR)/etc/isv_as320.xcf
export FGLLDPATH=../g2_lib/bin

all: gbc gar distbin/.deployed

gar:
	gsmake gbc_app.4pw

clean:
	find . -name \*.42? -delete
	find . -name \*.gar -delete

gbc: 
	cd gbc_mdi && ln -s $(GBCPROJDIR) && make

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
