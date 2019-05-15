# Library functions for Database Connection / Actions.
IMPORT os

IMPORT FGL g2_lib
&include "g2_debug.inc"

# See schema.inc - value should be the same!
CONSTANT DEF_DBNAME = "njm_demo310"

# Informix
CONSTANT DEF_DBDRIVER = "dbmifx9x"
CONSTANT DEF_DBSPACE = "dbs1"

# SQLServer
#CONSTANT DEF_DBDRIVER="dbmsnc90"

# MySQL
#CONSTANT DEF_DBDRIVER="dbmmys51x"

# SQLite
#CONSTANT DEF_DBDRIVER="dbmsqt3xx"
CONSTANT DEF_DBDIR = "../db"

PUBLIC TYPE dbInfo RECORD
	name STRING,
	type STRING,
	desc STRING,
	source STRING,
	driver STRING,
	dir STRING,
	dbspace STRING,
	connection STRING,
	create_db BOOLEAN
END RECORD

PUBLIC FUNCTION (this dbInfo) g2_connect(l_dbName STRING) RETURNS ()
  DEFINE l_msg STRING
  DEFINE l_lockMode, l_fglprofile BOOLEAN

  LET l_fglprofile = FALSE

-- setup stuff from environment or defaults
  IF l_dbName IS NULL OR l_dbName = " " THEN
    LET l_dbName = fgl_getenv("DBNAME")
  END IF
  IF l_dbName IS NULL OR l_dbName = " " THEN
    LET l_dbName = DEF_DBNAME
  END IF
  LET this.name = l_dbName

  IF this.dir IS NULL OR this.dir = " " THEN
    LET this.dir = DEF_DBDIR
  END IF

  IF this.dbspace IS NULL THEN
    LET this.dbspace = fgl_getenv("DBSPACE")
  END IF
  IF  this.dbspace IS NULL OR this.dbspace = " " THEN
    LET this.dbspace = DEF_DBSPACE
  END IF

  IF this.driver IS NULL THEN
    LET this.driver = fgl_getenv("DBDRIVER")
  END IF
  IF this.driver IS NULL OR this.driver = " " THEN
    LET this.driver = DEF_DBDRIVER
  END IF

