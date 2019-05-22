IMPORT os
IMPORT FGL g2_lib

-- From $GREDIR/lib
IMPORT FGL libgreprops
IMPORT FGL libgre

PUBLIC TYPE greRpt RECORD
		reportsDir STRING,
		rptName STRING,
		fileName STRING,
		device STRING,
		preview BOOLEAN,
		pageWidth SMALLINT,
		rptTitle STRING,
		handle om.SaxDocumentHandler
	END RECORD

FUNCTION ( this greRpt ) init(l_rptName STRING, l_preview BOOLEAN, l_device STRING) RETURNS BOOLEAN
	LET this.preview = l_preview
	LET this.device = l_device
	RETURN this.start(l_rptName)
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION ( this greRpt ) start(l_rptName STRING) RETURNS BOOLEAN
	LET this.rptName = l_rptName
  IF this.preview IS NULL THEN LET this.preview = FALSE END IF
	IF this.reportsDir IS NULL THEN LET this.reportsDir = fgl_getEnv("REPORTDIR") END IF
	IF this.reportsDir IS NULL THEN LET this.reportsDir = "../etc" END IF
  IF this.rptName IS NOT NULL THEN
		IF this.rptTitle IS NULL THEN LET this.rptTitle = l_rptName END IF
    LET this.rptName = os.path.join(this.reportsDir, this.rptName.append(".4rp") )
  END IF
	IF NOT os.path.exists(this.rptName) THEN
    CALL g2_lib.g2_winMessage("Error", SFMT("Report Design '%1' not found!",this.rptName), "exclamation")
    RETURN FALSE
	END IF
  IF NOT libgre.fgl_report_loadCurrentSettings(this.rptName) THEN
    CALL g2_lib.g2_winMessage("Error", "Report initialize failed!", "exclamation")
    RETURN FALSE
  END IF

  IF this.pageWidth > 80 THEN
    CALL libgreprops.fgl_report_configurePageSize("a4length", "a4width") -- Landscape
  ELSE
    CALL libgreprops.fgl_report_configurePageSize("a4width", "a4length") -- Portrait
  END IF

  IF this.device = "PDF" AND this.rptName IS NULL THEN
    CALL libgreprops.fgl_report_configureCompatibilityOutput(
        this.pageWidth, "Courier", TRUE, base.Application.getProgramName(), "", "")
  END IF

  IF this.device != "XML" THEN
    CALL libgreprops.fgl_report_selectDevice(this.device)
    CALL libgreprops.fgl_report_selectPreview(this.preview)
  END IF

  IF this.device = "Printer" THEN
    CALL libgreprops.fgl_report_setPrinterName(this.fileName)
  ELSE
    IF this.fileName IS NOT NULL THEN
      CALL libgreprops.fgl_report_setOutputFileName(this.fileName)
    END IF
  END IF
  -- Set the SAX handler
  IF this.device = "XML" THEN -- Just produce XML output
    LET this.handle = libgre.fgl_report_createProcessLevelDataFile(this.fileName)
  ELSE -- Produce a report using GRE
    LET this.handle = libgre.fgl_report_commitCurrentSettings()
  END IF
  MESSAGE SFMT("Printing Report %1, please wait ...", NVL(this.rptName,"ASCII") )
  CALL ui.Interface.refresh()

	RETURN TRUE
