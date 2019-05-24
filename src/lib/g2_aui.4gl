--------------------------------------------------------------------------------
#+ Genero AUI Functions - by Neil J Martin ( neilm@4js.com )
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
IMPORT util
IMPORT FGL g2_lib
&include "g2_debug.inc"

DEFINE m_gl_winInfo BOOLEAN
--------------------------------------------------------------------------------
#+ Return the node for a named window.
#+
#+ @param l_nam The name of window, if null current window node is returned.
#+ @return ui.Window.
FUNCTION g2_getWinNode(l_nam STRING) RETURNS om.DomNode
  DEFINE l_win ui.Window
  DEFINE l_ret om.DomNode
  IF l_nam IS NULL THEN
    LET l_win = ui.Window.getCurrent()
    LET l_nam = "SCREEN"
  ELSE
    LET l_win = ui.Window.forName(l_nam)
  END IF
  IF l_win IS NULL THEN
    CALL g2_lib.g2_errMsg(__FILE__, __LINE__, SFMT(% "lib.getwinnode.error", l_nam))
    RETURN l_ret -- l_ret is null here
  ELSE
    LET l_ret = l_win.getNode()
  END IF
  RETURN l_ret
END FUNCTION
--------------------------------------------------------------------------------
#+ Return the form NODE for the named form.
#+
#+ @param l_nam name of Form, if null current Form node is returned.
#+ @return Node.
FUNCTION g2_getFormNode(l_nam STRING) RETURNS om.DomNode
  DEFINE l_frm ui.Form
  DEFINE nl om.nodeList
  DEFINE n om.domNode

  LET l_frm = g2_getForm(NULL)
  IF l_nam IS NULL THEN
    IF l_frm IS NULL THEN
      RETURN NULL
    END IF
    LET n = l_frm.getNode()
  ELSE
    LET n = ui.Interface.getRootNode()
    LET nl = n.selectByPath("//Form[@name='" || l_nam.trim() || "']")
    IF nl.getLength() < 1 THEN
      CALL g2_errMsg(
          __FILE__, __LINE__, "g2_getFormNode: Form not found '" || l_nam.trim() || "'!")
      RETURN NULL
    ELSE
      LET n = nl.item(1)
    END IF
  END IF

  RETURN n
END FUNCTION
--------------------------------------------------------------------------------
#+ Return the form object for the named form.
#+
#+ @param l_nam name of Form, if null current Form object is returned.
#+ @return ui.Form.
FUNCTION g2_getForm(l_nam STRING) RETURNS ui.Form
  DEFINE l_win ui.Window
  DEFINE l_frm ui.Form

  IF l_nam IS NULL THEN
    LET l_win = ui.Window.getCurrent()
    LET l_frm = l_win.getForm()
  ELSE
    -- not written yet!
  END IF

  RETURN l_frm
END FUNCTION
--------------------------------------------------------------------------------
#+ Dynamically generate a form object & return it's node.
#+
#+ @param l_nam name of Form, Should not be NULL!
#+ @return ui.Form.
FUNCTION g2_genForm(l_nam STRING) RETURNS om.DomNode
  DEFINE l_win ui.Window
  DEFINE l_frm ui.Form
  DEFINE l_n om.DomNode

  LET l_win = ui.Window.getCurrent()
  IF l_win IS NULL THEN
    CALL g2_lib.g2_errMsg(__FILE__, __LINE__, SFMT(% "genForm: failed to get Window '%1'", "CURRENT"))
    RETURN l_n
  END IF

  LET l_frm = l_win.createForm(l_nam)
  IF l_frm IS NULL THEN
    CALL g2_lib.g2_errMsg(__FILE__, __LINE__, SFMT(% "genForm: createForm('%1') failed !!", l_nam))
    RETURN l_n
  END IF
  LET l_n = l_frm.getNode()

  RETURN l_n
END FUNCTION
--------------------------------------------------------------------------------
#+ Generic Window notify message.
#+
#+ @param msg   = String: Message text
#+ @return none
FUNCTION g2_notify( l_msg STRING ) RETURNS()
  DEFINE frm, g om.domNode

  IF l_msg IS NULL THEN
    CLOSE WINDOW notify
    RETURN
  ELSE
    OPEN WINDOW notify AT 1, 1 WITH 1 ROWS, 2 COLUMNS ATTRIBUTES(STYLE = "naked")
  END IF

  LET frm = g2_genForm("myprompt")

