
CREATE OR REPLACE PACKAGE PKG_FERRY_MWS AS

    PROCEDURE PR_LOAD_MWS_FB_BRANCH_DIM;
    PROCEDURE PR_LOAD_MWS_FB_MEAL_DIM;
    PROCEDURE PR_LOAD_MWS_FB_VEHICLE_TYPE_DIM;
    PROCEDURE PR_LOAD_MWS_FB_ROUT_DIM;
    PROCEDURE PR_LOAD_MWS_FB_SALES_FACT;

END PKG_FERRY_MWS;
/
----------------

CREATE OR REPLACE PACKAGE BODY PKG_FERRY_MWS AS

    PROCEDURE PR_LOAD_MWS_FB_BRANCH_DIM IS
    BEGIN
            MERGE INTO MWS.MWS_FB_BRANCH_DIM TGT
    USING (
        SELECT
            TRIM(BRANCHCODE) AS BRANCH_CODE,
            TRIM(NAME)       AS BRANCH_NAME,
            CASE
                WHEN STATUS = 'ACTIVE' THEN
                    1
                ELSE
                    0
            END              AS IS_ACTIVE,
            'MWS-DB'         AS DATA_SOURCE,
            SYSTIMESTAMP     AS INSERT_AT,
            SYSTIMESTAMP     AS UPDATED_AT
        FROM
            MWS.MWS_FB_STATIONS_EXT_R
        ORDER BY
            BRANCH_CODE
    ) SRC ON ( TGT.BRANCH_CODE = SRC.BRANCH_CODE )
    WHEN MATCHED THEN UPDATE
    SET TGT.BRANCH_NAME = SRC.BRANCH_NAME,
        TGT.IS_ACTIVE = SRC.IS_ACTIVE,
        TGT.UPDATED_AT = SYSDATE
    WHERE
        DECODE(TGT.BRANCH_NAME, SRC.BRANCH_NAME, 0, 1) = 1
        OR DECODE(TGT.IS_ACTIVE, SRC.IS_ACTIVE, 0, 1) = 1
    WHEN NOT MATCHED THEN
    INSERT (
        BRANCH_CODE,
        BRANCH_NAME,
        IS_ACTIVE,
        DATA_SOURCE,
        INSERT_AT )
    VALUES
        ( SRC.BRANCH_CODE,
          SRC.BRANCH_NAME,
          SRC.IS_ACTIVE,
          SRC.DATA_SOURCE,
          SYSDATE );

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('BRANCH KEY IS DUPLICATED.');
        RAISE;

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END PR_LOAD_MWS_FB_BRANCH_DIM;
		
    PROCEDURE PR_LOAD_MWS_FB_MEAL_DIM IS
    BEGIN
       MERGE INTO MWS.MWS_FB_MEAL_DIM TGT
    USING (
        SELECT
        TRIM(MM.SHORTCODE)    AS MEAL_CODE,
        TRIM(MM.MENUNAME)     AS MEAL_NAME,
        TRIM(MT.MEALTYPENAME) AS MEAL_TYPE_NAME,
        'MWS-DB'        AS DATA_SOURCE,
        SYSDATE         AS INSERT_AT,
        SYSDATE         AS UPDATED_AT
        FROM
                 MWS.MWS_FB_MEALMASTER_EXT_R MM
            JOIN MWS.MWS_FB_MEALTYPE_EXT_R MT ON MM.TYPE = MT.ID
    ) SRC ON ( TGT.MEAL_CODE = SRC.MEAL_CODE )
    WHEN MATCHED THEN UPDATE
    SET TGT.MEAL_NAME = SRC.MEAL_NAME,
        TGT.MEAL_TYPE_NAME = SRC.MEAL_TYPE_NAME,
        TGT.UPDATED_AT = SYSDATE
    WHERE
        DECODE(TGT.MEAL_NAME, SRC.MEAL_NAME, 0, 1) = 1
        OR DECODE(TGT.MEAL_TYPE_NAME, SRC.MEAL_TYPE_NAME, 0, 1) = 1
    WHEN NOT MATCHED THEN
    INSERT (
        MEAL_CODE,
        MEAL_TYPE_NAME,
        MEAL_NAME,
        DATA_SOURCE,
        INSERT_AT )
    VALUES
        ( SRC.MEAL_CODE,
          SRC.MEAL_TYPE_NAME,
          SRC.MEAL_NAME,
          SRC.DATA_SOURCE,
          SYSDATE );

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('MEAL KEY IS DUPLICATED.');
        RAISE;

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END PR_LOAD_MWS_FB_MEAL_DIM;

