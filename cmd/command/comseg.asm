; The following are all of the segments used in the load order

CODERES SEGMENT PUBLIC
CODERES ENDS

DATARES SEGMENT PUBLIC
DATARES ENDS

ENVIRONMENT SEGMENT PUBLIC
ENVIRONMENT ENDS

INIT    SEGMENT PUBLIC
INIT    ENDS

TAIL    SEGMENT PUBLIC
TAIL    ENDS

TRANCODE        SEGMENT PUBLIC
TRANCODE        ENDS

TRANDATA        SEGMENT PUBLIC
TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC
TRANSPACE       ENDS

TRANTAIL        SEGMENT PUBLIC
TRANTAIL        ENDS

ZEXEC_CODE      SEGMENT PUBLIC
ZEXEC_CODE      ENDS

ZEXEC_DATA      SEGMENT PUBLIC
ZEXEC_DATA      ENDS

RESGROUP        GROUP   CODERES,DATARES,ENVIRONMENT,INIT,TAIL
TRANGROUP       GROUP   TRANCODE,TRANDATA,TRANSPACE,TRANTAIL
EGROUP          GROUP   ZEXEC_CODE,ZEXEC_DATA