-- create the grid, label, formfield and edit/dateedit nodes.
  LET g = frm.createChild('Grid')
  CALL g.setAttribute("height", "4")
  CALL g.setAttribute("width", l_msg.getLength() + 1)
  CALL g.setAttribute("gridWidth", l_msg.getLength() + 1)
  CALL g2_addLabel(g, 1, 2, l_msg, NULL, "big")
  GL_DBGMSG(1, "g2_notify" || l_msg)
  CALL ui.interface.refresh()

END FUNCTION
--------------------------------------------------------------------------------
#+ Show the Genero & GRE license
#+
FUNCTION g2_showLicence() RETURNS()
  DEFINE licstring STRING
  DEFINE winnode, frm, g, frmf, txte om.DomNode
  DEFINE c base.Channel

  OPEN WINDOW lic WITH 1 ROWS, 1 COLUMNS
  LET winnode = g2_getWinNode(NULL)
  CALL winnode.setAttribute("style", "naked")
  CALL winnode.setAttribute("width", 80)
  CALL winnode.setAttribute("height", 20)
  CALL winnode.setAttribute("text", "Licence Info")
  LET frm = g2_genForm("help")

  LET g = frm.createChild('Grid')
  CALL g.setAttribute("width", 80)
  CALL g.setAttribute("height", 20)

  LET frmf = g.createChild('FormField')
  CALL frmf.setAttribute("colName", "licstring")
  LET txte = frmf.createChild('TextEdit')
  CALL txte.setAttribute("gridWidth", 80)
  CALL txte.setAttribute("gridHeight", 20)

  CALL ui.interface.refresh()

  LET c = base.Channel.create()
  CALL c.openPipe("fglWrt -a info 2>&1", "r")
  DISPLAY "Status:", STATUS
  LET licString = "fglWrt -a info:\n"
  WHILE NOT c.isEof()
    LET licstring = licstring.append(c.readLine() || "\n")
  END WHILE
  CALL c.close()

  CALL c.openPipe("greWrt -a info 2>&1", "r")
  LET licString = licString.append("\n\ngreWrt -a info:\n")
  WHILE NOT c.isEof()
    LET licstring = licstring.append(c.readLine() || "\n")
  END WHILE
  CALL c.close()

  DISPLAY "Lic:", licstring.trim()
  DISPLAY BY NAME licstring

  MENU
    COMMAND "close"
      EXIT MENU
    COMMAND "cancel"
      EXIT MENU
  END MENU

  CLOSE WINDOW lic
END FUNCTION
--------------------------------------------------------------------------------
#+ Show ReadMe local file
#+
#+ @return none
FUNCTION g2_showReadMe() RETURNS()
  DEFINE vb, frm, g, ff, t om.DomNode
  DEFINE txt STRING
  DEFINE c base.Channel

  LET c = base.channel.create()
  LET txt = fgl_getenv("README")
  IF txt IS NULL THEN
    LET txt = "readme.txt"
  END IF
  TRY
    CALL c.openFile(txt, "r")
  CATCH
    CALL g2_winMessage(
        "ReadMe", SFMT(% "Open '%1' failed\n%2.", txt, err_get(STATUS)), "information")
    RETURN
  END TRY

  LET txt = "ReadMe.txt:\n"
  WHILE NOT c.isEOF()
    LET txt = txt.append(c.readLine() || "\n")
  END WHILE
  CALL c.close()

  OPEN WINDOW showRM AT 1, 1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTES(STYLE = "naked")
  LET frm = g2_genForm("showRM")
  CALL ui.Window.getCurrent().setText("Read Me")
  LET vb = frm.createChild("VBox")
  LET g = vb.createChild("Grid")
  LET ff = g.createChild("FormField")
  CALL ff.setATtribute("colName", "txt")
  LET t = ff.createChild("TextEdit")
  CALL t.setATtribute("scroll", "both")
  CALL t.setATtribute("stretch", "both")
  CALL t.setATtribute("gridWidth", "80")
  CALL t.setATtribute("height", "60")

  DISPLAY BY NAME txt
  MENU
    ON ACTION close
      EXIT MENU
    ON ACTION exit
      EXIT MENU
  END MENU
  CLOSE WINDOW showRM

END FUNCTION
--------------------------------------------------------------------------------
#+ Show Environment variables in a dynamic table.
#+ @return none
FUNCTION g2_showEnv() RETURNS()
  DEFINE vb, frm, w, tabl, tabc om.DomNode
  DEFINE x, val_w, txt_w SMALLINT
  DEFINE env DYNAMIC ARRAY OF RECORD
    nam STRING,
    val STRING
  END RECORD
