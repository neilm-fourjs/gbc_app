
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL combos

SCHEMA njm_demo310

MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_arr DYNAMIC ARRAY OF RECORD LIKE customer.*
	DEFINE l_scrArr  DYNAMIC ARRAY OF RECORD
		customer_code LIKE customer.customer_code,
		customer_name LIKE customer.customer_name
	END RECORD
	DEFINE l_mdi CHAR(1)

	LET l_mdi = ARG_VAL(1)
	IF l_mdi IS NULL THEN LET l_mdi = "S" END IF
	CALL g2_lib.g2_init(l_mdi, NULL )
  CALL l_db.g2_connect(NULL)
	CALL combos.dummy()

	OPEN FORM prodlist FROM "custlist"
	DISPLAY FORM prodlist

	DECLARE l_cur CURSOR FOR SELECT * FROM customer
	FOREACH l_cur INTO l_arr[ l_arr.getLength() + 1 ].*
		LET l_scrArr[ l_arr.getLength() ].customer_code =  l_arr[ l_arr.getLength() ].customer_code
		LET l_scrArr[ l_arr.getLength() ].customer_name =  l_arr[ l_arr.getLength() ].customer_name
	END FOREACH
	CALL l_arr.deleteElement( l_arr.getLength() )
	DISPLAY ARRAY l_scrArr TO custs.*
		ON ACTION SELECT
			CALL showDets( l_arr[ arr_curr() ].* )
	END DISPLAY
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION showDets( l_cst RECORD LIKE customer.* )

	OPEN FORM prodmnt FROM "custmnt"
	DISPLAY FORM prodmnt

	DISPLAY l_cst.customer_code TO code
	DISPLAY l_cst.contact_name TO name

	MENU
		ON ACTION CLOSE EXIT MENU
		ON ACTION QUIT EXIT MENU
	END MENU

END FUNCTION