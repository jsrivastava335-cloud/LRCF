-- Revised template: insert update section between initial and post validation.
-- Due to size, manually duplicate your validation block for post-validation using stored collection.
spool C:\log\SML_ISSUE_JULY2026.txt;
set line 2000;
set serveroutput on;
--Header start
declare
v_filename varchar2(100):='SML_ISSUE_JULY2026.sql';--provide the script name
v_executed_by varchar2(100);
d_executed_at date;
v_database varchar2(100);
begin
dbms_output.put_line('*************************************************************');
dbms_output.put_line('DB script        :           '||v_filename);
select user into v_executed_by from dual;
dbms_output.put_line('Executed by      :           '||v_executed_by);
dbms_output.put_line('Executed at      :           '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS'));
select ora_database_name into v_database from dual;
dbms_output.put_line('Against database :           '||v_database);
dbms_output.put_line('*************************************************************');
end;
/
--Header end
set echo on;

DECLARE

    v_count           NUMBER;
    v_total_orders    NUMBER := 0;
    v_problem_orders  NUMBER := 0;
    v_current_order   cplcodac.pp_order.ord_sap%TYPE;

    CURSOR c_orders IS
        SELECT ord_sap
        FROM cplcodac.pp_order
             JOIN cplcodac.pp_proj
               ON pr_id = ord_pr_id
        WHERE pr_desc = 'S:JIT_JNJ-70033093_BSP' AND ORD_STAT IN ('R','F')
        ORDER BY ord_sap;

BEGIN

DBMS_OUTPUT.PUT_LINE(' ');
DBMS_OUTPUT.PUT_LINE(RPAD('ORDER SAP',20) || 'PROBLEMATIC SU');
DBMS_OUTPUT.PUT_LINE(RPAD('-',20,'-') || ' ' || RPAD('-',30,'-'));
    FOR r IN c_orders LOOP

        v_current_order := r.ord_sap;
        v_total_orders := v_total_orders + 1;
        v_count := 0;

        

        FOR rec IN (

            WITH T1 AS
            (
                SELECT
                    LJOBE_START AS OUTPUT_OPEN_TIME,
                    LJOBE_END AS OUTPUT_CLOSING_TIME,
                    SU_UNIT_NO AS OUTPUT_SU,
                    LJOBE_MAT_ID
                FROM cplcodac.pe_log_jobe
                JOIN cplcodac.pe_job_exec
                    ON JOBE_ID = LJOBE_JOBE_ID
                JOIN cplcodac.pe_job_theo
                    ON JOBT_ID = JOBE_JOBT_ID
                JOIN cplcodac.pe_stor_unit
                    ON SU_ID = LJOBE_SU_ID
                JOIN cplcodac.pp_order
                    ON ORD_ID = JOBT_ORD_ID
                JOIN cplcodac.pp_proj
                    ON PR_ID = ORD_PR_ID
                WHERE LJOBE_MAT_ID = JOBT_MAT_ID_TO_PROD
                  AND LJOBE_LOGTP_ID = 102
                  AND PR_DESC = 'S:JIT_JNJ-70033093_BSP'
                  AND SU_CONT_TYPE = 'V'
                  AND ORD_SAP = v_current_order
            ),

            T2 AS
            (
                SELECT
                    LJOBE_START AS INPUT_OPEN_TIME,
                    LJOBE_END AS INPUT_CLOSING_TIME,
                    SU_UNIT_NO AS INPUT_SU,
                    LJOBE_MAT_ID
                FROM cplcodac.pe_log_jobe
                JOIN cplcodac.pe_job_exec
                    ON JOBE_ID = LJOBE_JOBE_ID
                JOIN cplcodac.pe_job_theo
                    ON JOBT_ID = JOBE_JOBT_ID
                JOIN cplcodac.pe_stor_unit
                    ON SU_ID = LJOBE_SU_ID
                JOIN cplcodac.pp_order
                    ON ORD_ID = JOBT_ORD_ID
                JOIN cplcodac.pp_proj
                    ON PR_ID = ORD_PR_ID
                WHERE LJOBE_MAT_ID <> JOBT_MAT_ID_TO_PROD
                  AND LJOBE_LOGTP_ID = 102
                  AND PR_DESC = 'S:JIT_JNJ-70033093_BSP'
                  AND SU_CONT_TYPE = 'V'
                  AND ORD_SAP = v_current_order
                  AND LJOBE_MAT_ID IN
                  (
                      173167,
                      173168,
                      173960,
                      173961,
                      177906,
                      177907,
                      177908,
                      177742,
                      177743
                  )
            )

            SELECT DISTINCT T1.OUTPUT_SU
            FROM T1, T2

            MINUS

            SELECT DISTINCT T1.OUTPUT_SU
            FROM T1, T2
            WHERE T1.OUTPUT_CLOSING_TIME
                  BETWEEN T2.INPUT_OPEN_TIME
                      AND T2.INPUT_CLOSING_TIME

        )
        LOOP

            v_count := v_count + 1;

          DBMS_OUTPUT.PUT_LINE(
    RPAD(v_current_order,20) || rec.OUTPUT_SU
);

        END LOOP;

        IF v_count > 0 THEN
    v_problem_orders := v_problem_orders + 1;
END IF;


    END LOOP;

    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE('SUMMARY');
    DBMS_OUTPUT.PUT_LINE('=========================================================');
    DBMS_OUTPUT.PUT_LINE('Total Orders Checked      : ' || v_total_orders);
    DBMS_OUTPUT.PUT_LINE('Orders with Problems      : ' || v_problem_orders);
    DBMS_OUTPUT.PUT_LINE('Orders without Problems   : ' || (v_total_orders - v_problem_orders));
    DBMS_OUTPUT.PUT_LINE('=========================================================');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('*************** ERROR ****************');
        DBMS_OUTPUT.PUT_LINE('Order being processed : ' || v_current_order);
        DBMS_OUTPUT.PUT_LINE('Oracle Error          : ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('**************************************');
        RAISE;
END;
/

spool off;