-- setup stuff from fglprofile
  LET l_msg = fgl_getResource("dbi.database." || this.name || ".source")
  IF l_msg IS NOT NULL AND l_msg != " " THEN
    LET this.source = l_msg
    LET l_fglprofile = TRUE
  END IF
  LET l_msg = fgl_getResource("dbi.database." || this.name || ".driver")
  IF l_msg IS NULL OR l_msg = " " THEN
    LET l_msg = fgl_getResource("dbi.default.driver")
  END IF
  IF l_msg IS NOT NULL AND l_msg != " " THEN
    LET this.driver = l_msg
    GL_DBGMSG(0, SFMT("Database Driver: %1 from fglprofile:%2", this.driver, fgl_getEnv("FGLPROFILE")))
  ELSE
    GL_DBGMSG(0, "Database Driver:"||this.driver)
  END IF

  LET this.type = this.driver.subString(4, 6)
  LET this.connection = this.name
  LET l_lockMode = TRUE
  IF NOT l_fglprofile THEN -- no fglprofile setting to do it the long way.
    CASE this.type
      WHEN "pgs"
        LET this.desc = "PostgreSQL " || this.driver.subString(7, 9)
        LET this.connection = "db+driver='" || this.driver || "',source='" || this.name || "'"
      WHEN "ifx"
        LET this.source = fgl_getEnv("INFORMIXSERVER")
        LET this.desc = "Informix " || this.driver.subString(7, 9)
        LET this.source = fgl_getEnv("INFORMIXSERVER")
        LET this.connection = this.name
				DISPLAY "INFORMIXDIR:",fgl_getEnv("INFORMIXDIR")
				DISPLAY "INFORMIXSERVER:",fgl_getEnv("INFORMIXSERVER")
				DISPLAY "INFORMIXSQLHOSTS:",fgl_getEnv("INFORMIXSQLHOSTS")
      WHEN "mdb"
        LET l_lockMode = FALSE
      WHEN "sqt"
        IF NOT os.path.EXISTS(this.dir) THEN
          IF NOT os.path.mkdir(this.dir) THEN
            CALL g2_lib.g2_winMessage(
                "Error",
                SFMT("Failed to create dbdir '%1' !\n%2", this.dir, ERR_GET(STATUS)),
                "exclamation")
          END IF
        END IF
        LET this.source = fgl_getEnv("SQLITEDB")
        IF this.source IS NULL OR this.source = " " THEN
          LET this.source = this.dir || "/" || this.name || ".db"
        END IF
        IF NOT os.path.EXISTS(this.source) THEN
          CALL g2_lib.g2_winMessage(
              "Error", SFMT("Database file is missing? '%1' !\n", this.source), "exclamation")
        ELSE
          DISPLAY "Database file exists:", this.source
        END IF
        LET l_lockMode = FALSE
        LET this.desc = "SQLite " || this.driver.subString(7, 9)
        LET this.connection = "db+driver='" || this.driver || "',source='" || this.source || "'"
    END CASE
  END IF

  TRY
    DISPLAY CURRENT, ":Connecting to " || this.connection || " Using:", this.driver, " Source:", this.source, " ..."
    DATABASE this.connection
    DISPLAY CURRENT, ":Connected to " || this.connection || " Using:", this.driver, " Source:", this.source
  CATCH
    LET l_msg =
        "Connection to database failed\nDB:",
        this.name,
        "\nSource:",
        this.source,
        "\nDriver:",
        this.driver,
        "\n",
        "Status:",
        SQLCA.SQLCODE,
        "\n",
        SQLERRMESSAGE
    DISPLAY l_msg
    IF this.create_db AND SQLCA.SQLCODE = -329 AND this.type = "ifx" THEN
      CALL this.g2_ifx_createdb()
      LET l_msg = NULL
    END IF
    IF this.create_db AND SQLCA.SQLCODE = -6372 AND (this.type = "mdb" OR this.type = "mys") THEN
      CALL this.g2_mdb_createdb()
      LET l_msg = NULL
    END IF
    IF this.create_db AND SQLCA.SQLCODE = -6372 AND this.type = "sqt" THEN
      CALL this.g2_sqt_createdb(this.dir, this.source)
      LET l_msg = NULL
    END IF
    IF SQLCA.SQLCODE = -6366 THEN
      RUN "echo $LD_LIBRARY_PATH;ldd $FGLDIR/dbdrivers/" || this.driver || ".so"
    END IF
    IF l_msg IS NOT NULL THEN
      CALL g2_lib.g2_errPopup(SFMT(% "Fatal Error %1", l_msg))
			CALL g2_lib.g2_exitProgram(1, l_msg)
    END IF
  END TRY

  IF l_lockMode THEN
    SET LOCK MODE TO WAIT 3
  END IF

  CALL fgl_setEnv("DBCON", this.name)

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION (this dbInfo) g2_getType() RETURNS STRING
  DEFINE drv STRING
  IF this.type IS NULL THEN
    LET drv = fgl_getenv("DBDRIVER")
    IF drv IS NULL OR drv = " " THEN
      LET drv = DEF_DBDRIVER
    END IF
    LET this.type = drv.subString(4, 6)
  END IF
  RETURN this.type
END FUNCTION
--------------------------------------------------------------------------------
-- create file and folder for the empty sqlite db and then call the db_connect again
FUNCTION (this dbInfo) g2_sqt_createdb(l_dir STRING, l_file STRING) RETURNS ()
  DEFINE c base.Channel
  LET c = base.Channel.create()
  IF NOT os.path.exists(l_dir) THEN
    IF NOT os.path.mkdir(l_dir) THEN
      CALL g2_lib.g2_exitProgram(STATUS, SFMT("DB Folder Creation Failed for: %1", l_dir))
    END IF
  END IF
  CALL c.openFile(l_file, "w")
  CALL c.close()
  LET this.create_db = FALSE -- avoid infintate loop!
  CALL this.g2_connect(this.name)
