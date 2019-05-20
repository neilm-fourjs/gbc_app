IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL combos

SCHEMA njm_demo310

DEFINE m_arr DYNAMIC ARRAY OF RECORD LIKE stock.*
DEFINE m_scrArr DYNAMIC ARRAY OF RECORD
  stock_code LIKE stock.stock_code,
  stock_cat LIKE stock.stock_cat,
  description LIKE stock.description,
  price LIKE stock.price,
  free_stock LIKE stock.free_stock
END RECORD

MAIN
  DEFINE l_db g2_db.dbInfo
  DEFINE l_rec RECORD LIKE stock.*
  DEFINE l_search STRING
  DEFINE l_where STRING
  DEFINE l_mdi CHAR(1)

  LET l_mdi = ARG_VAL(1)
  IF l_mdi IS NULL THEN
    LET l_mdi = "S"
  END IF
  CALL g2_lib.g2_init(l_mdi, NULL)
  CALL l_db.g2_connect(NULL)
  CALL combos.dummy()

  OPEN FORM list FROM "prodlist"
  DISPLAY FORM list

  CALL getData(NULL)

  DIALOG ATTRIBUTES(UNBUFFERED)
    INPUT l_search FROM search
      ON ACTION search
        IF l_search IS NOT NULL THEN
          LET l_where = g2_db.g2_chkSearch("stock", "description", l_search)
          IF l_where IS NOT NULL THEN
            CALL getData(l_where)
          END IF
        END IF
        NEXT FIELD stock_code
    END INPUT
    DISPLAY ARRAY m_scrArr TO list.*
      ON ACTION SELECT
        RUN "fglrun prodmnt.42r " || l_mdi || " " || m_arr[arr_curr()].stock_code WITHOUT WAITING
    END DISPLAY
    ON ACTION refresh
      CALL getData(NULL)
    ON ACTION advanced
      MESSAGE "Not yet!"
    ON ACTION close
      EXIT DIALOG
    ON ACTION add
      LET l_rec.stock_code = "new"
      RUN "fglrun prodmnt.42r " || l_mdi || " " || l_rec.stock_code WITHOUT WAITING
  END DIALOG
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION getData(l_where STRING)
  DEFINE l_stmt STRING
  CALL m_scrArr.clear()
  CALL m_arr.clear()
  IF l_where IS NULL THEN
    LET l_where = "1=1"
  END IF
  LET l_stmt = "SELECT * FROM stock WHERE " || l_where
  DISPLAY l_stmt
  PREPARE l_pre FROM l_stmt
  DECLARE l_cur CURSOR FOR l_pre
  FOREACH l_cur INTO m_arr[m_arr.getLength() + 1].*
    LET m_scrArr[m_arr.getLength()].stock_code = m_arr[m_arr.getLength()].stock_code
    LET m_scrArr[m_arr.getLength()].stock_cat = m_arr[m_arr.getLength()].stock_cat
    LET m_scrArr[m_arr.getLength()].description = m_arr[m_arr.getLength()].description
    LET m_scrArr[m_arr.getLength()].price = m_arr[m_arr.getLength()].price
    LET m_scrArr[m_arr.getLength()].free_stock = m_arr[m_arr.getLength()].free_stock
  END FOREACH
  CALL m_arr.deleteElement(m_arr.getLength())
END FUNCTION
----------------------------------------------------------------------------------------------------
