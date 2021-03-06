# GBC Demo Application
This was written as a demo application for a custom GBC - not as production quality code.

*Disclaimer - It's a demo! - it's not fully functional and purely example code!*

NOTE: This was written using the EAP3 vesion of Genero 3.20 - I will updating it for newer releases as and when I can.

NOTE: The GBC customization was done using the 1.00.53 release.


## Folders
* Screenshots : The screenshots for this README
* db : My sqlite demo database
* dbexport : An Informix dbexport of my current demo database
* etc : 4st / 4ad / 4rp / 4db  etc
* gas : XCF file for deployment
* gst_gas : An XCF for when running via GST
* pics : Logo's
* src : Source code for the applications
* src/lib : Library source code

## This demo uses imported git repos for common library code and GBC customizations
* git submodule add https://github.com/neilm-fourjs/g2_lib.git g2_lib
* git submodule add https://github.com/neilm-fourjs/gbc_mdi.git gbc_mdi


*If libraries change do:* git submodule foreach git pull origin master



## Building
This was written and tested on Linux and built using GeneroStudio 3.20, the Makefile is used to setup additional folders.
* Required: GST 3.20 installed licensed and the environment set eg: . envgenero
* For notes on building the GBC see https://github.com/neilm-fourjs/gbc_mdi.git
 
*IMPORTANT* Make sure you use the --recursive flag when you clone this repo, eg: On Linux
```
$ git clone --recursive https://github.com/neilm-fourjs/gbc_app.git
$ cd gbc_app
$ make
$ make
```


## Database
This demo uses my njm_demo310 database as created by the mk_db program here: https://github.com/neilm-fourjs/njms_demos310/tree/master/src/db

I've only tested this application against Informix, PostgreSQL and SQLite.

To run locally with the included SQLite DB you'll need to change the etc/profile to load that database driver.


## Running
At the time of writing this, I have a deployed version of the demo that can be run from here: https://generodemos.dynu.net/f/ua/r/gbc_app

NOTE: This is actually running on a Raspberry Pi using: rasbian / lighttpd / postgresSQL

There is no login code in this demo so you can login using any user/pass values.
If you want a login demo see https://github.com/neilm-fourjs/loginDemo


## Genero 3.20 Specific
This demo uses the new structure methods feature. eg:
```
PUBLIC TYPE logger RECORD
  dirName STRING,
  fileName STRING,
  fileExt STRING,
  fullLogPath STRING,
  useDate BOOLEAN
END RECORD

#+ Set the logging Dir / Name / Ext / useDate
#+
#+ @param l_dir Directory to log to - can be NULL to use $LOGDIR
#+ @param l_name File name - can be NULL to default to use $LOGNAME
#+ @param l_ext File extension - can be NULL to default ( .log )
#+ @param l_useDate string "true" / "false" include the date in the log name
FUNCTION (this logger) init(l_dir STRING, l_name STRING, l_ext STRING, l_useDate STRING) RETURNS()
  CALL this.setLogDir(l_dir)

...


IMPORT FGL g2_logging
&include "g2_debug.inc"

PUBLIC DEFINE g2_err g2_logging.logger
...
  CALL g2_err.init(NULL, NULL, "err", "TRUE")
  DISPLAY "StartLog ", g2_err.fullLogPath
  CALL STARTLOG(g2_err.fullLogPath)
...

```


## Screenshots
![ss1](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-1.png "Login")
![ss2](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-2.png "Empty MDI Container")
![ss3](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-3.png "SS3")
![ss4](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-4.png "SS4")
![ss5](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-5.png "SS5")
![ss6](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-6.png "SS6")
![ss7](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-7.png "SS7")
![ss8](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-8.png "SS8")
![ss9](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-9.png "SS9")
![ss10](https://github.com/neilm-fourjs/gbc_app/raw/master/Screenshots/ss-10.png "SS10")


