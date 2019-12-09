--------------------------------------------------------
--  DDL for Index ANALYZE_LOG_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "EETS3P"."ANALYZE_LOG_PK" ON "EETS3P"."ANALYZE_LOG" ("LFD#", "ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TS_INDEXES" ;
--------------------------------------------------------
--  DDL for Package LOGGING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "EETS3P"."LOGGING" AS 
    
    LOGID NUMBER;
    LFD_LOGNR NUMBER;

    PROCEDURE LOG_INIT;

    PROCEDURE LOG_MSG (
        MESSAGE IN VARCHAR2
    );

END LOGGING;

/
--------------------------------------------------------
--  DDL for Package Body LOGGING
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "EETS3P"."LOGGING" AS

    /*
     * FUNCTION :: GET_LOGID 
     */
    PROCEDURE LOG_INIT
    AS
    
    BEGIN
    
        LOGID := SEQ_PKG_LOGGING_LOGID.NEXTVAL;
        LFD_LOGNR := 1;
     
    END LOG_INIT;


    
    
    /*
     * PROCEDURE :: LOG_MSG
     */
    PROCEDURE LOG_MSG (
        MESSAGE IN VARCHAR2
    ) 
    
    AS
    
    BEGIN 
        
        IF LOGID IS NULL
        THEN
        
            LOG_INIT;
                        
        END IF;
        
        IF MESSAGE IS NULL
        THEN
            INSERT 
                INTO ANALYZE_LOG
            VALUES 
                ( LOGID, LFD_LOGNR, '', SYSDATE )
            ;
        ELSE
            INSERT 
                INTO ANALYZE_LOG 
            VALUES
                ( LOGID, LFD_LOGNR, MESSAGE, SYSDATE )
            ;
        END IF;
        
        COMMIT;

        LFD_LOGNR := LFD_LOGNR +1 ;
        
    END LOG_MSG;
    
END LOGGING;

/
--------------------------------------------------------
--  Constraints for Table ANALYZE_LOG
--------------------------------------------------------

  ALTER TABLE "EETS3P"."ANALYZE_LOG" ADD CONSTRAINT "ANALYZE_LOG_PK" PRIMARY KEY ("LFD#", "ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TS_INDEXES"  ENABLE;
  ALTER TABLE "EETS3P"."ANALYZE_LOG" MODIFY ("LFD#" NOT NULL ENABLE);
  ALTER TABLE "EETS3P"."ANALYZE_LOG" MODIFY ("ID" NOT NULL ENABLE);