END FUNCTION
--------------------------------------------------------------------------------
-- create file and folder for the empty sqlite db and then call the db_connect again
FUNCTION (this dbInfo) g2_mdb_createdb() RETURNS ()
  DEFINE l_sql_stmt STRING
  LET l_sql_stmt =
      "CREATE DATABASE " || this.name || " default character set utf8mb4 collate utf8mb4_unicode_ci"
  TRY
    EXECUTE IMMEDIATE l_sql_stmt
  CATCH
    IF NOT g2_sqlStatus(__LINE__, "gl_db", l_sql_stmt) THEN
      CALL g2_lib.g2_exitProgram(STATUS, "DB Creation Failed!")
    END IF
  END TRY
  LET this.create_db = FALSE -- avoid in
END FUNCTION
--------------------------------------------------------------------------------
-- create a new informix database and then call the db_connect again
FUNCTION (this dbInfo) g2_ifx_createdb() RETURNS ()
  DEFINE l_sql_stmt STRING
  LET l_sql_stmt = "CREATE DATABASE " || this.name || " IN " || this.dbspace
  TRY
    EXECUTE IMMEDIATE l_sql_stmt
  CATCH
    IF NOT g2_sqlStatus(__LINE__, "gl_db", l_sql_stmt) THEN
      CALL g2_lib.g2_exitProgram(STATUS, "DB Creation Failed!")
    END IF
  END TRY
  LET this.create_db = FALSE -- avoid infintate loop!
  CALL this.g2_connect(this.name)
END FUNCTION