--TODO: maybe read list of environment variables from a file?
  LET env[env.getLength() + 1].nam = "FGLDIR"
  LET env[env.getLength() + 1].nam = "FGLASDIR"
  LET env[env.getLength() + 1].nam = "FGLSERVER"
  LET env[env.getLength() + 1].nam = "FGLLDPATH"
  LET env[env.getLength() + 1].nam = "FGLRESOURCEPATH"
  LET env[env.getLength() + 1].nam = "FGLIMAGEPATH"
  LET env[env.getLength() + 1].nam = "FGLPROFILE"
  LET env[env.getLength() + 1].nam = "FGLRUN"
  LET env[env.getLength() + 1].nam = "GREDIR"

  LET env[env.getLength() + 1].nam = "FGLDBPATH"
  LET env[env.getLength() + 1].nam = "FGLSQLDEBUG"

  LET env[env.getLength() + 1].nam = "DBPATH"
  LET env[env.getLength() + 1].nam = "DBDATE"
  LET env[env.getLength() + 1].nam = "DBCENTURY"

  LET env[env.getLength() + 1].nam = "INFORMIXDIR"
  LET env[env.getLength() + 1].nam = "INFORMIXSERVER"
  LET env[env.getLength() + 1].nam = "INFORMIXSQLHOSTS"

  LET env[env.getLength() + 1].nam = "ANTSHOME"
  LET env[env.getLength() + 1].nam = "ANTS_DSN"

  LET env[env.getLength() + 1].nam = "PATH"
  LET env[env.getLength() + 1].nam = "LD_LIBRARY_PATH"

  LET env[env.getLength() + 1].nam = "TEMP"
  LET env[env.getLength() + 1].nam = "TMP"

  LET env[env.getLength() + 1].nam = "LANG"
  LET env[env.getLength() + 1].nam = "LOCALE"
  LET env[env.getLength() + 1].nam = "HOSTNAME"
  LET env[env.getLength() + 1].nam = "RHOSTNAME"

  LET env[env.getLength() + 1].nam = "FGL_PRIVATE_DIR"
  LET env[env.getLength() + 1].nam = "FGL_PRIVATE_URL_PREFIX"
  LET env[env.getLength() + 1].nam = "FGL_PUBLIC_DIR"
  LET env[env.getLength() + 1].nam = "FGL_PUBLIC_IMAGEPATH"
  LET env[env.getLength() + 1].nam = "FGL_PUBLIC_URL_PREFIX"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_APPLICATION_ID"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_AUTO_LOGOUT"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_COMMAND_DIR"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_COMMAND_LINE"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_CONNECTOR_URI"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_DVM_AVAILABLE"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_GAS_ADDRESS"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_LOG_DAILYFILE"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_LOG_DAILYFILE_CATEGORIES_FILTER"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_LOG_DAILYFILE_FORMAT"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_LOG_DAILYFILE_PATH"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_LOG_DAILYFILE_RAW_DATA_MAX_LENGTH"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_PROXY"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_REQUEST_RESULT"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_SESSION_ID"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_TEMPORARY_DIRECTORY"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_USER_AGENT"
  LET env[env.getLength() + 1].nam = "FGL_VMPROXY_WEB_COMPONENT_LOCATION"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTPS"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_ACCEPT"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_ACCEPT_ENCODING"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_ACCEPT_LANGUAGE"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_CONNECTION"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_COOKIE"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_HOST"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_REFERER"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_HTTP_USER_AGENT"
  LET env[env.getLength() + 1].nam = "FGL_WEBSERVER_REMOTE_ADDR"

  FOR x = 1 TO env.getLength()
    LET env[x].val = fgl_getenv(env[x].nam)
    IF env[x].nam.getLength() > txt_w THEN
      LET txt_w = env[x].nam.getLength()
    END IF
    IF env[x].val.getLength() > val_w THEN
      LET val_w = env[x].val.getLength()
    END IF
  END FOR

  OPEN WINDOW showEnv AT 1, 1 WITH 1 ROWS, 1 COLUMNS ATTRIBUTES(STYLE = "naked")
  LET frm = g2_genForm("showEnv")
  CALL ui.Window.getCurrent().setText("Current Environment")
  LET vb = frm.createChild("VBox")
  LET tabl = vb.createChild("Table")
  CALL tabl.setAttribute("tabName", "showenv")
  CALL tabl.setAttribute("height", env.getLength() + 1)
  CALL tabl.setAttribute("pageSize", env.getLength() + 1)
  CALL tabl.setAttribute("posX", 1)
  CALL tabl.setAttribute("posY", 6)
  LET tabc = tabl.createChild('TableColumn')
  CALL tabc.setAttribute("colName", "nam")
  CALL tabc.setAttribute("text", "Name")
  LET w = tabc.createChild('Edit')
  CALL w.setAttribute("width", txt_w)
  LET tabc = tabl.createChild('TableColumn')
  CALL tabc.setAttribute("colName", "val")
  CALL tabc.setAttribute("text", "Value")
  LET w = tabc.createChild('Edit')
  CALL w.setAttribute("width", val_w)
  DISPLAY ARRAY env TO showenv.* ATTRIBUTE(COUNT = env.getLength())
  CLOSE WINDOW showEnv
