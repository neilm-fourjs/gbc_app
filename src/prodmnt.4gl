
IMPORT FGL g2_lib
IMPORT FGL g2_db

SCHEMA njm_demo310

MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_stk RECORD LIKE stock.*
	DEFINE l_search STRING

	CALL g2_lib.g2_init(ARG_VAL(1), NULL )
  CALL l_db.g2_connect(NULL)

	OPEN FORM prodmnt FROM "prodmnt"
	DISPLAY FORM prodmnt

	LET l_stk.stock_code = ARG_VAL(2)
	IF l_stk.stock_code != "new" THEN
		SELECT * INTO l_stk.* FROM stock WHERE stock_code = l_stk.stock_code
		IF STATUS = NOTFOUND THEN
			CALL g2_lib.g2_winMessage("Error",SFMT("Stock item '%1' not found!",l_stk.stock_code),"exclamation")
			EXIT PROGRAM
		END IF
	END IF
	CALL showDets( l_stk.* )
	CALL g2_lib.g2_exitProgram(0,"Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION showDets( l_stk RECORD LIKE stock.* )
	DEFINE l_stk2 RECORD LIKE stock.*

	CALL ui.Window.getCurrent().setText(SFMT("Prod:%1",l_stk.stock_code))
	LET l_stk2.* = l_stk.*
	LET int_flag = FALSE
	INPUT BY NAME l_stk2.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
		ON ACTION close LET int_flag = TRUE EXIT INPUT
		ON ACTION CLEAR LET l_stk2.* = l_stk.*
		ON ACTION save
	END INPUT

END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_cat(l_cb ui.ComboBox)
	DEFINE l_code LIKE stock_cat.catid
	DEFINE l_name LIKE stock_cat.cat_name
	DECLARE l_catcur CURSOR FOR SELECT catid, cat_name FROM stock_cat
	FOREACH l_catcur INTO l_code, l_name
		CALL l_cb.addItem(l_code CLIPPED, l_name CLIPPED)
	END FOREACH
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_supp(l_cb ui.ComboBox)
	DEFINE l_code LIKE supplier.supp_code
	DEFINE l_name LIKE supplier.supp_name
	DECLARE l_supcur CURSOR FOR SELECT supp_code, supp_name FROM supplier
	FOREACH l_supcur INTO l_code, l_name
		CALL l_cb.addItem(l_code CLIPPED, l_name CLIPPED)
	END FOREACH
END FUNCTION