--------------------------------------------------------------------------------
#+ Show Information for a Failed Connections. Debug.
#+
#+ @param stat Status
#+ @param dbname Database Name
FUNCTION (this dbInfo) g2_showInfo(stat INTEGER) RETURNS ()

  OPEN WINDOW info WITH FORM "g2_dbinfo"

  DISPLAY "FGLDIR" TO lab1
  DISPLAY fgl_getenv("FGLDIR") TO fld1
  DISPLAY "FGLASDIR" TO lab2
  DISPLAY fgl_getenv("FGLASDIR") TO fld2
  DISPLAY "FGLPROFILE" TO lab3
  DISPLAY fgl_getenv("FGLPROFILE") TO fld3
  DISPLAY "DBNAME" TO lab4
  DISPLAY this.name TO fld4
  DISPLAY "dbi.database." || this.name || ".source" TO lab5
  DISPLAY this.source TO fld5

  DISPLAY "dbi.database." || this.name || ".driver" TO lab6
  DISPLAY this.driver TO fld6

  IF this.type IS NULL THEN
    DISPLAY "No driver in FGLPROFILE!!!" TO lab7
  ELSE
    DISPLAY "dbi.database." || this.name || "." || this.type || ".schema" TO lab7
  END IF
  DISPLAY fgl_getResource("dbi.database." || this.name || "." || this.type || ".schema") TO fld7

  DISPLAY "dbsrc" TO lab8
  DISPLAY this.source TO fld8

  DISPLAY "dbconn" TO lab9
  DISPLAY this.connection TO fld9

  DISPLAY "DBPATH" TO lab10
  DISPLAY fgl_getenv("DBPATH") TO fld10

  DISPLAY "LD_LIBRARY_PATH" TO lab11
  DISPLAY fgl_getenv("LD_LIBRARY_PATH") TO fld11

  DISPLAY "STATUS" TO lab13
  DISPLAY stat TO fld13
  DISPLAY "SQLSTATE" TO lab14
  DISPLAY SQLSTATE TO fld14
  DISPLAY "SQLERRMESSAGE" TO lab15
  DISPLAY SQLERRMESSAGE TO fld15

  MENU "Info"
    ON ACTION exit
      EXIT MENU
    ON ACTION close
      EXIT MENU
  END MENU

  CLOSE WINDOW info
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
FUNCTION g2_chkSearch(l_tab STRING, l_defcol STRING, l_search STRING) RETURNS STRING
	DEFINE l_where, l_stmt, l_cond STRING
	DEFINE l_cnt INTEGER
	IF l_search IS NULL OR l_tab IS NULL THEN RETURN "1=1" END IF
	LET l_search = l_search.trim()
	IF l_search.getIndexOf(";",1) > 0 THEN LET l_search = l_search.subString(1,l_cnt) END IF
	LET l_cond = "MATCHES"
	LET l_where = SFMT("lower(%1) %2 '*%3*'",l_defcol, l_cond,l_search.toLowerCase())
	DISPLAY "Search:",l_search
	DISPLAY "       12345678901234567890"
	CALL g2_findCondition( l_search ) RETURNING l_cnt, l_cond
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
		CALL g2_lib.g2_winMessage("SQL Error",SFMT("%1 %2",STATUS, SQLERRMESSAGE),"exclamation")
		LET l_where = NULL
	END TRY
	IF l_cnt = 0 THEN
		ERROR SFMT("No rows found for search '%1'",l_search)
		LET l_where = NULL
	END IF
	RETURN l_where
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION g2_findCondition(l_search STRING) RETURNS (INT,STRING)
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
--------------------------------------------------------------------------------
#+ Process the status after an SQL Statement.
#+
#+ @code CALL g2_db_sqlStatus( __LINE__, "gl_db", l_sql_stmt )
#+
#+ @param l_line Line number - should be __LINE__
#+ @param l_mod Module name - should be __FILE__
#+ @param l_stmt = String: The SQL Statement / Message, Can be NULL.
#+ @return TRUE/FALSE.  Success / Failed
FUNCTION g2_sqlStatus(l_line INT, l_mod STRING, l_stmt STRING) RETURNS BOOLEAN
  DEFINE l_stat INTEGER

  LET l_stat = STATUS
  LET l_mod = l_mod || " Line:", (l_line USING "<<<<<<<")
  IF l_stat = 0 THEN
    RETURN TRUE
  END IF
  IF l_stmt IS NULL THEN
    CALL g2_lib.g2_errPopup(
        % "Status:"
            || l_stat
            || "\nSqlState:"
            || SQLSTATE
            || "\n"
            || SQLERRMESSAGE
            || "\n"
            || l_mod)
  ELSE
    CALL g2_lib.g2_errPopup(
        l_stmt
            || "\nStatus:"
            || l_stat
            || "\nSqlState:"
            || SQLSTATE
            || "\n"
            || SQLERRMESSAGE
            || "\n"
            || l_mod)
    GL_DBGMSG(0, "gl_sqlStatus: Stmt         ='" || l_stmt || "'")
  END IF
  GL_DBGMSG(0, "gl_sqlStatus: WHERE        :" || l_mod)
  GL_DBGMSG(0, "gl_sqlStatus: STATUS       :" || l_stat)
  GL_DBGMSG(0, "gl_sqlStatus: SQLSTATE     :" || SQLSTATE)
  GL_DBGMSG(0, "gl_sqlStatus: SQLERRMESSAGE:" || SQLERRMESSAGE)

  RETURN FALSE