END FUNCTION
--------------------------------------------------------------------------------
#+ Progressbar Routine.
#+ Example call:
#+ @code
#+ CALL g2_progBar(1,10,"Processing, please wait ...")   Open window and set max = 10
#+ FOR x = 1 TO 10
#+ 	CALL g2_progBar(2,x,NULL)  Move the bar to x position
#+ END FOR
#+ CALL g2_progBar(3,0,NULL)   Close the window
#+
#+ @param l_meth 1=Open Window / 2=Update bar / 3=Close Window
#+ @param l_curval 1=Max value for Bar / 2=Current value position for Bar / 3=Ignored.
#+ @param l_txt Text display below the bar in the window.
#+ @return Nothing.
FUNCTION g2_progBar(l_meth SMALLINT, l_curval INT, l_txt STRING) RETURNS()
  DEFINE l_win, l_frm, l_grid, l_frmf, l_pbar om.DomNode
-- open window and create form
  IF l_meth = 1 OR l_meth = 0 THEN
    OPEN WINDOW progbar WITH 1 ROWS, 50 COLUMNS
    LET l_win = g2_getWinNode(NULL)
    CALL l_win.setAttribute("style", "naked")
    CALL l_win.setAttribute("width", 45)
    CALL l_win.setAttribute("height", 2)
    LET l_frm = g2_genForm("gl_progbar")
    CALL l_frm.setAttribute("text", "ProgressBar")

    LET l_grid = l_frm.createChild('Grid')

    LET l_frmf = l_grid.createChild('FormField')
    CALL l_frmf.setAttribute("colName", "progress")
    CALL l_frmf.setAttribute("value", 0)
    LET l_pbar = l_frmf.createChild('ProgressBar')
    CALL l_pbar.setAttribute("width", 40)
    CALL l_pbar.setAttribute("posY", 1)
    CALL l_pbar.setAttribute("valueMax", l_curval)
    CALL l_pbar.setAttribute("valueMin", 1)

    CALL g2_addLabel(l_grid, 0, 2, l_txt, NULL, NULL)
    IF l_meth = 0 THEN
      LET l_grid = l_grid.createChild('HBox')
      CALL l_grid.setAttribute("posY", 3)
      LET l_frmf = l_grid.createChild('SpacerItem')
      LET l_frmf = l_grid.createChild('Button')
      CALL l_frmf.setAttribute("name", "cancel")
      LET l_frmf = l_grid.createChild('SpacerItem')
    END IF
  END IF
-- update the progressbar
  IF l_meth = 2 THEN
    DISPLAY l_curval TO progress
  END IF
-- close the window
  IF l_meth = 3 THEN
    CLOSE WINDOW progbar
  END IF

  CALL ui.interface.refresh()

END FUNCTION
--------------------------------------------------------------------------------
#+ Generic Windows info popup window.
#+ Example call:
#+ @code
#+ CALL g2_winInfo(1,"Processing, Please Wait ...","info")
#+ CALL doProcess()
#+ CALL g2_winInfo(3,"","")
#+
#+ @param l_meth 1=Open Window / 2=Message / 3=Close Window
#+ @param l_txt The Message
#+ @param l_icon Optional Icon
#+ @return Nothing.
FUNCTION g2_winInfo(l_meth SMALLINT, l_txt STRING, l_icon STRING) RETURNS()
  DEFINE l_win, l_frm, l_grid, l_frmf, l_msg om.DomNode
  DEFINE l_len SMALLINT
