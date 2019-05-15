
IMPORT FGL g2_lib
IMPORT FGL g2_db

SCHEMA njm_demo310

	DEFINE m_arr DYNAMIC ARRAY OF RECORD LIKE stock.*
	DEFINE m_scrArr  DYNAMIC ARRAY OF RECORD
		stock_code LIKE stock.stock_code,
		stock_cat LIKE stock.stock_cat,
		description LIKE stock.description,
		price LIKE stock.price,
		free_stock LIKE stock.free_stock
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
				RUN "fglrun prodmnt.42r C "||m_arr[ arr_curr() ].stock_code WITHOUT WAITING
		END DISPLAY
		ON ACTION refresh
			CALL getData()
		ON ACTION advanced
			MESSAGE "Not yet!"
		ON ACTION CLOSE EXIT DIALOG
		ON ACTION ADD
			LET l_stk.stock_code = "new"
			RUN "fglrun prodmnt.42r C "||l_stk.stock_code WITHOUT WAITING
	END DIALOG
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION getData()
	CALL m_scrArr.clear()
	CALL m_arr.clear()
	DECLARE l_cur CURSOR FOR SELECT * FROM stock
	FOREACH l_cur INTO m_arr[ m_arr.getLength() + 1 ].*
		LET m_scrArr[ m_arr.getLength() ].stock_code =  m_arr[ m_arr.getLength() ].stock_code
		LET m_scrArr[ m_arr.getLength() ].stock_cat =  m_arr[ m_arr.getLength() ].stock_cat
		LET m_scrArr[ m_arr.getLength() ].description =  m_arr[ m_arr.getLength() ].description
		LET m_scrArr[ m_arr.getLength() ].price =  m_arr[ m_arr.getLength() ].price
		LET m_scrArr[ m_arr.getLength() ].free_stock =  m_arr[ m_arr.getLength() ].free_stock
	END FOREACH
	CALL m_arr.deleteElement( m_arr.getLength() )
END FUNCTION
----------------------------------------------------------------------------------------------------