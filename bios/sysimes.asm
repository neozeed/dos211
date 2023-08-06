SYSINITSEG      SEGMENT PUBLIC BYTE 'SYSTEM_INIT'

        PUBLIC  BADOPM,CRLFM,BADSIZ_PRE,BADSIZ_POST,BADCOM,SYSSIZE
        PUBLIC  BADCOUNTRY,BADLD_PRE,BADLD_POST

BADOPM  DB      13,10,"Unrecognized command in CONFIG.SYS"
CRLFM   DB      13,10,'$'

BADSIZ_PRE  DB  13,10,"Sector size too large in file "
BADSIZ_POST DB  "$"

BADLD_PRE DB    13,10,"Bad or missing "
BADLD_POST DB   "$"

BADCOM  DB      "Command Interpreter",0

BADCOUNTRY DB   "Invalid country code",13,10,"$"

SYSSIZE LABEL   BYTE

SYSINITSEG      ENDS
        END
                                                                                                        
