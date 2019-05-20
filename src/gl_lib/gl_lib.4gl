
PUBLIC DEFINE m_mdi CHAR(1)
PUBLIC DEFINE m_isUniversal BOOLEAN
PUBLIC DEFINE m_isGDC BOOLEAN

FUNCTION gl_init(l_mdi_sdi CHAR(1), l_sty STRING)
	DEFINE l_container, l_desc STRING
  DEFINE l_fe STRING

  CALL STARTLOG( base.Application.getProgramDir()||".err")
  WHENEVER ANY ERROR CALL gl_error

	LET m_isGDC = FALSE
	LET m_isUniversal = FALSE
	IF ui.Interface.getFrontEndName() = "GDC" THEN LET m_isGDC = TRUE END IF
--	IF ui.Interface.getUniversalClientName() = "GBC" THEN LET m_isUniversal = TRUE END IF

	IF l_sty IS NULL THEN LET l_sty = "default" END IF
  IF m_isGDC THEN LET l_fe = "GDC" END IF
  IF m_isUniversal THEN LET l_fe = "GBC" END IF

	TRY
 		CALL ui.interface.loadStyles(l_sty || "_" || l_fe)
	CATCH
 		CALL ui.interface.loadStyles(l_sty)
	END TRY

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

      CALL ui.Interface.setType("child")
      CALL ui.Interface.setContainer(l_container)
    WHEN "M" -- MDI Container

      CALL ui.Interface.setText(l_desc)
      CALL ui.Interface.setType("container")
      CALL ui.Interface.setName(l_container)
		OTHERWISE

  END CASE
END FUNCTION
--------------------------------------------------------------------------------
#+ Default error handler
#+
#+ @return Nothing
FUNCTION gl_error()
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
    DISPLAY l_err
  END IF

END FUNCTION
--------------------------------------------------------------------------------
#+ Process the status after an SQL Statement.
#+
#+ @code CALL g2_db_sqlStatus( __LINE__, "gl_db", l_sql_stmt )
#+
#+ @param l_tab Table name
#+ @param l_defcol Default column
#+ @param l_search Search string
#+ @return a String containing a where clause
FUNCTION gl_chkSearch(l_tab STRING, l_defcol STRING, l_search STRING) RETURNS STRING
	DEFINE l_where, l_stmt, l_cond STRING
	DEFINE l_cnt INTEGER
	IF l_search IS NULL OR l_tab IS NULL THEN RETURN "1=1" END IF
	LET l_search = l_search.trim()
	IF l_search.getIndexOf(";",1) > 0 THEN LET l_search = l_search.subString(1,l_cnt) END IF
	LET l_cond = "MATCHES"
	LET l_where = SFMT("lower(%1) %2 '*%3*'",l_defcol, l_cond,l_search.toLowerCase())
	DISPLAY "Search:",l_search
	DISPLAY "       12345678901234567890"
	CALL gl_findCondition( l_search ) RETURNING l_cnt, l_cond
	IF l_cnt = 1 THEN
		LET l_search = l_search.subString(l_cond.getLength()+1, l_search.getLength())
		LET l_where = SFMT("lower(%1) %2 '%3'",l_defcol.trim(), l_cond,l_search.toLowerCase())
	END IF
	IF l_cnt > 1 THEN
		LET l_defcol = l_search.subString(1,l_cnt-1)
		LET l_search = l_search.subString(l_cnt+l_cond.getLength(), l_search.getLength())
		LET l_where = SFMT("%1 %2 '%3'",l_defcol.trim(), l_cond, l_search.trim())
	END IF
	DISPLAY "X:",l_cnt," Col:",l_defcol, " Condition:",l_cond," Search:",l_search
	LET l_stmt = "SELECT COUNT(*) FROM "||l_tab||" WHERE "||l_where
	DISPLAY l_stmt
	TRY
		PREPARE pre_chk FROM l_stmt
		EXECUTE pre_chk INTO l_cnt
	CATCH
		CALL fgl_winMessage("SQL Error",SFMT("%1 %2",STATUS, SQLERRMESSAGE),"exclamation")
		LET l_where = NULL
	END TRY
	IF l_cnt = 0 THEN
		ERROR SFMT("No rows found for search '%1'",l_search)
		LET l_where = NULL
	END IF
	RETURN l_where
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gl_findCondition(l_search STRING) RETURNS (INT,STRING)
	DEFINE x INTEGER
	LET x = l_search.getIndexOf(">",1)
	IF x > 0 THEN RETURN x,">" END IF
	LET x = l_search.getIndexOf("<",1)
	IF x > 0 THEN RETURN x,"<" END IF
	LET x = l_search.getIndexOf("!=",1)
	IF x > 0 THEN RETURN x,"!=" END IF
	LET x = l_search.getIndexOf("<>",1)
	IF x > 0 THEN RETURN x,"<>" END IF
	LET x = l_search.getIndexOf("=",1)
	IF x > 0 THEN RETURN x,"=" END IF
	RETURN 0, NULL
END FUNCTION