-------------
    PROCEDURE PR_LOAD_MWS_FB_VEHICLE_TYPE_DIM IS
    BEGIN
      MERGE INTO MWS.MWS_FB_VEHICLE_TYPE_DIM TGT
    USING (
        SELECT
            ID                    AS VEHICLE_TYPE_ID,
            TRIM(VEHICLETYPENAME) AS VEHICLE_TYPE_NAME,
            'MWS-DB'              AS DATA_SOURCE,
            SYSDATE               AS INSERT_AT,
            SYSDATE               AS UPDATED_AT
        FROM
            MWS_FB_VEHICLETYPE_EXT_R
        WHERE
            VEHICLETYPENAME IN (
                SELECT DISTINCT
                    VEHICLETYPENAME
                FROM
                    MWS_FB_VEHICLETYPE_EXT_R
            )
        ORDER BY
            ID
    ) SRC ON ( TGT.VEHICLE_TYPE_ID = SRC.VEHICLE_TYPE_ID )
    WHEN MATCHED THEN UPDATE
    SET TGT.VEHICLE_TYPE_NAME = SRC.VEHICLE_TYPE_NAME,
        TGT.UPDATED_AT = SYSDATE
    WHERE
        DECODE(TGT.VEHICLE_TYPE_NAME, SRC.VEHICLE_TYPE_NAME, 0, 1) = 1
    WHEN NOT MATCHED THEN
    INSERT (
        VEHICLE_TYPE_ID,
        VEHICLE_TYPE_NAME,
        DATA_SOURCE,
        INSERT_AT )
    VALUES
        ( SRC.VEHICLE_TYPE_ID,
          SRC.VEHICLE_TYPE_NAME,
          SRC.DATA_SOURCE,
          SYSDATE );

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('VEHICLE TYPE KEY IS DUPLICATED.');
        RAISE;

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
END PR_LOAD_MWS_FB_VEHICLE_TYPE_DIM;

-----------
    PROCEDURE PR_LOAD_MWS_FB_ROUT_DIM IS
    BEGIN
       MERGE INTO MWS.MWS_FB_ROUT_DIM TGT
    USING (
     WITH extracted AS (
    SELECT
        FR.*,
		FD.*,
        UPPER(REGEXP_SUBSTR(FD.DUTYNAME, '[0-9]{1,2}:[0-9]{2} [AP]M', 1, 1, 'i')) AS dep_text,
        UPPER(REGEXP_SUBSTR(FD.DUTYNAME, '[0-9]{1,2}:[0-9]{2} [AP]M', 1, 2, 'i')) AS arr_text
    FROM MWS_FB_ROUTEMASTER_EXT_R FR
  LEFT JOIN MWS_FB_DUTYMASTER_EXT_R FD
  ON FR.ROUTENO =FD.ROUTEID
),
parsed AS (
    SELECT
        TRIM(e.DUTYNAME) AS DUTY_NAME,
        e.ROUTENO AS ROUTE_NO,
        TRIM(e.ROUTENAME) AS ROUTE_NAME,
        e.DUTYID AS DUTY_ID,
        TO_NUMBER(SUBSTR(dep_text, 1, INSTR(dep_text, ':') - 1)) AS dep_hour,
        TO_NUMBER(SUBSTR(dep_text, INSTR(dep_text, ':') + 1, 2)) AS dep_minute,
        SUBSTR(dep_text, -2) AS dep_am_pm,
        TO_NUMBER(SUBSTR(arr_text, 1, INSTR(arr_text, ':') - 1)) AS arr_hour,
        TO_NUMBER(SUBSTR(arr_text, INSTR(arr_text, ':') + 1, 2)) AS arr_minute,
        SUBSTR(arr_text, -2) AS arr_am_pm
    FROM extracted e
),
final_q AS (
    SELECT
        p.*,
        CASE
            WHEN dep_hour = 12 AND dep_am_pm = 'AM' THEN 0
            WHEN dep_hour BETWEEN 1 AND 11 AND dep_am_pm = 'PM' THEN dep_hour + 12 ELSE dep_hour
        END AS dep_hour_24,
        CASE
            WHEN arr_hour = 12 AND arr_am_pm = 'AM' THEN 0
            WHEN arr_hour BETWEEN 1 AND 11 AND arr_am_pm = 'PM' THEN arr_hour + 12
            ELSE arr_hour
        END AS arr_hour_24
    FROM parsed p
    )

    SELECT 
    fn.ROUTE_NO,
    fn.ROUTE_NAME,
    fn.DUTY_ID,
    fn.DUTY_NAME,
       CASE WHEN dep_hour_24 IS NOT NULL THEN TO_CHAR(dep_hour_24, 'FM00') || ':' || TO_CHAR(dep_minute, 'FM00')
    END AS departure_HOUR,
    MOD((arr_hour_24 * 60 + arr_minute) - (dep_hour_24 * 60 + dep_minute) + 1440, 1440 ) AS duration_minutes,
    'MWS-DB'AS DATA_SOURCE,
    SYSDATE AS INSERT_AT,
    SYSDATE AS UPDATED_AT 
FROM FinaL_Q fn
ORDER BY fn.ROUTE_NO )SRC
    ON (TGT.ROUTE_NO = SRC.ROUTE_NO 
    AND TGT.DUTY_ID = SRC.DUTY_ID ) 
 
 WHEN MATCHED THEN
 
 UPDATE SET 
 TGT.ROUTE_NAME = SRC.ROUTE_NAME,
 TGT.DUTY_NAME = SRC.DUTY_NAME,
 TGT.DEPARTURE_HOUR = SRC.DEPARTURE_HOUR,
 TGT.DURATION_MINUTES = SRC.DURATION_MINUTES,
 TGT.UPDATED_AT = SYSDATE
 WHERE 
 DECODE(TGT.ROUTE_NAME, SRC.ROUTE_NAME, 0, 1) = 1
 OR DECODE(TGT.DUTY_NAME, SRC.DUTY_NAME, 0, 1) = 1
 OR DECODE(TGT.DEPARTURE_HOUR, SRC.DEPARTURE_HOUR, 0, 1) = 1
 OR DECODE(TGT.DURATION_MINUTES, SRC.DURATION_MINUTES, 0, 1) = 1
 
 WHEN NOT MATCHED THEN 
 INSERT (
ROUTE_NO,
ROUTE_NAME,
DUTY_ID,
DUTY_NAME,
DEPARTURE_HOUR,
DURATION_MINUTES,
DATA_SOURCE,
INSERT_AT,
UPDATED_AT
 )
 VALUES ( 
SRC.ROUTE_NO,
SRC.ROUTE_NAME,
SRC.DUTY_ID,
SRC.DUTY_NAME,
SRC.DEPARTURE_HOUR,
SRC.DURATION_MINUTES,
SRC.DATA_SOURCE,
SYSDATE,
SYSDATE
 );
 COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ROUTE KEY IS DUPLICATED.');
        RAISE;

    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_STACK);
        DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;
 END PR_LOAD_MWS_FB_ROUT_DIM;
