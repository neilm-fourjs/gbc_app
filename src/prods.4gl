
IMPORT FGL g2_lib
IMPORT FGL g2_db

SCHEMA njm_demo310

	DEFINE m_arr DYNAMIC ARRAY OF RECORD LIKE stock.*
	DEFINE m_scrArr  DYNAMIC ARRAY OF RECORD
		stock_code LIKE stock.stock_code,
		description LIKE stock.description
	END RECORD

MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_stk RECORD LIKE stock.*
	DEFINE l_search STRING

	CALL g2_lib.g2_init(ARG_VAL(1), NULL )
  CALL l_db.g2_connect(NULL)

	OPEN FORM prodlist FROM "prodlist"
	DISPLAY FORM prodlist

	CALL getData()

	DIALOG ATTRIBUTES(UNBUFFERED)
		INPUT l_search FROM search
		END INPUT
		DISPLAY ARRAY m_scrArr TO prods.*
			ON ACTION SELECT
				CALL showDets( m_arr[ arr_curr() ].* )
		END DISPLAY
		ON ACTION refresh
			CALL getData()
		ON ACTION advanced
			MESSAGE "Not yet!"
		ON ACTION CLOSE EXIT DIALOG
		ON ACTION ADD
			LET l_stk.stock_code = "new"
			CALL showDets( l_stk.* )
	END DIALOG
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION getData()
	CALL m_scrArr.clear()
	CALL m_arr.clear()
	DECLARE l_cur CURSOR FOR SELECT * FROM stock
	FOREACH l_cur INTO m_arr[ m_arr.getLength() + 1 ].*
		LET m_scrArr[ m_arr.getLength() ].stock_code =  m_arr[ m_arr.getLength() ].stock_code
		LET m_scrArr[ m_arr.getLength() ].description =  m_arr[ m_arr.getLength() ].description
	END FOREACH
	CALL m_arr.deleteElement( m_arr.getLength() )
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION showDets( l_stk RECORD LIKE stock.* )
	DEFINE l_stk2 RECORD LIKE stock.*

	OPEN FORM prodmnt FROM "prodmnt"
	DISPLAY FORM prodmnt
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
FUNCTION cb_supp(l_cb ui.ComboBox)
	DEFINE l_code LIKE supplier.supp_code
	DEFINE l_name LIKE supplier.supp_name
	DECLARE l_supcur CURSOR FOR SELECT supp_code, supp_name FROM supplier
	FOREACH l_supcur INTO l_code, l_name
		CALL l_cb.addItem(l_code CLIPPED, l_name CLIPPED)
	END FOREACH
END FUNCTION