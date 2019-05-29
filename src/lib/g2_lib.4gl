--------------------------------------------------------------------------------
#+ Genero Genero Library Functions - by Neil J Martin ( neilm@4js.com )
#+ This library is intended as an example of useful library code for use with
#+ Genero 3.20 and above
#+
#+ No warrantee of any kind, express or implied, is included with this software;
#+ use at your own risk, responsibility for damages (if any) to anyone resulting
#+ from the use of this software rests entirely with the user.
#+
#+ No includes required.

IMPORT os
IMPORT util
IMPORT FGL g2_logging

&include "g2_debug.inc"

PUBLIC DEFINE g2_log g2_logging.logger
PUBLIC DEFINE g2_err g2_logging.logger
PUBLIC DEFINE m_mdi CHAR(1)
PUBLIC DEFINE m_isUniversal BOOLEAN
PUBLIC DEFINE m_isGDC BOOLEAN

FUNCTION g2_init(l_mdi CHAR(1), l_cfgname STRING)
	DEFINE l_ucn STRING
	CALL g2_log.init(NULL, NULL, "log", "TRUE")
	CALL g2_log.init(NULL, NULL, "err", "TRUE")

  CALL STARTLOG(g2_err.fullLogPath)
  WHENEVER ANY ERROR CALL g2_error

	LET m_isGDC = FALSE
	LET m_isUniversal = TRUE
	LET l_ucn = ui.Interface.getUniversalClientName()
	IF l_ucn.getLength() < 3 THEN LET l_ucn = "?" END IF
	IF ui.Interface.getFrontEndName() = "GDC" THEN LET m_isGDC = TRUE END IF
	IF l_ucn != "GBC" THEN LET m_isUniversal = FALSE END IF

  CALL g2_loadStyles(l_cfgname)
	CALL g2_loadToolBar(l_cfgname)
	CALL g2_loadActions(l_cfgname)
  CALL g2_mdisdi(l_mdi)
END FUNCTION
--------------------------------------------------------------------------------
#+ Set MDI or not
#+ C = child
#+ M = MDI Container
#+ S = Not MDI
#+ @param l_mdi_sdi S/C/M = default is 'S'
FUNCTION g2_mdisdi(l_mdi_sdi CHAR(1))
	DEFINE l_container, l_desc STRING
  IF l_mdi_sdi IS NULL OR l_mdi_sdi = " " THEN
    LET l_mdi_sdi = "S"
  END IF
	LET m_mdi = l_mdi_sdi

  LET l_container = fgl_getEnv("FJS_MDICONT")
  IF l_container IS NULL OR l_container = " " THEN
    LET l_container = "container"
  END IF
  LET l_desc = fgl_getEnv("FJS_MDITITLE")
  IF l_desc IS NULL OR l_desc = " " THEN
    LET l_desc = "MDI Container:" || l_container
  END IF
  CASE m_mdi
    WHEN "C" -- Child
      GL_DBGMSG(2, "gl_init: Child")
      CALL ui.Interface.setType("child")
      CALL ui.Interface.setContainer(l_container)
    WHEN "M" -- MDI Container
      GL_DBGMSG(2, "gl_init: Container:" || l_container)
      CALL ui.Interface.setText(l_desc)
      CALL ui.Interface.setType("container")
      CALL ui.Interface.setName(l_container)
		OTHERWISE
			GL_DBGMSG(2, "gl_init: Not MDI")
  END CASE
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the style file depending on the client
FUNCTION g2_loadStyles(l_stName STRING) RETURNS()
  DEFINE l_fe, l_name STRING
	IF l_stName IS NULL THEN LET l_stName = "default" END IF
	LET l_fe = "GBC"
  IF m_isGDC THEN LET l_fe = "GDC" END IF
  IF m_isUniversal THEN LET l_fe = "GBC" END IF
	LET l_name = l_stName||"_"||l_fe
	TRY
 		CALL ui.interface.loadStyles(l_name)
	CATCH
 		LET l_name = l_stName
	END TRY
	TRY
 		CALL ui.interface.loadStyles(l_name)
	CATCH
 		LET l_name = "FAILED!"
	END TRY
  GL_DBGMSG(0, SFMT("g2_loadStyles: file=%1 ", l_name ))
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the Action Defaults file depending on the client
FUNCTION g2_loadActions(l_adName STRING) RETURNS()
	IF l_adName IS NULL THEN LET l_adName = "default" END IF
	TRY
		CALL ui.Interface.loadActionDefaults( l_adName )
	CATCH
		LET l_adName = "default"
	END TRY
	TRY
		CALL ui.Interface.loadActionDefaults( l_adName )
	CATCH
		LET l_adName = "FAILED!"
	END TRY
  GL_DBGMSG(0, SFMT("g2_loadActions: file=%1 ", l_adName ))
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the ToolBar file depending on the client
FUNCTION g2_loadToolBar(l_tbName STRING) RETURNS()
	IF l_tbName IS NULL THEN LET l_tbName = "default" END IF
	TRY
		CALL ui.Interface.loadToolBar( l_tbName )
	CATCH
		LET l_tbName = "FAILED!"
	END TRY
  GL_DBGMSG(0, SFMT("g2_loadToolBar: file=%1 ", l_tbName ))
