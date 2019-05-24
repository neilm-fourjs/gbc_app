
IMPORT FGL g2_lib
IMPORT FGL g2_db
IMPORT FGL g2_about
IMPORT FGL g2_appInfo

CONSTANT C_PRGDESC = "GBC Demo Application"
CONSTANT C_PRGAUTH = "Neil J.Martin"
CONSTANT C_PRGICON = "logo"
CONSTANT C_PRGVER = "3.2"

DEFINE m_appInfo g2_appInfo.appInfo

MAIN
  DEFINE l_db g2_db.dbInfo

  CALL m_appInfo.progInfo(C_PRGDESC, C_PRGAUTH, C_PRGVER, C_PRGICON)
	CALL g2_lib.g2_init("M", NULL)
  CALL l_db.g2_connect(NULL)
  OPEN FORM gbc_app FROM "gbc_app"
  DISPLAY FORM gbc_app

  CALL login()

  CALL ui.Interface.loadStartMenu("gbc_app")

  MENU "Applications:"
    ON ACTION prod RUN "fglrun prods C" WITHOUT WAITING
    ON ACTION quote RUN "fglrun quotes C" WITHOUT WAITING
    ON ACTION cust RUN "fglrun custs C" WITHOUT WAITING
    ON ACTION CLOSE
      EXIT MENU
    ON ACTION QUIT
      EXIT MENU
  END MENU

END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION login()
  DEFINE l_un, l_pw STRING
  OPEN WINDOW login WITH FORM "login"
  INPUT l_un, l_pw FROM username, password
    ON ACTION forgot
      MESSAGE "Oh Dear!"
		ON ACTION about
			CALL g2_about.g2_about(m_appInfo)
  END INPUT
  CLOSE WINDOW login
  IF int_flag THEN
    EXIT PROGRAM
  END IF
END FUNCTION
