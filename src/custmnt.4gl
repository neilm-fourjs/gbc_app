IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_sql
IMPORT FGL g2_ui
IMPORT FGL combos

SCHEMA njm_demo310
DEFINE m_sql g2_sql.sql
DEFINE m_ui g2_ui.ui
MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_key STRING
	DEFINE l_table STRING
	DEFINE l_keyField STRING

  CALL g2_lib.g2_init(ARG_VAL(1), NULL)
  CALL l_db.g2_connect(NULL)
  CALL combos.dummy()

	LET l_table = "customer"
	LET l_keyField = "customer_code"
  OPEN FORM custmnt FROM "custmnt"
  DISPLAY FORM custmnt

  LET l_key = ARG_VAL(2)
  IF l_key = "new" THEN
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, "1=2")
		CALL m_ui.g2_UIinput(TRUE, m_sql, "save", TRUE)
	ELSE
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,l_key))
		CALL m_Sql.g2_SQLgetRow(1,TRUE)
    IF m_sql.rows_count = 0 THEN
      CALL g2_lib.g2_winMessage(
          "Error", SFMT("Customer '%1' not found!", l_key), "exclamation")
      EXIT PROGRAM
    END IF
		CALL m_ui.g2_UIinput(FALSE, m_sql, "save", FALSE)
  END IF
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------