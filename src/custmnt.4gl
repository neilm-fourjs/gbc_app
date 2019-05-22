IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL combos

SCHEMA njm_demo310

MAIN
  DEFINE l_db g2_db.dbInfo
  DEFINE l_rec RECORD LIKE customer.*

  CALL g2_lib.g2_init(ARG_VAL(1), NULL)
  CALL l_db.g2_connect(NULL)
  CALL combos.dummy()

  OPEN FORM custmnt FROM "custmnt"
  DISPLAY FORM custmnt

  LET l_rec.customer_code = ARG_VAL(2)
  IF l_rec.customer_code != "new" THEN
    SELECT * INTO l_rec.* FROM customer WHERE customer_code = l_rec.customer_code
    IF STATUS = NOTFOUND THEN
      CALL g2_lib.g2_winMessage(
          "Error", SFMT("Customer '%1' not found!", l_rec.customer_code), "exclamation")
      EXIT PROGRAM
    END IF
  END IF
  CALL showDets(l_rec.*)
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION showDets(l_rec RECORD LIKE customer.*)
  DEFINE l_rec2 RECORD LIKE customer.*

  CALL ui.Window.getCurrent().setText(SFMT("Prod:%1", l_rec.customer_code))
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