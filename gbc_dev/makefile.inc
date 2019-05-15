
export PACKVER=current
export GBCPROJECT=build/gbc-$(PACKVER)
export DISTBIN=$(PWD)/../distbin
export CWD=$(PWD)

ifeq (,$(wildcard $(PWD)/custom.json))
	export NOCFG="missing $(PWD)/custom.json"
else
	#export CFG=--configuration=$(PWD)/custom.json --compile-mode=prod
	export CFG=--configuration=$(PWD)/custom.json --compile-mode=prod --create-zip
endif
