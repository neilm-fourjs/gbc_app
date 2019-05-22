
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL combos

SCHEMA njm_demo310

MAIN
  DEFINE l_db g2_db.dbInfo
  DEFINE l_rec RECORD LIKE quotes.*

  CALL g2_lib.g2_init(ARG_VAL(1), NULL)
  CALL l_db.g2_connect(NULL)

  CALL combos.dummy()

  OPEN FORM quotemnt FROM "quotemnt"
  DISPLAY FORM quotemnt

  LET l_rec.quote_number = ARG_VAL(2)
  IF l_rec.quote_number != 0 THEN
    SELECT * INTO l_rec.* FROM quotes WHERE quote_number = l_rec.quote_number
    IF STATUS = NOTFOUND THEN
      CALL g2_lib.g2_winMessage(
          "Error", SFMT("quotes item '%1' not found!", l_rec.quote_number), "exclamation")
      EXIT PROGRAM
    END IF
  END IF
  CALL showDets(l_rec.*)
  CALL g2_lib.g2_exitProgram(0, "Finished")
END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION showDets(l_rec RECORD LIKE quotes.*)
  DEFINE l_rec2 RECORD LIKE quotes.*
  DEFINE l_dets DYNAMIC ARRAY OF RECORD
    item_num INTEGER,
    product STRING,
    colour INTEGER,
    colour_surcharge LIKE quote_detail.colour_surcharge,
    quantity INTEGER,
    unit_rrp LIKE quote_detail.unit_rrp
  END RECORD
  DEFINE l_qdet RECORD LIKE quote_detail.*
  DEFINE l_row SMALLINT
  DEFINE l_prod LIKE stock.description

  DECLARE stkcur CURSOR FOR SELECT description FROM stock WHERE stock_code = ?

  DECLARE qdetscur CURSOR FOR SELECT * FROM quote_detail WHERE quote_number = l_rec.quote_number
  FOREACH qdetscur INTO l_qdet.*
    CALL l_dets.appendElement()
    LET l_row = l_dets.getLength()
    LET l_dets[l_row].colour = l_qdet.colour_key
    LET l_dets[l_row].colour_surcharge = l_qdet.colour_surcharge
    LET l_dets[l_row].item_num = l_qdet.item_num
    OPEN stkcur USING l_qdet.stock_code
    FETCH stkcur INTO l_prod
    CLOSE stkcur
    LET l_dets[l_row].product = l_prod
    LET l_dets[l_row].quantity = l_qdet.quantity
    LET l_dets[l_row].unit_rrp = l_qdet.unit_rrp
  END FOREACH

  CALL ui.Window.getCurrent().setText(SFMT("Quote:%1", l_rec.quote_number))
  LET l_rec2.* = l_rec.*

  LET int_flag = FALSE
  DIALOG ATTRIBUTES(UNBUFFERED)
    INPUT BY NAME l_rec2.* ATTRIBUTES(WITHOUT DEFAULTS)
      ON ACTION CLEAR
        LET l_rec2.* = l_rec.*
      ON ACTION save
    END INPUT
    DISPLAY ARRAY l_dets TO qdets.*
    END DISPLAY
    ON ACTION close
      LET int_flag = TRUE
      EXIT DIALOG
  END DIALOG

END FUNCTION
----------------------------------------------------------------------------------------------------
