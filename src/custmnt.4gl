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
	DEFINE l_table STRING = "customer"
	DEFINE l_keyField STRING = "customer_code"
	DEFINE l_new BOOLEAN = FALSE

  CALL g2_lib.g2_init(ARG_VAL(1), NULL)
  CALL l_db.g2_connect(NULL)
  CALL combos.dummy()

  OPEN FORM custmnt FROM "custmnt"
  DISPLAY FORM custmnt

  LET l_key = ARG_VAL(2)
  IF l_key = "new" OR l_key IS NULL THEN LET l_new = TRUE END IF
	IF l_new THEN
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, "1=2")
	ELSE
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,l_key))
		CALL m_Sql.g2_SQLgetRow(1,TRUE)
    IF m_sql.rows_count = 0 THEN
      CALL g2_lib.g2_winMessage("Error", SFMT("Customer '%1' not found!", l_key), "exclamation")
      EXIT PROGRAM
    END IF
  END IF
	LET m_ui.before_inp_func = FUNCTION before_input
	LET m_ui.after_fld_func = FUNCTION after_field
	CALL m_ui.g2_UIinput(l_new, m_sql, "save", FALSE)
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION before_input( l_new BOOLEAN, l_d ui.Dialog ) RETURNS ()
	DEFINE l_key LIKE customer.customer_code
	DEFINE x SMALLINT
	IF l_new THEN
		SELECT MAX( customer_code ) INTO l_key FROM customer
	END IF
	LET x = l_key[2,5]
	LET x = x + 1
	LET l_key[2,5] = x USING "&&&&"
	CALL l_d.setFieldValue("customer_code", l_key)
	CALL l_d.setFieldActive("customer_code", FALSE)
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION after_field( l_fldName STRING, l_fldValue STRING, l_d ui.Dialog ) RETURNS ()
	DISPLAY "After Field:",l_fldName,":",l_fldValue
	CASE l_fldName
		WHEN "email"
			IF l_fldValue.getIndexOf("@",2) < 2 THEN
				ERROR "Email address looks invalid!"
				CALL l_d.nextField( l_fldName )
			END IF
	END CASE
END FUNCTION
