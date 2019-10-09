IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_sql
IMPORT FGL g2_ui
IMPORT FGL combos

&include "schema.inc"

DEFINE m_sql g2_sql.sql
DEFINE m_ui g2_ui.g2_ui
DEFINE m_stk RECORD LIKE stock.*
DEFINE m_colour STRING
MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_key STRING
	DEFINE l_table STRING = "stock"
	DEFINE l_keyField STRING = "stock_code"
	DEFINE l_new BOOLEAN = FALSE

  CALL g2_lib.g2_init(ARG_VAL(1), NULL)
  CALL l_db.g2_connect(NULL)
  CALL combos.dummy()

  OPEN FORM custmnt FROM "prodmnt"
  DISPLAY FORM custmnt

  LET l_key = ARG_VAL(2)
  IF l_key = "new" OR l_key IS NULL THEN LET l_new = TRUE END IF
	CALL ui.window.getCurrent().setText(SFMT("Prod:%1",l_key))
  IF l_new THEN
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, "1=2")
	ELSE
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,l_key))
		CALL m_Sql.g2_SQLgetRow(1,TRUE)
    IF m_sql.rows_count = 0 THEN
      CALL g2_lib.g2_winMessage("Error", SFMT("Product '%1' not found!", l_key), "exclamation")
      EXIT PROGRAM
    END IF
		CALL m_sql.g2_SQLrec2Json()
		CALL m_sql.json_rec.toFGL( m_stk )
		SELECT colour_hex INTO m_colour FROM colours WHERE colour_key = m_stk.colour_code
		
  END IF
	LET m_ui.init_inp_func = FUNCTION init_input
	LET m_ui.onChange_func = FUNCTION onChange
	CALL m_ui.g2_UIinput(l_new, m_sql, "save", FALSE)
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION init_input( l_new BOOLEAN, l_d ui.Dialog ) RETURNS ()
	IF NOT l_new THEN
		CALL m_ui.g2_addFormOnlyField("colour_hex", "CHAR(10)", m_colour, TRUE)
	END IF
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION onChange( l_fldName STRING, l_fldValue STRING, l_d ui.Dialog ) RETURNS ()
	DEFINE l_key INTEGER
	IF l_fldName = "colour_code" THEN
		LET l_key = l_fldValue
		SELECT colour_hex INTO m_colour FROM colours WHERE colour_key = l_key
		DISPLAY "Hex:",m_colour
		CALL l_d.setFieldValue("colour_hex", m_colour)
	END IF
END FUNCTION