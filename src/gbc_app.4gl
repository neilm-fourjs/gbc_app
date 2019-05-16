
IMPORT FGL g2_lib

MAIN

	CALL g2_lib.g2_init("M", NULL)

	OPEN FORM gbc_app FROM "gbc_app"
	DISPLAY FORM gbc_app

	CALL login()

	CALL ui.Interface.loadStartMenu("gbc_app")

	MENU
		ON ACTION cust  RUN "fglrun custs C" WITHOUT WAITING
		ON ACTION quote RUN "fglrun quotes C" WITHOUT WAITING
		ON ACTION prod  RUN "fglrun prods C" WITHOUT WAITING
		ON ACTION CLOSE EXIT MENU
		ON ACTION QUIT EXIT MENU
	END MENU

END MAIN
----------------------------------------------------------------------------------------------------
FUNCTION login()
	DEFINE l_un, l_pw STRING
	OPEN WINDOW login WITH FORM "login"
	INPUT l_un, l_pw FROM username, password
		ON ACTION forgot
			MESSAGE "Oh Dear!"
	END INPUT
	CLOSE WINDOW login
	IF int_flag THEN EXIT PROGRAM END IF
END FUNCTION
