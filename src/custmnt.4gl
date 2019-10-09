IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_sql
IMPORT FGL g2_ui
IMPORT FGL combos

&include "schema.inc"

DEFINE m_sql g2_sql.sql
DEFINE m_ui g2_ui.g2_ui
DEFINE m_cst RECORD LIKE customer.*
DEFINE m_del RECORD LIKE addresses.*
DEFINE m_inv RECORD LIKE addresses.*
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
	CALL ui.window.getCurrent().setText(SFMT("Cust:%1",l_key))
	IF l_new THEN
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, "1=2")
	ELSE
		CALL m_sql.g2_SQLinit(l_table,"*",l_keyField, SFMT("%1 = '%2'",l_keyField,l_key))
		CALL m_Sql.g2_SQLgetRow(1,TRUE)
    IF m_sql.rows_count = 0 THEN
      CALL g2_lib.g2_winMessage("Error", SFMT("Customer '%1' not found!", l_key), "exclamation")
      EXIT PROGRAM
    END IF
		CALL m_sql.g2_SQLrec2Json()
		CALL m_sql.json_rec.toFGL( m_cst )
		DISPLAY "Customer:",m_cst.customer_name

		SELECT * INTO m_del.* FROM addresses WHERE addresses.rec_key = m_cst.del_addr
		SELECT * INTO m_inv.* FROM addresses WHERE addresses.rec_key = m_cst.inv_addr
  END IF
	LET m_ui.init_inp_func = FUNCTION init_input
	LET m_ui.before_inp_func = FUNCTION before_input
	LET m_ui.after_fld_func = FUNCTION after_field
	CALL m_ui.g2_UIinput(l_new, m_sql, "save", FALSE)
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION init_input( l_new BOOLEAN, l_d ui.Dialog ) RETURNS ()
	IF NOT l_new THEN
		CALL m_ui.g2_addFormOnlyField("del_add_line1", "VARCHAR(40)", m_del.line1, TRUE)
		CALL m_ui.g2_addFormOnlyField("del_add_line2", "VARCHAR(40)", m_del.line2, TRUE )
		CALL m_ui.g2_addFormOnlyField("del_add_line3", "VARCHAR(40)", m_del.line3, TRUE )
		CALL m_ui.g2_addFormOnlyField("del_add_line4", "VARCHAR(40)", m_del.line4, TRUE )
		CALL m_ui.g2_addFormOnlyField("del_postal_code", "CHAR(8)", m_del.postal_code, TRUE )
		CALL m_ui.g2_addFormOnlyField("del_country_code", "CHAR(3)", m_del.country_code, TRUE ) 
		CALL m_ui.g2_addFormOnlyField("inv_add_line1", "VARCHAR(40)", m_inv.line1, TRUE)
		CALL m_ui.g2_addFormOnlyField("inv_add_line2", "VARCHAR(40)", m_inv.line2, TRUE )
		CALL m_ui.g2_addFormOnlyField("inv_add_line3", "VARCHAR(40)", m_inv.line3, TRUE )
		CALL m_ui.g2_addFormOnlyField("inv_add_line4", "VARCHAR(40)", m_inv.line4, TRUE )
		CALL m_ui.g2_addFormOnlyField("inv_postal_code", "CHAR(8)", m_inv.postal_code, TRUE )
		CALL m_ui.g2_addFormOnlyField("inv_country_code", "CHAR(3)", m_inv.country_code, TRUE ) 
	END IF
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION before_input( l_new BOOLEAN, l_d ui.Dialog ) RETURNS ()
	DEFINE l_key LIKE customer.customer_code
	DEFINE x SMALLINT
	IF l_new THEN
		SELECT MAX( customer_code ) INTO l_key FROM customer -- doean't work in PostgreSQL ?
		LET x = l_key[2,5]
		LET x = x + 1
		LET l_key[2,5] = x USING "&&&&"
		CALL l_d.setFieldValue("customer_code", l_key)
		CALL l_d.setFieldActive("customer_code", FALSE)
	END IF
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