-- open window and create form
  IF l_meth = 1 AND NOT m_gl_winInfo THEN
    OPEN WINDOW gl_winInfo WITH 1 ROWS, 50 COLUMNS
    LET l_len = l_txt.getLength() + 10
    IF l_len < 40 THEN
      LET l_len = 40
    END IF
    LET l_win = g2_getWinNode(NULL)
    CALL l_win.setAttribute("style", "naked")
    CALL l_win.setAttribute("width", l_len + 2)
    CALL l_win.setAttribute("height", 3)
    LET l_frm = g2_genForm("g2_wininfo")
    CALL l_frm.setAttribute("text", "Info")

    LET l_grid = l_frm.createChild('Grid')

    IF l_icon IS NOT NULL THEN
      LET l_msg = l_grid.createChild('Image')
      CALL l_msg.setAttribute("width", 1)
      CALL l_msg.setAttribute("posX", 1)
      CALL l_msg.setAttribute("image", l_icon)
      CALL l_msg.setAttribute("style", "noborder")
    END IF

    LET l_frmf = l_grid.createChild('FormField')
    CALL l_frmf.setAttribute("colName", "message")
    CALL l_frmf.setAttribute("value", 0)
    LET l_msg = l_frmf.createChild('Label')
    CALL l_msg.setAttribute("width", l_len)
    CALL l_msg.setAttribute("posX", 2)
    CALL l_msg.setAttribute("sizePolicy", "dynamic")

    LET m_gl_winInfo = TRUE
  END IF

  IF l_meth < 3 AND m_gl_winInfo THEN
    -- update the message
    CURRENT WINDOW IS gl_winInfo
    DISPLAY l_txt TO message
  END IF

-- close the window
  IF l_meth = 3 AND m_gl_winInfo THEN
    LET m_gl_winInfo = FALSE
    CLOSE WINDOW gl_winInfo
  END IF

  CALL ui.interface.refresh()

END FUNCTION
--------------------------------------------------------------------------------
#+ Add a Field to a grid/group
#+
#+ @param f Node of the Grid or Group
#+ @param x X position
#+ @param y Y Position
#+ @param wgt Widget: Edit, ButtonEdit, ComboBox, DateEdit etc
#+ @param fld Text for label
#+ @param w Width
#+ @param com NULL or Comment
#+ @param j Justify : NULL, center or right
#+ @param s Style.
#+ @return nothing
FUNCTION g2_addField(
    f om.DomNode,
    x SMALLINT,
    y SMALLINT,
    wgt STRING,
    fld STRING,
    w SMALLINT,
    com STRING,
    j STRING,
    s STRING)
    RETURNS()
  DEFINE n om.domNode
  DEFINE h SMALLINT

  LET f = f.createChild("FormField")
  CALL f.setAttribute("name", fld)
  CALL f.setAttribute("colName", fld)
  LET n = f.createChild(wgt)
  CALL n.setAttribute("posX", x)
  CALL n.setAttribute("posY", y)
  IF w > 80 THEN
    LET h = w / 80
    LET w = 80
    CALL n.setAttribute("height", h)
  END IF
  CALL n.setAttribute("width", w)
  IF com IS NOT NULL THEN
    CALL n.setAttribute("comment", com)
  END IF
  IF j IS NOT NULL THEN
    CALL n.setAttribute("justify", j)
  END IF
  IF s IS NOT NULL THEN
    CALL n.setAttribute("style", s)
  END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Add a label to a grid/group
#+
#+ @param l Node of the Grid or Group
#+ @param x X position
#+ @param y Y Position
#+ @param txt Text for label
#+ @param j Justify : NULL, center or right
#+ @param s Style.
#+ @return nothing
FUNCTION g2_addLabel(
    l om.DomNode, x SMALLINT, y SMALLINT, txt STRING, j STRING, s STRING)
    RETURNS()

  LET l = l.createChild("Label")
  CALL l.setAttribute("posX", x)
  CALL l.setAttribute("posY", y)
  CALL l.setAttribute("text", txt)
  IF j IS NOT NULL THEN
    CALL l.setAttribute("justify", j)
  END IF
  IF s IS NOT NULL THEN
    CALL l.setAttribute("style", s)
  END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Add items to a RadioGroup or any node that has Item nodes
#+
#+ @param l_rad Parent node.
#+ @param l_val value
#+ @param l_txt Text
FUNCTION g2_addItem(l_rad om.DomNode, l_val STRING, l_txt STRING) RETURNS()
  DEFINE l_itm om.DomNode
  LET l_itm = l_rad.createChild("Item")
  CALL l_itm.setAttribute("name", l_val)
  CALL l_itm.setAttribute("text", l_txt)
END FUNCTION
