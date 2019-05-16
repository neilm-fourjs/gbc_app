
IMPORT FGL g2_lib
IMPORT FGL g2_db

SCHEMA njm_demo310

	DEFINE m_arr DYNAMIC ARRAY OF RECORD LIKE quotes.*
	DEFINE m_scrArr  DYNAMIC ARRAY OF RECORD
		quote_number LIKE quotes.quote_number,
		quote_ref LIKE quotes.quote_ref
	END RECORD

MAIN
  DEFINE l_db g2_db.dbInfo
	DEFINE l_rec RECORD LIKE quotes.*
	DEFINE l_search STRING
	DEFINE l_where STRING

	CALL g2_lib.g2_init(ARG_VAL(1), NULL )
  CALL l_db.g2_connect(NULL)

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
				RUN "fglrun quotemnt.42r C "||m_arr[ arr_curr() ].quote_number WITHOUT WAITING
		END DISPLAY
		ON ACTION refresh
			CALL getData(NULL)
		ON ACTION advanced
			MESSAGE "Not yet!"
		ON ACTION close EXIT DIALOG
		ON ACTION add
			LET l_rec.quote_number = 0
			RUN "fglrun quotemnt.42r C "||l_rec.quote_number WITHOUT WAITING
	END DIALOG
	CALL g2_lib.g2_exitProgram(0,"Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION getData(l_where STRING)
	DEFINE l_stmt STRING
	CALL m_scrArr.clear()
	CALL m_arr.clear()
	IF l_where IS NULL THEN LET l_where = "1=1" END IF
	LET l_stmt = "SELECT * FROM quotes WHERE "||l_where
	DISPLAY l_stmt
	PREPARE l_pre FROM l_stmt
	DECLARE l_cur CURSOR FOR l_pre 
	FOREACH l_cur INTO m_arr[ m_arr.getLength() + 1 ].*
		LET m_scrArr[ m_arr.getLength() ].quote_number =  m_arr[ m_arr.getLength() ].quote_number
		LET m_scrArr[ m_arr.getLength() ].quote_ref =  m_arr[ m_arr.getLength() ].quote_ref
	END FOREACH
	CALL m_arr.deleteElement( m_arr.getLength() )
END FUNCTION
----------------------------------------------------------------------------------------------------