END FUNCTION
--------------------------------------------------------------------------------
#+ Load the TopMenu file depending on the client
FUNCTION g2_loadTopMenu(l_tmName STRING) RETURNS()
	DEFINE l_w ui.Window
	DEFINE l_f ui.Form
	LET l_w = ui.Window.getCurrent()
	IF l_w IS NOT NULL THEN	LET l_f = l_w.getForm() END IF
	IF l_tmName IS NULL THEN LET l_tmName = "default" END IF
	TRY
		IF l_f IS NOT NULL THEN
			CALL l_f.loadTopMenu( l_tmName )
		ELSE
			CALL ui.Interface.loadTopMenu( l_tmName )
		END IF
	CATCH
		LET l_tmName = "FAILED!"
	END TRY
  GL_DBGMSG(0, SFMT("g2_loadTopMenu: file=%1 ", l_tmName ))
END FUNCTION
--------------------------------------------------------------------------------
#+ Generic Windows message Dialog.  NOTE: This handles messages when there is
#+ no window!
#+
#+ @param l_title     = Window Title
#+ @param l_message   = Message text
#+ @param l_icon      = Icon name, "exclamation"
#+ @return none
FUNCTION g2_winMessage(l_title STRING, l_message STRING, l_icon STRING) RETURNS()
  DEFINE l_win ui.window
  IF l_title IS NULL THEN
    LET l_title = "No Title!"
  END IF
  IF l_message IS NULL THEN
    LET l_message = "Message was NULL!!\n" || base.Application.getStackTrace()
  END IF

  LET l_win = ui.window.getcurrent()
  IF l_win IS NULL THEN -- Needs a current window or dialog doesn't work!!
    OPEN WINDOW dummy AT 1, 1 WITH 1 ROWS, 1 COLUMNS
		CALL ui.Window.getCurrent().setText(" ") -- clear default window title to avoid 'dummy' showing in gbc.
  END IF
  IF l_icon = "exclamation" THEN
    ERROR ""
  END IF -- Beep

  GL_DBGMSG(2, "gl_winMessage: " || NVL(l_message, "gl_winMessage passed NULL!"))
  MENU l_title ATTRIBUTES(STYLE = "dialog", COMMENT = l_message, IMAGE = l_icon)
    COMMAND "Okay"
      EXIT MENU
  END MENU

  IF l_win IS NULL THEN
    CLOSE WINDOW dummy
  END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Generic Windows Question Dialog