END FUNCTION
--------------------------------------------------------------------------------
#+ Generate an insert statement.
#+
#+ @param tab String: Table name
#+ @param rec_n TypeInfo Node for record to udpate
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION g2_genInsert(tab STRING, rec_n om.domNode, fixQuote BOOLEAN) RETURNS STRING
  DEFINE n om.domNode
  DEFINE nl om.nodeList
  DEFINE l_stmt, val STRING
  DEFINE x, len SMALLINT
  DEFINE typ, comma CHAR(1)

  LET l_stmt = "INSERT INTO " || tab || " VALUES("
  LET nl = rec_n.selectByTagName("Field")
  LET comma = " "
  FOR x = 1 TO nl.getLength()
    LET n = nl.item(x)
    CALL g2_getColumnType(n.getAttribute("type")) RETURNING typ, len
    LET val = n.getAttribute("value")
    IF val IS NULL THEN
      LET l_stmt = l_stmt.append(comma || "NULL")
    ELSE
      IF typ = "N" THEN
        LET l_stmt = l_stmt.append(comma || val)
      ELSE
        IF fixQuote THEN
          LET val = g2_fixQuote(val)
        END IF
        LET l_stmt = l_stmt.append(comma || "'" || val || "'")
      END IF
    END IF
    LET comma = ","
  END FOR
  LET l_stmt = l_stmt.append(")")

  RETURN l_stmt
END FUNCTION
--------------------------------------------------------------------------------
#+ Generate an update statement.
#+
#+ @param tab Table name
#+ @param wher 	Where Clause
#+ @param rec_n TypeInfo Node for NEW record to udpate
#+ @param rec_o TypeInfo Node for ORIGINAL record to udpate
#+ @param ser_col Serial Column number or 0 ( colNo of the column that is a serial )
#+ @param fixQuote Mask single quote with another single quote for GeneroDB!
#+ @return SQL Statement
FUNCTION g2_genUpdate(tab, wher, rec_n, rec_o, ser_col, fixQuote)
  DEFINE tab, wher STRING
  DEFINE ser_col, fixQuote SMALLINT
  DEFINE rec_n, rec_o, n, o om.domNode
  DEFINE l_stmt, val, val_o, d_val, d_val_o STRING
  DEFINE nl_n, nl_o om.nodeList
  DEFINE x, len SMALLINT
  DEFINE typ, comma CHAR(1)

  LET l_stmt = "UPDATE " || tab || " SET "
  LET nl_n = rec_n.selectByTagName("Field")
  LET nl_o = rec_o.selectByTagName("Field")
  LET comma = " "
  FOR x = 1 TO nl_n.getLength()
    IF x = ser_col THEN
      CONTINUE FOR
    END IF -- Skip Serial Column
    LET n = nl_n.item(x)
    LET o = nl_o.item(x)
    CALL g2_getColumnType(n.getAttribute("type")) RETURNING typ, len
    LET val_o = o.getAttribute("value")
    LET val = n.getAttribute("value")
    IF (val_o IS NULL AND val IS NULL) OR val_o = val THEN
      CONTINUE FOR
    END IF
    LET d_val = val
    LET d_val_o = val_o
    IF val IS NULL THEN
      LET d_val = "(null)"
    END IF
    IF val_o IS NULL THEN
      LET d_val_o = "(null)"
    END IF
    GL_DBGMSG(3, n.getAttribute("name") || " N:" || d_val || " O:" || d_val_o)
    LET l_stmt = l_stmt.append(comma || n.getAttribute("name") || " = ")
    IF val IS NULL THEN
      LET l_stmt = l_stmt.append("NULL")
    ELSE
      IF typ = "N" THEN
        LET l_stmt = l_stmt.append(val)
      ELSE
        IF fixQuote THEN
          LET val = g2_fixQuote(val)
        END IF
        LET l_stmt = l_stmt.append("'" || val || "'")
      END IF
    END IF
    LET comma = ","
  END FOR
  LET l_stmt = l_stmt.append(" WHERE " || wher)

  RETURN l_stmt
