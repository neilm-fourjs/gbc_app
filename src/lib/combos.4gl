
SCHEMA njm_demo310

FUNCTION dummy()
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_cat(l_cb ui.ComboBox)
	DEFINE l_code LIKE stock_cat.catid
	DEFINE l_name LIKE stock_cat.cat_name
	DECLARE l_catcur CURSOR FOR SELECT catid, cat_name FROM stock_cat
	FOREACH l_catcur INTO l_code, l_name
		CALL l_cb.addItem(l_code CLIPPED, l_name CLIPPED)
	END FOREACH
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_supp(l_cb ui.ComboBox)
	DEFINE l_code LIKE supplier.supp_code
	DEFINE l_name LIKE supplier.supp_name
	DECLARE l_supcur CURSOR FOR SELECT supp_code, supp_name FROM supplier
	FOREACH l_supcur INTO l_code, l_name
		CALL l_cb.addItem(l_code CLIPPED, l_name CLIPPED)
	END FOREACH
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_users(l_cb ui.ComboBox)
	DEFINE l_code LIKE sys_users.user_key
	DEFINE l_fname LIKE sys_users.forenames
	DEFINE l_sname LIKE sys_users.surname
	DECLARE l_ucur CURSOR FOR SELECT user_key, forenames, surname  FROM sys_users
	FOREACH l_ucur INTO l_code, l_fname, l_sname
		CALL l_cb.addItem(l_code CLIPPED, SFMT("%1 %2",l_fname CLIPPED, l_sname CLIPPED))
	END FOREACH
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_status(l_cb ui.ComboBox)
	CALL l_cb.addItem("Q","Quote")
	CALL l_cb.addItem("R","Revised")
	CALL l_cb.addItem("W","Won")
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_custs(l_cb ui.ComboBox)
	DEFINE l_code LIKE customer.customer_code
	DEFINE l_name LIKE customer.customer_name
	DECLARE l_custcur CURSOR FOR SELECT customer_code, customer_name FROM customer
	FOREACH l_custcur INTO l_code, l_name
		CALL l_cb.addItem(l_code CLIPPED, l_name CLIPPED)
	END FOREACH
END FUNCTION
----------------------------------------------------------------------------------------------------