#+
#+ @param l_title Window Title
#+ @param l_message Message text
#+ @param l_ans   Default Answer
#+ @param l_items List of Answers ie "Yes|No|Cancel"
#+ @param l_icon  Icon name, "exclamation"
#+ @return string: Entered value.
FUNCTION g2_winQuestion(
    l_title STRING, l_message STRING, l_ans STRING, l_items STRING, l_icon STRING)
    RETURNS STRING
  DEFINE l_result STRING
  DEFINE l_toks base.STRINGTOKENIZER
  DEFINE l_dum BOOLEAN
  DEFINE l_opt DYNAMIC ARRAY OF STRING
  DEFINE x SMALLINT

  LET l_icon = l_icon.trim()
  LET l_title = l_title.trim()
  LET l_message = l_message.trim()
  LET l_icon = l_icon.trim()
  IF l_icon = "info" THEN
    LET l_icon = "information"
  END IF

  LET l_toks = base.StringTokenizer.create(l_items, "|")
  IF NOT l_toks.hasMoreTokens() THEN
    RETURN NULL
  END IF
  WHILE l_toks.hasMoreTokens()
    LET l_opt[l_opt.getLength() + 1] = l_toks.nextToken()
  END WHILE
	FOR x = l_opt.getLength()+1 TO 10
		LET l_opt[x] = "__"||x
	END FOR

  -- Handle the case when there is no current window
  LET l_dum = FALSE
  IF ui.window.getCurrent() IS NULL THEN
    OPEN WINDOW dummy AT 1, 1 WITH 1 ROWS, 2 COLUMNS ATTRIBUTE(STYLE = "naked")
    CALL ui.Window.getCurrent().setText(l_title)
    LET l_dum = TRUE
  END IF

  MENU l_title ATTRIBUTE(STYLE = "dialog", COMMENT = l_message, IMAGE = l_icon)
    BEFORE MENU
      FOR x = 1 TO 10
				CALL DIALOG.setActionHidden(l_opt[x].toLowerCase(), IIF(l_opt[x].subString(1,2) = "__",TRUE,FALSE))
        IF l_opt[x] IS NOT NULL THEN
          IF l_ans.equalsIgnoreCase(l_opt[x]) THEN
            NEXT OPTION l_opt[x]
          END IF
        END IF
      END FOR
    COMMAND l_opt[1]
      LET l_result = l_opt[1]
    COMMAND l_opt[2]
      LET l_result = l_opt[2]
    COMMAND l_opt[3]
      LET l_result = l_opt[3]
    COMMAND l_opt[4]
      LET l_result = l_opt[4]
    COMMAND l_opt[5]
      LET l_result = l_opt[5]
    COMMAND l_opt[6]
      LET l_result = l_opt[6]
    COMMAND l_opt[7]
      LET l_result = l_opt[7]
    COMMAND l_opt[8]
      LET l_result = l_opt[8]
    COMMAND l_opt[9]
      LET l_result = l_opt[9]
    COMMAND l_opt[10]
      LET l_result = l_opt[10]
  END MENU
  IF l_dum THEN
    CLOSE WINDOW dummy
  END IF
  RETURN l_result
