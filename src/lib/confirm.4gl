IMPORT FGL g2_lib
----------------------------------------------------------------------------------------------------
FUNCTION confirm(l_msg STRING) RETURNS BOOLEAN
  IF g2_lib.g2_winQuestion("Confirm", l_msg, "Yes", "Yes|No", "question") = "Yes" THEN
    RETURN TRUE
  ELSE
    RETURN FALSE
  END IF
END FUNCTION