
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL combos

SCHEMA njm_demo310

DEFINE m_arr DYNAMIC ARRAY OF RECORD LIKE quotes.*
DEFINE m_scrArr DYNAMIC ARRAY OF RECORD
		quote_ref						STRING,
		revision						SMALLINT,
		status							CHAR(1),
		account_manager			STRING,
		raised_by						STRING,
		customer_code				STRING,
		division						STRING,
		quote_date					DATE,
		expiration_date 		DATE,
		registered_project	STRING,
		quote_total 				LIKE quotes.quote_total
	END RECORD
DEFINE m_arrCol DYNAMIC ARRAY OF RECORD
		col01 STRING,
		col02 STRING,
		col03 STRING,
		col04 STRING,
		col05 STRING,
		col06 STRING,
		col07 STRING,
		col08 STRING,
		col09 STRING,
		col10 STRING,
		col11 STRING
	END RECORD
MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_rec RECORD LIKE quotes.*
	DEFINE l_search STRING
	DEFINE l_where STRING
	DEFINE l_mdi CHAR(1)

	LET l_mdi = ARG_VAL(1)
	IF l_mdi IS NULL THEN LET l_mdi = "S" END IF
	CALL g2_lib.g2_init(l_mdi, NULL )
  CALL l_db.g2_connect(NULL)

	CALL combos.dummy()

	OPEN FORM list FROM "quotelist"
	DISPLAY FORM list

	CALL getData(NULL)

	DIALOG ATTRIBUTES(UNBUFFERED)
		INPUT l_search FROM search
			ON ACTION search
				IF l_search IS NOT NULL THEN
					LET l_where = g2_db.g2_chkSearch("quotes","quote_ref",l_search)
					IF l_where IS NOT NULL THEN
						CALL getData(l_where)
					END IF
				END IF
				NEXT FIELD quote_number
		END INPUT
		DISPLAY ARRAY m_scrArr TO list.*
			ON ACTION SELECT
				DISPLAY "Run:"||l_mdi||" "||m_arr[ arr_curr() ].quote_number
				RUN "fglrun quotemnt.42r "||l_mdi||" "||m_arr[ arr_curr() ].quote_number WITHOUT WAITING
		END DISPLAY
		BEFORE DIALOG
			CALL DIALOG.setCellAttributes(m_arrCol)
		ON ACTION refresh
			CALL getData(NULL)
		ON ACTION advanced
			MESSAGE "Not yet!"
		ON ACTION close EXIT DIALOG
		ON ACTION add
			LET l_rec.quote_number = 0
			RUN "fglrun quotemnt.42r "||l_mdi||" "||l_rec.quote_number WITHOUT WAITING
	END DIALOG
	CALL g2_lib.g2_exitProgram(0,"Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION getData(l_where STRING)
	DEFINE l_stmt STRING
	DEFINE l_row SMALLINT
	DEFINE l_cust LIKE customer.customer_name
	CALL m_arr.clear()
	IF l_where IS NULL THEN LET l_where = "1=1" END IF
	LET l_stmt = "SELECT * FROM quotes WHERE "||l_where
	DECLARE cstcur CURSOR FOR SELECT customer_name FROM customer WHERE customer_code = ?

	DISPLAY l_stmt
	PREPARE l_pre FROM l_stmt
	DECLARE l_cur CURSOR FOR l_pre 
	FOREACH l_cur INTO m_arr[ m_arr.getLength() + 1 ].*
		LET l_row = m_arr.getLength()
		LET m_scrArr[ l_row ].quote_ref = m_arr[ l_row ].quote_ref
		LET m_scrArr[ l_row ].revision = m_arr[ l_row ].revision
		LET m_scrArr[ l_row ].status = m_arr[ l_row ].status
		LET m_scrArr[ l_row ].account_manager = m_arr[ l_row ].account_manager
		LET m_scrArr[ l_row ].raised_by = m_arr[ l_row ].raised_by

		OPEN cstcur USING m_arr[ l_row ].customer_code
		FETCH cstcur INTO l_cust
		IF STATUS = NOTFOUND THEN LET l_cust = SFMT("Customer '%1' Not Found!", m_arr[ l_row ].customer_code) END IF
		CLOSE cstcur
		LET m_scrArr[ l_row ].customer_code = l_cust

		LET m_scrArr[ l_row ].division = m_arr[ l_row ].division
		LET m_scrArr[ l_row ].quote_date = m_arr[ l_row ].quote_date
		LET m_scrArr[ l_row ].expiration_date = m_arr[ l_row ].expiration_date
		LET m_scrArr[ l_row ].registered_project = m_arr[ l_row ].registered_project
		LET m_scrArr[ l_row ].quote_total = m_arr[ l_row ].quote_total

		CASE m_arr[ l_row ].status
			WHEN "R" LET m_arrCol[ l_row ].col03 = "reverse gray"
			WHEN "W" LET m_arrCol[ l_row ].col03 = "reverse green"
		END CASE
	END FOREACH
	CALL m_arr.deleteElement( l_row )
END FUNCTION
----------------------------------------------------------------------------------------------------