END FUNCTION
--------------------------------------------------------------------------------
#+ Simple message with ui refresh
#+
#+ @return Nothing
FUNCTION g2_message(l_msg STRING) --{{{
  MESSAGE NVL(l_msg,"NULL")
	CALL ui.Interface.refresh()
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Simple error message
#+
#+ @return Nothing.
FUNCTION g2_errPopup(l_msg STRING)
  CALL g2_winMessage(% "Error!", l_msg, "exclamation")
END FUNCTION
--------------------------------------------------------------------------------
#+ Simple error message
#+
#+ @return Nothing
FUNCTION g2_warnPopup(l_msg STRING) --{{{
  CALL g2_winMessage(% "Warning!", l_msg, "exclamation")
END FUNCTION --}}}
--------------------------------------------------------------------------------
#+ Display an error message in a window, console & logfile.
#+
#+ @param l_fil __FILE__ - File name
#+ @param l_lno __LINE__ - Line Number
#+ @param l_err Error Message.
#+ @return Nothing.
FUNCTION g2_errMsg(l_fil STRING, l_lno INT, l_err STRING)

  CALL g2_errPopup(l_err)
  ERROR "* ", l_err.trim(), " *"
  IF l_fil IS NOT NULL THEN
    DISPLAY l_fil.trim(), ":", l_lno, ": ", l_err.trim()
    CALL ERRORLOG(l_fil.trim() || ":" || l_lno || ": " || l_err)
  END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Cleanly exit program, setting exit status.
#+
#+ @param stat Exit status 0 or -1 normally.
#+ @param reason For Exit, clean, crash, closed, terminated etc
#+ @return none
FUNCTION g2_exitProgram(l_stat SMALLINT, l_reason STRING)
  GL_DBGMSG(0, SFMT("g2_exitProgram: stat=%1 reason:%2", l_stat, l_reason))
  EXIT PROGRAM l_stat
END FUNCTION
--------------------------------------------------------------------------------
#+ On Application Close
FUNCTION g2_appClose()
  GL_DBGMSG(1, "g2_appClose")
  CALL g2_exitProgram(0, "Closed")
END FUNCTION
--------------------------------------------------------------------------------
#+ On Application Terminalate ( kill -15 )
FUNCTION g2_appTerm()
  GL_DBGMSG(1, "g2_appTerm")
  TRY
    ROLLBACK WORK
  CATCH
  END TRY
  CALL g2_exitProgram(0, "Terminated")
END FUNCTION
--------------------------------------------------------------------------------
#+ Check the client for it's vesion
#+
FUNCTION g2_chkClientVer(l_cli STRING, l_ver STRING, l_feature STRING) RETURNS BOOLEAN
  DEFINE l_fe_major DECIMAL(4, 2)
  DEFINE l_fe_minor SMALLINT
  DEFINE l_ck_major DECIMAL(4, 2)
  DEFINE l_ck_minor SMALLINT

  -- if client doesn't match just return true
  IF NOT m_isGDC THEN RETURN TRUE END IF

  CALL g2_getVer( ui.Interface.getFrontEndVersion() ) RETURNING l_fe_major, l_fe_minor
  CALL g2_getVer(l_ver) RETURNING l_ck_major, l_ck_minor

  IF l_fe_major < l_ck_major OR (l_fe_major = l_ck_major AND l_fe_minor < l_ck_minor) THEN
    -- client matched by version is too old
    CALL g2_winMessage(
        "Error",
        SFMT("Your Client version doesn't support feature '%1'!\nNeed min version of %2",
            l_feature, l_ver),
        "exclamation")
    RETURN FALSE
  END IF
  RETURN TRUE
END FUNCTION
--------------------------------------------------------------------------------
-- Break the Version string into major and minor
FUNCTION g2_getVer(l_str STRING) RETURNS(DECIMAL(4, 2), INT)
  DEFINE l_major DECIMAL(4, 2)
  DEFINE l_minor SMALLINT
  DEFINE l_st base.StringTokenizer
  LET l_minor = l_str.getIndexOf("-", 1)
  IF l_minor > 0 THEN
    LET l_str = l_str.subString(1, l_minor - 1)
  END IF
  LET l_st = base.StringTokenizer.create(l_str, ".")
  IF l_st.countTokens() != 3 THEN
    RETURN 0, 0
  END IF
  LET l_minor = l_st.nextToken()
  LET l_major = l_minor
  LET l_minor = l_st.nextToken()
  LET l_major = l_major + (l_minor / 100)
  LET l_minor = l_st.nextToken()
  --DISPLAY "Maj:",l_major," Min:",l_minor
  RETURN l_major, l_minor
END FUNCTION
--------------------------------------------------------------------------------
#+ Default error handler
#+
#+ @return Nothing
FUNCTION g2_error()
  DEFINE l_err, l_mod STRING
  DEFINE l_stat INTEGER
  DEFINE x, y SMALLINT

  LET l_stat = STATUS

  LET l_mod = base.Application.getStackTrace()
  LET x = l_mod.getIndexOf("#", 2) + 3
  LET y = l_mod.getIndexOf("#", x + 1) - 1
  LET l_mod = l_mod.subString(x, y)
  IF y < 1 THEN
    LET y = l_mod.getLength()
  END IF
  LET l_mod = l_mod.subString(x, y)
  IF l_mod IS NULL THEN
    GL_DBGMSG(0, "failed to get module from stackTrace!\n" || base.Application.getStackTrace())
    LET l_mod = "(null module)"
  END IF

  LET l_err = SQLERRMESSAGE || "\n"
  IF l_err IS NULL THEN
    LET l_err = ERR_GET(l_stat)
  END IF
  IF l_err IS NULL THEN
    LET l_err = "Unknown!"
  END IF
  LET l_err = l_stat || ":" || l_err || l_mod
--  CALL gl_logIt("Error:"||l_err)
  IF l_stat != -6300 THEN
    CALL g2_errPopup(l_err)
  END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Get the product version from the $FGLDIR/etc/fpi-fgl
#+ @param l_prod String of product name, eg: fglrun
#+ @return String or NULL
FUNCTION g2_getProductVer(l_prod STRING) RETURNS STRING
  DEFINE l_file base.channel
  DEFINE l_line STRING
  LET l_file = base.channel.create()
  CALL l_file.openPipe("fpi -l", "r")
  WHILE NOT l_file.isEof()
    LET l_line = l_file.readLine()
    IF l_line.getIndexOf(l_prod, 1) > 0 THEN
      LET l_line = l_line.subString(8, l_line.getLength() - 1)
      EXIT WHILE
    END IF
  END WHILE
  CALL l_file.close()
  RETURN l_line
END FUNCTION
--------------------------------------------------------------------------------
#+ Attempt to convert a String to a date
#+
#+ @param l_str A string containing a date
#+ @returns DATE or NULL
FUNCTION g2_strToDate(l_str STRING) RETURNS DATE
  DEFINE l_date DATE
  TRY
    LET l_date = l_str
  CATCH
  END TRY
  IF l_date IS NOT NULL THEN
    RETURN l_date
  END IF
  LET l_date = util.Date.parse(l_str, "dd/mm/yyyy")
  RETURN l_date
END FUNCTION
--------------------------------------------------------------------------------
#+ Return the result from the uname commend on Unix / Linux / Mac.
#+
#+ @return uname of the OS
FUNCTION g2_getUname() RETURNS STRING
  DEFINE l_uname STRING
  DEFINE c base.channel
  LET c = base.channel.create()
  CALL c.openPipe("uname", "r")
  LET l_uname = c.readLine()
  CALL c.close()
  RETURN l_uname
END FUNCTION
--------------------------------------------------------------------------------
#+ Return the Linux Version
#+
#+ @return OS Version
FUNCTION g2_getLinuxVer() RETURNS STRING
  DEFINE l_ver STRING
  DEFINE c base.channel
  DEFINE l_file DYNAMIC ARRAY OF STRING
  DEFINE x SMALLINT

-- possible files containing version info
  LET l_file[l_file.getLength() + 1] = "/etc/issue.net"
  LET l_file[l_file.getLength() + 1] = "/etc/issue"
  LET l_file[l_file.getLength() + 1] = "/etc/debian_version"
  LET l_file[l_file.getLength() + 1] = "/etc/SuSE-release"

-- loop thru and see which ones exist
  FOR x = 1 TO l_file.getLength() + 1
    IF l_file[x] IS NULL THEN
      RETURN "Unknown"
    END IF
    IF os.Path.exists(l_file[x]) THEN
      EXIT FOR
    END IF
  END FOR

-- read the first line of existing file
  LET c = base.channel.create()
  CALL c.openFile(l_file[x], "r")
  LET l_ver = c.readLine()
  CALL c.close()
  RETURN l_ver
END FUNCTION
--------------------------------------------------------------------------------
#+ Splash Screen
#+
#+ @param l_dur > 0 for sleep then close, 0=just open window, -1=close window
#+ @param l_splashImage Image file name
#+ @return Nothing.
FUNCTION g2_splash(l_dur SMALLINT, l_splashImage STRING) --{{{
  DEFINE f, g, n om.DomNode

  IF l_dur = -1 THEN
    CLOSE WINDOW splash
    RETURN
  END IF

  GL_DBGMSG(4, "Doing splash.")
  OPEN WINDOW splash
      AT 1, 1
      WITH 1 ROWS, 1 COLUMNS
      ATTRIBUTE(STYLE = "default noborder dialog2 bg_white")
  LET f = ui.window.getCurrent().createForm("splash").getNode()
  LET g = f.createChild("Grid")
  LET n = g.createChild("Image")
  CALL n.setAttribute("name", "logo")
  CALL n.setAttribute("style", "noborder")
  CALL n.setAttribute("width", "36")
  CALL n.setAttribute("height", "8")
  CALL n.setAttribute("image", l_splashImage)
  CALL n.setAttribute("posY", "0")
  CALL n.setAttribute("posX", "0")
  CALL n.setAttribute("gridWidth", "40")
  CALL n.setAttribute("gridHeight", "8")
  CALL n.setAttribute("height", "200px")
  CALL n.setAttribute("width", "570px")
  CALL n.setAttribute("stretch", "both")
  CALL n.setAttribute("autoScale", "1")
  CALL ui.interface.refresh()

  IF l_dur > 0 THEN
    SLEEP l_dur
    CLOSE WINDOW splash
  END IF
  GL_DBGMSG(4, "Done splash.")
END FUNCTION --}}}
