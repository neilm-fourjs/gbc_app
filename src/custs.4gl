
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_grw
IMPORT FGL combos

SCHEMA njm_demo310

DEFINE m_arr DYNAMIC ARRAY OF RECORD LIKE customer.*
TYPE t_scrRec  RECORD
  customer_code LIKE customer.customer_code,
  customer_name LIKE customer.customer_name,
  email LIKE customer.email,
  total_invoices LIKE customer.total_invoices
END RECORD
DEFINE m_scrArr DYNAMIC ARRAY OF t_scrRec

MAIN
  DEFINE l_db g2_db.dbInfo
  DEFINE l_rec RECORD LIKE customer.*
  DEFINE l_search STRING
  DEFINE l_where STRING

  CALL g2_lib.g2_init(ARG_VAL(1), NULL)
  CALL l_db.g2_connect(NULL)
  CALL combos.dummy()

  OPEN FORM list FROM "custlist"
  DISPLAY FORM list

  CALL getData(NULL, "customer_code")

  DIALOG ATTRIBUTES(UNBUFFERED)
    INPUT l_search FROM search
      ON ACTION search
        IF l_search IS NOT NULL THEN
          LET l_where = g2_db.g2_chkSearch("customer", "customer_name", l_search)
          IF l_where IS NOT NULL THEN
            CALL getData(l_where, "customer_code")
          END IF
        END IF
        NEXT FIELD customer_code
    END INPUT
    DISPLAY ARRAY m_scrArr TO list.*
      ON ACTION SELECT
        RUN "fglrun custmnt.42r " || g2_lib.m_mdi || " " || m_arr[arr_curr()].customer_code WITHOUT WAITING
    END DISPLAY
    ON ACTION refresh
      CALL getData(NULL, "customer_code")
    ON ACTION advanced
      MESSAGE "Not yet!"
    ON ACTION close
      EXIT DIALOG
    ON ACTION add
      LET l_rec.customer_code = "new"
      RUN "fglrun custmnt.42r " || g2_lib.m_mdi || " " || l_rec.customer_code WITHOUT WAITING
		ON ACTION rpt
			CALL rpt_func1()
  END DIALOG
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION getData(l_where STRING, l_orderBy STRING )
  DEFINE l_stmt STRING
  CALL m_scrArr.clear()
  CALL m_arr.clear()
  IF l_where IS NULL THEN
    LET l_where = "1=1"
  END IF
  LET l_stmt = "SELECT * FROM customer WHERE " || l_where || " ORDER BY " || l_orderBy
  DISPLAY l_stmt
  PREPARE l_pre FROM l_stmt
  DECLARE l_cur CURSOR FOR l_pre
  FOREACH l_cur INTO m_arr[m_arr.getLength() + 1].*
    LET m_scrArr[m_arr.getLength()].customer_code = m_arr[m_arr.getLength()].customer_code
    LET m_scrArr[m_arr.getLength()].customer_name = m_arr[m_arr.getLength()].customer_name
    LET m_scrArr[m_arr.getLength()].email = m_arr[m_arr.getLength()].email
    LET m_scrArr[m_arr.getLength()].total_invoices = m_arr[m_arr.getLength()].total_invoices
  END FOREACH
  CALL m_arr.deleteElement(m_arr.getLength())
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION rpt_func1()
	DEFINE l_rpt greRpt
	DEFINE x, l_max INTEGER
	LET l_rpt.pageWidth = 132
	IF NOT l_rpt.init( "custlist1", TRUE, "PDF" ) THEN
		CALL g2_lib.g2_winMessage("Error","Report Initialization failed!","exclamation")
		RETURN
	END IF

	LET l_max = m_scrArr.getLength()
	CALL l_rpt.progress(0, l_max, 2)
	START REPORT rpt1 TO XML HANDLER l_rpt.handle
	FOR x = 1 TO l_max
		CALL l_rpt.progress(x, l_max, 2)
		OUTPUT TO REPORT rpt1( m_scrArr[x].* )
	END FOR
	FINISH REPORT rpt1
	CALL l_rpt.finish()
END FUNCTION
----------------------------------------------------------------------------------------------------
REPORT rpt1( l_rec t_scrRec )
	FORMAT
		ON EVERY ROW
			PRINT l_rec.*
END REPORT