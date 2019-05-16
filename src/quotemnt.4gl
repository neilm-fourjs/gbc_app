
IMPORT FGL g2_lib
IMPORT FGL g2_db

SCHEMA njm_demo310

MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_rec RECORD LIKE quotes.*

	CALL g2_lib.g2_init(ARG_VAL(1), NULL )
  CALL l_db.g2_connect(NULL)

	OPEN FORM quotemnt FROM "quotemnt"
	DISPLAY FORM quotemnt

	LET l_rec.quote_number = ARG_VAL(2)
	IF l_rec.quote_number != 0 THEN
		SELECT * INTO l_rec.* FROM quotes WHERE quote_number = l_rec.quote_number
		IF STATUS = NOTFOUND THEN
			CALL g2_lib.g2_winMessage("Error",SFMT("quotes item '%1' not found!",l_rec.quote_number),"exclamation")
			EXIT PROGRAM
		END IF
	END IF
	CALL showDets( l_rec.* )
	CALL g2_lib.g2_exitProgram(0,"Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION showDets( l_rec RECORD LIKE quotes.* )
	DEFINE l_rec2 RECORD LIKE quotes.*

	CALL ui.Window.getCurrent().setText(SFMT("Quote:%1",l_rec.quote_number))
	LET l_rec2.* = l_rec.*
	LET int_flag = FALSE
	INPUT BY NAME l_rec2.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
		ON ACTION close LET int_flag = TRUE EXIT INPUT
		ON ACTION CLEAR LET l_rec2.* = l_rec.*
		ON ACTION save
	END INPUT

END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_custs(l_cb ui.ComboBox)
	DEFINE l_code LIKE customer.customer_code
	DEFINE l_name LIKE customer.customer_name
	DECLARE l_custcur CURSOR FOR SELECT customer_code, customer_name FROM customer
	FOREACH l_custcur INTO l_code, l_name
		CALL l_cb.addItem(l_code CLIPPED, l_name CLIPPED)
	END FOREACH
END FUNCTION
