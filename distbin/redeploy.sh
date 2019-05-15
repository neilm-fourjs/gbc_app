ARCH=gbc_app320
gasadmin gar --disable-archive $ARCH
gasadmin gar --undeploy-archive $ARCH.gar

gasadmin gar --deploy-archive $ARCH.gar
gasadmin gar --enable-archive $ARCH
