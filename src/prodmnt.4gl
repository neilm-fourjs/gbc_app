IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL combos

SCHEMA njm_demo310

MAIN
  DEFINE l_db g2_db.dbInfo
  DEFINE l_rec RECORD LIKE stock.*

  CALL g2_lib.g2_init(ARG_VAL(1), NULL)
  CALL l_db.g2_connect(NULL)
  CALL combos.dummy()

  OPEN FORM prodmnt FROM "prodmnt"
  DISPLAY FORM prodmnt

  LET l_rec.stock_code = ARG_VAL(2)
  IF l_rec.stock_code != "new" THEN
    SELECT * INTO l_rec.* FROM stock WHERE stock_code = l_rec.stock_code
    IF STATUS = NOTFOUND THEN
      CALL g2_lib.g2_winMessage(
          "Error", SFMT("Stock item '%1' not found!", l_rec.stock_code), "exclamation")
      EXIT PROGRAM
    END IF
  END IF
  CALL showDets(l_rec.*)
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION showDets(l_rec RECORD LIKE stock.*)
  DEFINE l_rec2 RECORD LIKE stock.*

  CALL ui.Window.getCurrent().setText(SFMT("Prod:%1", l_rec.stock_code))
  LET l_rec2.* = l_rec.*
  LET int_flag = FALSE
  INPUT BY NAME l_rec2.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
    ON ACTION close
      LET int_flag = TRUE
      EXIT INPUT
    ON ACTION CLEAR
      LET l_rec2.* = l_rec.*
    ON ACTION save
  END INPUT

END FUNCTION
----------------------------------------------------------------------------------------------------
