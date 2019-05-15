
&ifndef G2_DEBUG
&define G2_DEBUG
IMPORT FGL g2_debug
&endif

&define GL_DBGMSG( lev, msg ) \
 CALL g2_debug.g2_dbgMsg( __FILE__, __LINE__, lev, NVL(msg,"NULL!"))

GLOBALS
  DEFINE gl_dbgLev SMALLINT
END GLOBALS
