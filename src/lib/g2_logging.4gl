--------------------------------------------------------------------------------
#+ Genero Logging Functions - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 3.20 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+
#+ No includes required.
#+
#+ Non GUI functions only

IMPORT os

CONSTANT C_DEFAULT_LOGDIR = "../logs/" -- Default logdir if nothing set

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
#+ @param l_name File name - can be NULL to default
#+ @param l_useDate string "true" / "false" include the date in the log name
FUNCTION (this logger) init(l_dir STRING, l_name STRING, l_ext STRING, l_useDate STRING) RETURNS()
  CALL this.setLogDir(l_dir)
  CALL this.setLogExt(l_ext)
  CALL this.setUseDate(l_useDate)
  CALL this.setLogName(l_name)
END FUNCTION
--------------------------------------------------------------------------------
#+ Write a message to an audit file.
#+
#+ @param l_mess Message to write to audit file.
FUNCTION (this logger) logIt(l_mess STRING) --{{{
  DEFINE c base.Channel
  DEFINE l_module STRING
  LET c = base.Channel.create()
  IF this.fullLogPath IS NULL THEN
    IF this.dirName IS NULL THEN
      CALL this.setLogDir(NULL)
    END IF
    IF this.fileExt IS NULL THEN
      CALL this.setLogExt(NULL)
    END IF
    IF this.fileName IS NULL THEN
      CALL this.setLogName(NULL)
    END IF
  END IF

  CALL c.openFile(this.fullLogPath, "a")

  LET l_module = getCallingModuleName()
  IF l_module MATCHES "cloud_gl_lib.gl_dbgMsg:*" THEN
    LET l_mess = CURRENT || "|" || NVL(l_mess, "NULL")
  ELSE
    LET l_mess = CURRENT || "|" || NVL(l_module, "NULL") || "|" || l_mess
  END IF

  DISPLAY "Log:", l_mess
  CALL c.writeLine(l_mess)
  CALL c.close()
END FUNCTION
--------------------------------------------------------------------------------
#+ Set the directory name for the log.
#+ also check for and create the log folder if it doesn't exist.
#+	normally not required as it's created during package install.
#+
#+ @param l_dir Directory to log to. If null then use $LOGDIR
FUNCTION (this logger) setLogDir(l_dir STRING) RETURNS()

  LET this.dirName = NVL(l_dir, fgl_getEnv("LOGDIR"))

  IF this.dirName.getLength() < 1 THEN
    LET this.dirName = "../logs" -- C_DEFAULT_LOGDIR
  END IF

  IF NOT os.path.exists(this.dirName) THEN
    IF NOT os.path.mkdir(this.dirName) THEN
      CALL g2_errPopup(SFMT(% "Failed to make logdir '%1.\nProgram aborting", this.dirName))
      CALL g2_exitProgram(200, "log dir issues")
    ELSE
      IF os.path.pathSeparator() = ":" THEN -- Linux/Unix/Mac/Android - ie not MSDOS!
        IF NOT os.path.chrwx(this.dirName, ((7 * 64) + (7 * 8) + 5)) THEN
          CALL g2_errPopup(SFMT(% "Failed set permissions on logdir '%1'", this.dirName))
          CALL g2_exitProgram(201, "log permissions")
        END IF
      END IF
    END IF
  END IF
  IF NOT os.path.isDirectory(this.dirName) THEN
    CALL g2_errPopup(SFMT(% "Logdir '%1' not a directory.\nProgram aborting", this.dirName))
    CALL g2_exitProgram(202, "logdir not a dir")
  END IF

-- Make sure the logdir ends with a slash.
  IF this.dirName.getCharAt(this.dirName.getLength()) != os.path.separator() THEN
    LET this.dirName = this.dirName.append(os.path.separator())
  END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Set the log fileName.
#+ If passed NULL then set the log name to the program name - date - user
#+ NOTE: doesn't include the extension so you can use it for .log and .err etc.
#+
#+ @param l_file File name for the logfile
FUNCTION (this logger) setLogName(l_file STRING) RETURNS()
  DEFINE l_user STRING
  IF fgl_getEnv("LOGFILEDATE") = "false" THEN
    LET this.useDate = FALSE
  END IF
  IF l_file IS NULL THEN
    LET l_user = fgl_getEnv("LOGNAME") -- get OS user
    IF l_user.getLength() < 2 THEN
      LET l_user = fgl_getEnv("USERNAME") -- get OS user
    END IF
    IF l_user.getLength() < 2 THEN
      LET l_user = "unknown"
    END IF
    --LET this.fileName = (TODAY USING "YYYYMMDD")||"-"||base.application.getProgramName()
    IF this.useDate THEN
      LET this.fileName =
          base.application.getProgramName() || "-" || (TODAY USING "YYYYMMDD") || "-" || l_user
    ELSE
      LET this.fileName = base.application.getProgramName()
    END IF
  ELSE
    LET this.fileName = l_file
  END IF
  LET this.fullLogPath = this.dirName || this.fileName || this.fileExt
-- if we have a dirName / fileName / and Ext then try and create an empty log file.
  IF this.fullLogPath IS NOT NULL THEN
    IF NOT os.path.exists(this.fullLogPath) THEN
      CALL this.logIt(SFMT("Log Started to %1", this.fullLogPath))
    END IF
  END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Set the file extension
#+
#+ @param l_ext Defaults to .log if NULL
FUNCTION (this logger) setLogExt(l_ext STRING) RETURNS()
  LET this.fileExt = NVL(l_ext, ".log")
  IF this.fileExt.getCharAt(1) != "." THEN
    LET this.fileExt = "." || this.fileExt
  END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Set the useDate
#+ If passed NULL then set the log name to the program name - date - user
#+ NOTE: doesn't include the extension so you can use it for .log and .err etc.
#+ @param l_useDate string "true" / "false" include the date in the log name
FUNCTION (this logger) setUseDate(l_useDate STRING) RETURNS()
  LET this.useDate = TRUE
  IF l_useDate IS NULL THEN
    IF LENGTH(fgl_getEnv("LOGFILEDATE")) > 1 THEN
      LET l_useDate = fgl_getEnv("LOGFILEDATE")
    END IF
  END IF
  IF l_useDate.toUpperCase() = "FALSE" THEN
    LET this.useDate = FALSE
  END IF
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the log directory name
FUNCTION (this logger) getLogDir() RETURNS STRING
  RETURN this.dirName
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the log file name ( minus dir and extension )
FUNCTION (this logger) getLogName() RETURNS STRING
  RETURN this.fileName
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the log file extension
FUNCTION (this logger) getLogExt() RETURNS STRING
  RETURN this.fileExt
END FUNCTION
--------------------------------------------------------------------------------
#+ Gets sourcefile.module:line from a stacktrace.
#+
#+ @return sourcefile.module:line
FUNCTION getCallingModuleName() RETURNS STRING
  DEFINE l_fil, l_mod, l_lin STRING
  DEFINE x, y SMALLINT
  LET l_fil = base.Application.getStackTrace()
  IF l_fil IS NULL THEN
    DISPLAY "Failed to get getStackTrace!!"
    RETURN "getStackTrace-failed!"
  END IF

  LET x = l_fil.getIndexOf("#", 2) -- skip passed this func
  LET x = l_fil.getIndexOf("#", x + 1) -- skip passed func that called this func
  LET x = l_fil.getIndexOf(" ", x) + 1
  LET y = l_fil.getIndexOf("(", x) - 1
  LET l_mod = l_fil.subString(x, y)

  LET x = l_fil.getIndexOf(" ", y) + 4
  LET y = l_fil.getIndexOf("#", x + 1) - 2
  IF y < 1 THEN
    LET y = (l_fil.getLength() - 1)
  END IF
  LET l_fil = l_fil.subString(x, y)

  -- strip the .4gl from the fil name
  LET x = l_fil.getIndexOf(".", 1)
  IF x > 0 THEN
    LET y = l_fil.getIndexOf(":", x)
    LET l_lin = l_fil.subString(y + 1, l_fil.getLength())
    LET l_fil = l_fil.subString(1, x - 1)
  END IF

  LET l_fil = NVL(l_fil, "FILE?") || "." || NVL(l_mod, "MOD?") || ":" || NVL(l_lin, "LINE?")
  RETURN l_fil
END FUNCTION