---------------

    PROCEDURE PR_LOAD_MWS_FB_SALES_FACT IS
    e_unstable_merge EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_unstable_merge, -30926);
    BEGIN
      MERGE INTO mws_fb_sales_fact tgt
USING (
  SELECT
        b.id   AS booking_id,
        CASE WHEN TRIM(b.bookingtype) IS NULL THEN 'UNKNOWN' ELSE TRIM(b.bookingtype) END AS booking_type,
        NVL(TRIM(b.type),'UNKNOWN' )  AS booking_channel,
        NVL(TRIM(b.status) ,  'UNKNOWN') AS booking_status,
        CASE WHEN dt.date_key IS NULL THEN  -1 ELSE dt.date_key END AS date_key,
        CASE WHEN pd.passenger_key IS NULL THEN  - 1 ELSE pd.passenger_key END AS passenger_key,
        CASE WHEN scd.service_class_key IS NULL THEN  - 1 ELSE scd.service_class_key END AS service_class_key,
        CASE WHEN brd.branch_key IS NULL THEN - 1 ELSE brd.branch_key END AS branch_key,
        CASE WHEN vecld.vehicle_type_key IS NULL THEN - 1 ELSE vecld.vehicle_type_key END AS vehicle_type_key,
        CASE WHEN vsd.vessel_key IS NULL THEN - 1 ELSE vsd.vessel_key END   AS vessel_key,
        CASE WHEN rd.rout_key IS NULL THEN - 1 ELSE rd.rout_key END    AS rout_key,
        CASE WHEN md.meal_key IS NULL THEN- 1 ELSE md.meal_key END    AS meal_key,
        bv.vehiclenumber  AS vehiclenumber,
        CASE WHEN bv.bookingid IS NOT NULL THEN 1 ELSE 0 END  AS vehicle_count,
        CASE WHEN exc.id IS NOT NULL THEN 1 ELSE 0 END    AS is_exclusive,
        SUM(b.adult)      AS adult_count,
        SUM(b.child)      AS child_count,
        SUM(b.infant)     AS infant_count,
        NVL(TRIM(pt.pricetype),'UNKNOWN')AS fare_type_name,
        b.amount          AS fare_amount,
        b.fareamountadult AS fare_amount_adult,
        b.fareamountchild AS fare_amount_child,
        b.fareamountinfant AS fare_amount_infant,
        b.discount        AS discount_amount,
        b.totalamount     AS total_amount,
        round(b.amount * 5 / 105, 2) AS vat_amount,
        CASE WHEN TRIM(b.status) = 'Cancelled' THEN 1 ELSE 0 END    AS is_cancelled,
        CASE WHEN trim(bm.mealcode) IS NOT NULL THEN 1 ELSE 0 END    AS meal_quantity,
        b.mealamount      AS meal_amount,
        'MWS_DB'          AS data_source,
        sysdate AS insert_at,
        sysdate AS updated_at
    FROM
        mws_fb_booking_ext_r        b
        LEFT JOIN mws_fb_bookingmeal_ext_r    bm ON b.id = bm.id
        LEFT JOIN mws_fb_bookingcancel_ext_r  bc ON bm.bookingid = bc.bookingid
        LEFT JOIN mws_fb_bookingvehicle_ext_r bv ON bv.bookingid = b.id
        LEFT JOIN mws_fb_exclusivetrip_ext_r  exc ON b.id = exc.id
        LEFT JOIN mws_fb_vehicle_type_dim     vecld ON vecld.vehicle_type_id = bv.vehicletypeid
--LEFT JOIN MWS_FERRY_PASSENGER_EXT_R FP ON FP.ID = B.ID
        LEFT JOIN mws_fb_passenger_dim        pd ON pd.source_system_key = to_char(b.customerid)
        LEFT JOIN mws_fb_date_dim  dt ON dt.full_date = trunc(b.transdate)
        LEFT JOIN mws_fb_branch_dim brd ON brd.branch_code = b.branchcode
        LEFT JOIN mws_fb_service_class_dim    scd ON scd.service_class_id = b.serviceclassid
        LEFT JOIN mws_fb_meal_dim  md ON md.meal_code = bm.mealcode
        LEFT JOIN mws_fb_vesselbookings_ext_r vsb ON vsb.id = b.id
        LEFT JOIN mws_fb_vessel_dim vsd ON vsd.vessel_id = vsb.vesselid
        LEFT JOIN mws_fb_rout_dim  rd ON vsb.routeno = rd.route_no
        LEFT JOIN mws_fb_pricetype_ext_r      pt ON b.pricetypeid = pt.id
--WHERE B.ID =1308198
    GROUP BY
        b.id,
        exc.id,
        bv.bookingid,
        b.bookingtype,
        b.type,
        b.status,
        dt.date_key,
        pd.passenger_key,
        scd.service_class_key,
        brd.branch_key,
        vecld.vehicle_type_key,
        vsd.vessel_key,
        rd.rout_key,
        md.meal_key,
        bv.vehiclenumber,
        is_cancelled,
        b.mealamount,
        b.totalamount,
        b.discount,
        b.fareamountinfant,
        b.fareamountchild,
        b.fareamountadult,
        b.amount,
        bm.mealcode,
        pt.pricetype
    ORDER BY
        dt.date_key
) src ON ( tgt.booking_id = src.booking_id
           AND tgt.date_key = src.date_key )