END FUNCTION
-------------------------------------------------------------------------------
FUNCTION ( this greRpt ) progress(l_row INTEGER, l_max INTEGER, l_mod SMALLINT) RETURNS ()
	DEFINE l_win, l_frm, l_grid, l_frmf, l_pbar om.DomNode
	IF l_row < 1 THEN
    OPEN WINDOW progbar WITH 1 ROWS, 50 COLUMNS
    LET l_win = ui.Window.getCurrent().getNode()
    CALL l_win.setAttribute("style","naked")
    CALL l_win.setAttribute("width",45)
    CALL l_win.setAttribute("height",2)
    LET l_frm = ui.Window.getCurrent().createForm("ProgBar").getNode()
    CALL l_win.setAttribute("text", SFMT("Printing '%1' ...", this.rptTitle))

    LET l_grid = l_frm.createChild('Grid')

    LET l_frmf = l_grid.createChild('FormField')
    CALL l_frmf.setAttribute("colName","progress")
    CALL l_frmf.setAttribute("value",0)
    LET l_pbar = l_frmf.createChild('ProgressBar')
    CALL l_pbar.setAttribute("width",40)
    CALL l_pbar.setAttribute("posY",1)
    CALL l_pbar.setAttribute("valueMax",l_max)
    CALL l_pbar.setAttribute("valueMin",1)

    IF l_row = -1 THEN
      LET l_grid = l_grid.createChild('HBox')
      CALL l_grid.setAttribute("posY",3)
      LET l_frmf = l_grid.createChild('SpacerItem')
      LET l_frmf = l_grid.createChild('Button')
      CALL l_frmf.setAttribute("name","cancel")
      LET l_frmf = l_grid.createChild('SpacerItem')
    END IF
  END IF

-- update the progressbar
  IF l_row > 0 THEN
    DISPLAY l_row TO progress
  END IF

	IF l_row = l_max THEN
		CLOSE WINDOW progbar
	END IF
	IF NOT l_row MOD l_mod THEN
--		DISPLAY l_row,":Refresh"
  	CALL ui.Interface.refresh()
	ELSE
--		DISPLAY l_row
	END IF
END FUNCTION
-------------------------------------------------------------------------------
FUNCTION ( this greRpt ) finish() RETURNS ()
	MESSAGE SFMT("Report %1 Finished.",  NVL(this.rptName,"ASCII"))
  CALL ui.Interface.refresh()
END FUNCTION
-------------------------------------------------------------------------------
FUNCTION ( this greRpt ) getOutput() RETURNS BOOLEAN
	DEFINE l_dest CHAR(1)
	LET int_flag = FALSE
  MENU "Report Destination"
      ATTRIBUTES(STYLE = "dialog", COMMENT = "Output report to ...", IMAGE = "question")
    COMMAND "File"
      LET l_dest = "F"
      LET this.device = "XML"
    COMMAND "File PDF"
      LET l_dest = "F"
      LET this.device = "PDF"
    COMMAND "Screen"
      LET l_dest = "S"
      LET this.device = "SVG"
      LET this.preview = TRUE
    COMMAND "Printer"
      LET l_dest = "P"
      LET this.device = "Printer"
    COMMAND "PDF"
      LET l_dest = "D"
      LET this.device = "PDF"
      LET this.preview = TRUE
    COMMAND "XLS"
      LET l_dest = "D"
      LET this.device = "XLS"
      LET this.preview = TRUE
    COMMAND "HTML"
      LET l_dest = "D"
      LET this.device = "HTML"
      LET this.preview = TRUE
    COMMAND "XLSX"
      LET l_dest = "F"
      LET this.device = "XLSX"
      LET this.preview = TRUE
    COMMAND "XML"
      LET l_dest = "F"
      LET this.device = "XML"
  END MENU
  IF int_flag THEN
    CALL g2_lib.g2_winMessage("Cancelled", "Report cancelled", "information")
   	RETURN FALSE
  END IF
  IF l_dest = "F" THEN
    PROMPT "Enter filename:" FOR this.fileName
    IF this.fileName IS NULL THEN
      LET this.fileName = base.Application.getProgramName()
    END IF
    IF this.fileName.getIndexOf(".", 1) < 1 THEN
      LET this.fileName = this.fileName.append("." || this.device.toLowerCase())
    END IF
  END IF
  IF int_flag THEN
    CALL g2_lib.g2_winMessage("Cancelled", "Report cancelled", "information")
    RETURN FALSE
  END IF
	RETURN TRUE
END FUNCTION