END FUNCTION
--------------------------------------------------------------------------------
#+ Fix single quote
#+
#+ @param l_in String to be fixed
#+ @returns fixed string
FUNCTION g2_fixQuote(l_in STRING) RETURNS STRING
  DEFINE y SMALLINT
  DEFINE sb base.StringBuffer

  LET y = l_in.getIndexOf("'", 1)
  IF y > 0 THEN
    GL_DBGMSG(0, "Single Quote Found and fixed!")
    LET sb = base.StringBuffer.create()
    CALL sb.append(l_in)
    CALL sb.replace("'", "''", 0)
    LET l_in = sb.toString()
  END IF

  RETURN l_in
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the database column type and return a simple char and len value.
#+ NOTE: SMALLINT INTEGER SERIAL DECIMAL=N, DATE=D, CHAR VARCHAR=C
#+
#+ @param l_typ Type
#+ @return CHAR(1),SMALLINT
FUNCTION g2_getColumnType(l_typ STRING) RETURNS(STRING, STRING)
  DEFINE l_len SMALLINT

--TODO: Use I for smallint, integer, serial, N for numeric, decimal
  LET l_len = 10
  CASE l_typ.subString(1, 3)
    WHEN "SMA"
      LET l_typ = "N"
      LET l_len = 5
    WHEN "INT"
      LET l_typ = "N"
      LET l_len = 10
    WHEN "SER"
      LET l_typ = "N"
      LET l_len = 10
    WHEN "DEC"
      LET l_typ = "N"
      LET l_len = 12
    WHEN "DAT"
      LET l_typ = "D"
      LET l_len = 10
    WHEN "CHA"
      LET l_typ = "C"
      LET l_len = g2_getColumnLength(l_typ)
    WHEN "VAR"
      LET l_typ = "C"
      LET l_len = g2_getColumnLength(l_typ)
  END CASE

  RETURN l_typ, l_len
END FUNCTION
--------------------------------------------------------------------------------
#+ Get the length from a type definiation ie CHAR(10) returns 10
#+
#+ @param s_typ Type
#+ @return Length from type or defaults to 10
FUNCTION g2_getColumnLength(l_typ STRING) RETURNS SMALLINT
  DEFINE x, y, l_len SMALLINT
  LET l_len = 1 -- default
--TODO: Handle decimal, numeric ie values with , in.
  LET x = l_typ.getIndexOf("(", 4)
  LET y = l_typ.getIndexOf(")", x + 1)
  IF x > 0 AND y > 0 THEN
    LET l_len = l_typ.subString(x + 1, y - 1)
  END IF
  RETURN l_len
END FUNCTION
--------------------------------------------------------------------------------
#+ Check a record for valid update/insert
#+
#+ @param l_ex Exists true/false
#+ @param l_key Key value
#+ @param l_sql SQL to select using
#+ @returns true/false
FUNCTION g2_checkRec(l_ex BOOLEAN, l_key STRING, l_sql STRING) RETURNS BOOLEAN
  DEFINE l_exists BOOLEAN

  LET l_key = l_key.trim()
  DISPLAY "Key='", l_key, "'"

  IF l_key IS NULL OR l_key = " " OR l_key.getLength() < 1 THEN
    CALL g2_lib.g2_warnPopup(% "You entered a NULL Key value!")
    RETURN FALSE
  END IF

  PREPARE g2_db_checkrec_pre FROM l_sql
  DECLARE g2_db_checkrec_cur CURSOR FOR g2_db_checkrec_pre
  OPEN g2_db_checkrec_cur
  LET l_exists = TRUE
  FETCH g2_db_checkrec_cur
  IF STATUS = NOTFOUND THEN
    LET l_exists = FALSE
  END IF
  CLOSE g2_db_checkrec_cur
  IF NOT l_exists THEN
    IF l_ex THEN
      CALL g2_lib.g2_warnPopup(% "Record '" || l_key || "' doesn't Exist!")
      RETURN FALSE
    END IF
  ELSE
    IF NOT l_ex THEN
      CALL g2_lib.g2_warnPopup(% "Record '" || l_key || "' already Exists!")
      RETURN FALSE
    END IF
  END IF
  RETURN TRUE
END FUNCTION