WHEN MATCHED THEN UPDATE
SET tgt.booking_type = src.booking_type,
    tgt.booking_channel = src.booking_channel,
    tgt.booking_status = src.booking_status,
    tgt.VEHICLENUMBER = src.VEHICLENUMBER,
    tgt.vehicle_count = src.vehicle_count,
    tgt.is_exclusive = src.is_exclusive,
    tgt.adult_count = src.adult_count,
    tgt.child_count = src.child_count,
    tgt.infant_count = src.infant_count,
    tgt.fare_type_name = src.fare_type_name,
    tgt.fare_amount = src.fare_amount,
    tgt.fare_amount_adult = src.fare_amount_adult,
    tgt.fare_amount_child = src.fare_amount_child,
    tgt.fare_amount_infant = src.fare_amount_infant,
    tgt.discount_amount = src.discount_amount,
    tgt.total_amount = src.total_amount,
    tgt.vat_amount = src.vat_amount,
    tgt.is_cancelled = src.is_cancelled,
    tgt.meal_quantity = src.meal_quantity,
    tgt.meal_amount = src.meal_amount,
    tgt.updated_at = sysdate
WHERE
    decode(tgt.booking_type, src.booking_type, 0, 1) = 1
    OR decode(tgt.booking_channel, src.booking_channel, 0, 1) = 1
    OR decode(tgt.booking_status, src.booking_status, 0, 1) = 1
    OR decode(tgt.VEHICLENUMBER, src.VEHICLENUMBER, 0, 1) = 1
    OR decode(tgt.vehicle_count, src.vehicle_count, 0, 1) = 1
    OR decode(tgt.is_exclusive, src.is_exclusive, 0, 1) = 1
    OR decode(tgt.adult_count, src.adult_count, 0, 1) = 1
    OR decode(tgt.child_count, src.child_count, 0, 1) = 1
    OR decode(tgt.infant_count, src.infant_count, 0, 1) = 1
    OR decode(tgt.fare_type_name, src.fare_type_name, 0, 1) = 1
    OR decode(tgt.fare_amount, src.fare_amount, 0, 1) = 1
    OR decode(tgt.fare_amount_adult, src.fare_amount_adult, 0, 1) = 1
    OR decode(tgt.fare_amount_child, src.fare_amount_child, 0, 1) = 1
    OR decode(tgt.fare_amount_infant, src.fare_amount_infant, 0, 1) = 1
    OR decode(tgt.discount_amount, src.discount_amount, 0, 1) = 1
    OR decode(tgt.total_amount, src.total_amount, 0, 1) = 1
    OR decode(tgt.vat_amount, src.vat_amount, 0, 1) = 1
    OR decode(tgt.is_cancelled, src.is_cancelled, 0, 1) = 1
    OR decode(tgt.meal_quantity, src.meal_quantity, 0, 1) = 1
    OR decode(tgt.meal_amount, src.meal_amount, 0, 1) = 1
