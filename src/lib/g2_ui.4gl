
IMPORT FGL g2_sql

PUBLIC TYPE t_before_inp_func FUNCTION(l_new BOOLEAN, l_d ui.Dialog) RETURNS ()
PUBLIC TYPE t_after_inp_func FUNCTION(l_new BOOLEAN, l_d ui.Dialog) RETURNS BOOLEAN
PUBLIC TYPE t_after_fld_func FUNCTION(l_fldName STRING, l_fldValue STRING, l_d ui.Dialog) RETURNS ()
PUBLIC TYPE ui RECORD
	dia ui.Dialog,
	before_inp_func t_before_inp_func,
	after_inp_func t_after_inp_func,
	after_fld_func t_after_fld_func
END RECORD
--------------------------------------------------------------------------------
FUNCTION (this ui) g2_UIinput(l_new BOOLEAN, l_sql g2_sql.sql, l_acceptAction STRING, l_exitOnAccept BOOLEAN)
  DEFINE x SMALLINT
	DEFINE l_evt, l_fld STRING
	IF l_acceptAction.getLength() < 1 THEN LET l_acceptAction = "accept" END IF
  CALL ui.Dialog.setDefaultUnbuffered(TRUE)
  LET this.dia = ui.Dialog.createInputByName(l_sql.fields)

  IF l_new THEN
  ELSE
    IF l_sql.current_row = 0 THEN
      RETURN
    END IF
    FOR x = 1 TO l_sql.fields.getLength()
      CALL this.dia.setFieldValue(l_sql.fields[x].colName, l_sql.fields[x].value)
      IF x = l_sql.key_field_num THEN
        CALL this.dia.setFieldActive(l_sql.fields[x].colname, FALSE)
      END IF
    END FOR
  END IF

  CALL this.dia.addTrigger("ON ACTION close")
  CALL this.dia.addTrigger("ON ACTION cancel")
  CALL this.dia.addTrigger("ON ACTION clear")
  CALL this.dia.addTrigger("ON ACTION "||l_acceptAction)
  LET int_flag = FALSE
  WHILE TRUE
		LET l_evt = this.dia.nextEvent()
		IF l_evt.subString(1,11) = "AFTER FIELD" THEN
			LET l_fld = l_evt.subString(13, l_evt.getLength())
			LET l_evt = "AFTER FIELD"
		END IF
    CASE l_evt
      WHEN "BEFORE INPUT"
        IF this.before_inp_func IS NOT NULL THEN
          CALL this.before_inp_func(l_new, this.dia)
        END IF

      WHEN "AFTER INPUT"
        IF this.after_inp_func IS NOT NULL THEN
          IF NOT this.after_inp_func(l_new, this.dia) THEN
            CONTINUE WHILE
          END IF
        END IF
				IF NOT int_flag THEN
					CALL l_sql.g2_SQLrec2Json()
					IF l_new THEN
						IF l_sql.g2_SQLinsert() THEN
							LET l_new = FALSE -- change to update mode now we have the row inserted
						END IF
					ELSE
						IF NOT l_sql.g2_SQLupdate() THEN
							CONTINUE WHILE
						END IF
					END IF
				END IF
        IF l_exitOnAccept THEN EXIT WHILE END IF

      WHEN "AFTER FIELD"
				IF this.after_fld_func IS NOT NULL THEN
					CALL this.after_fld_func(l_fld, this.dia.getFieldValue(l_fld), this.dia)
				END IF

      WHEN "ON ACTION close"
        LET int_flag = TRUE
        EXIT WHILE

      WHEN "ON ACTION clear"
				CALL l_sql.g2_SQLrec2Json()
				FOR x = 1 TO l_sql.fields.getLength()
					CALL this.dia.setFieldValue(l_sql.fields[x].colName, l_sql.fields[x].value)
				END FOR
				CALL l_sql.g2_SQLrec2Json()

      WHEN "ON ACTION "||l_acceptAction
				FOR x = 1 TO l_sql.fields.getLength()
					LET l_sql.fields[x].value = this.dia.getFieldValue(l_sql.fields[x].colName)
				END FOR
        CALL this.dia.accept()

      WHEN "ON ACTION cancel"
        CALL this.dia.cancel()
        EXIT WHILE
    END CASE
  END WHILE

END FUNCTION