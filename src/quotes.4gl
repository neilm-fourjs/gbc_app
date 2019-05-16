
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL combos

SCHEMA njm_demo310

DEFINE m_arr DYNAMIC ARRAY OF RECORD LIKE quotes.*
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
	col11 STRING,
	col12 STRING,
	col13 STRING,
	col14 STRING,
	col15 STRING,
	col16 STRING,
	col17 STRING
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
		DISPLAY ARRAY m_arr TO list.*
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
	CALL m_arr.clear()
	IF l_where IS NULL THEN LET l_where = "1=1" END IF
	LET l_stmt = "SELECT * FROM quotes WHERE "||l_where
	DISPLAY l_stmt
	PREPARE l_pre FROM l_stmt
	DECLARE l_cur CURSOR FOR l_pre 
	FOREACH l_cur INTO m_arr[ m_arr.getLength() + 1 ].*
		CASE m_arr[ m_arr.getLength() ].status
			WHEN "R" LET m_arrCol[ m_arr.getLength() ].col04 = "reverse gray"
			WHEN "W" LET m_arrCol[ m_arr.getLength() ].col04 = "reverse green"
		END CASE
		DISPLAY m_arrCol[ m_arr.getLength() ].col04
	END FOREACH
	CALL m_arr.deleteElement( m_arr.getLength() )
END FUNCTION
----------------------------------------------------------------------------------------------------