WHEN NOT MATCHED THEN
INSERT (
    booking_id,
    booking_type,
    booking_channel,
    booking_status,
    date_key,
    passenger_key,
    service_class_key,
    branch_key,
    vehicle_type_key,
    vessel_key,
    rout_key,
    meal_key,
    VEHICLENUMBER,
    vehicle_count,
    is_exclusive,
    adult_count,
    child_count,
    infant_count,
    fare_type_name,
    fare_amount,
    fare_amount_adult,
    fare_amount_child,
    fare_amount_infant,
    discount_amount,
    total_amount,
    vat_amount,
    is_cancelled,
    meal_quantity,
    meal_amount,
    data_source,
    insert_at ,
    updated_at)
VALUES
    ( src.booking_id,
      src.booking_type,
      src.booking_channel,
      src.booking_status,
      src.date_key,
      src.passenger_key,
      src.service_class_key,
      src.branch_key,
      src.vehicle_type_key,
      src.vessel_key,
      src.rout_key,
      src.meal_key,
      src.VEHICLENUMBER,
      src.vehicle_count,
      src.is_exclusive,
      src.adult_count,
      src.child_count,
      src.infant_count,
      src.fare_type_name,
      src.fare_amount,
      src.fare_amount_adult,
      src.fare_amount_child,
      src.fare_amount_infant,
      src.discount_amount,
      src.total_amount,
      src.vat_amount,
      src.is_cancelled,
      src.meal_quantity,
      src.meal_amount,
      src.data_source,
      sysdate,
      sysdate);
        COMMIT;
EXCEPTION
    WHEN E_UNSTABLE_MERGE THEN
    ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20001,
            'CHECK WHETHER THE MERGE SOURCE RETURNS MULTIPLE ROWS FOR A BOOKING_ID.',
            TRUE
        );

    WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20002,
            'A UNIQUE KEY WAS VIOLATED WHILE LOADING THE SALES FACT.',
            TRUE
        );

    WHEN OTHERS THEN
    ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20003,
            'LOAD_SALES_FACT FAILED.',
            TRUE
        );
END PR_LOAD_MWS_FB_SALES_FACT;

END PKG_FERRY_MWS;
/
#################################################

SET SERVEROUTPUT ON;
BEGIN
    PKG_FERRY_MWS.PR_LOAD_MWS_FB_BRANCH_DIM;
    PKG_FERRY_MWS.PR_LOAD_MWS_FB_MEAL_DIM;
    PKG_FERRY_MWS.PR_LOAD_MWS_FB_VEHICLE_TYPE_DIM;
    PKG_FERRY_MWS.PR_LOAD_MWS_FB_ROUT_DIM;
    PKG_FERRY_MWS.PR_LOAD_MWS_FB_SALES_FACT;
DBMS_OUTPUT.PUT_LINE('Load Completed.');
END;
/