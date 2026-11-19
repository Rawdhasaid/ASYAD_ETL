--SQL HISTORY 

MERGE INTO MWS.MWS_FB_PASSENGER_DIM P 
        USING (
            SELECT 
                CAST(PX.ID AS VARCHAR2(50)) AS SOURCE_SYSTEM_KEY,
                PX.NAME AS PASSENGER_NAME,
                PX.GENDER AS GENDER,
                PX.NATIONALITYID AS NATIONALITY_NAME,
                CASE 
                    WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, TO_DATE(PX.DOB, 'YYYY-MM-DD')) / 12) < 12 THEN 'Child'
                    WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, TO_DATE(PX.DOB, 'YYYY-MM-DD')) / 12) < 18 THEN 'Youth'
                    WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, TO_DATE(PX.DOB, 'YYYY-MM-DD')) / 12) < 65 THEN 'Adult'
                    ELSE 'Senior'
                END AS AGE_GROUP,
                PX.IDCARDNO AS ID_CARD_NO,
                NVL(CX.ISGUEST, 0) AS IS_GUEST,
                1 AS IS_PASSENGER,
                CASE 
                    WHEN BL.PASSENGERIDCARD IS NOT NULL THEN 1  
                    ELSE 0 
                END AS IS_BLACKLISTED,
                'MWS_FERRY' AS SRC_DATA_SOURCE
            FROM MWS.MWS_FERRY_PASSENGER_EXT_R PX
            LEFT JOIN MWS.MWS_FB_CUSTOMER_EXT_R CX 
                ON PX.ID = CX.ID
            LEFT JOIN MWS.MWS_FB_PASSENGER_BLACKLIST_EXT_R BL 
                ON PX.IDCARDNO = BL.PASSENGERIDCARD
        ) SRC
        ON (P.SOURCE_SYSTEM_KEY = SRC.SOURCE_SYSTEM_KEY)
        WHEN MATCHED THEN
        UPDATE SET 
            P.PASSENGER_NAME   = SRC.PASSENGER_NAME, 
            P.GENDER           = SRC.GENDER,
            P.NATIONALITY_NAME = SRC.NATIONALITY_NAME,
            P.AGE_GROUP        = SRC.AGE_GROUP,
            P.ID_CARD_NO       = SRC.ID_CARD_NO,
            P.IS_GUEST         = SRC.IS_GUEST,
            P.IS_PASSENGER     = SRC.IS_PASSENGER,
            P.IS_BLACKLISTED   = SRC.IS_BLACKLISTED,
            P.UPDATED_AT       = SYSTIMESTAMP,
            P.DATA_SOURCE      = SRC_DATA_SOURCE
        WHEN NOT MATCHED THEN
        INSERT (
            SOURCE_SYSTEM_KEY, PASSENGER_NAME, GENDER, NATIONALITY_NAME,
            AGE_GROUP, ID_CARD_NO, IS_GUEST, IS_PASSENGER, IS_BLACKLISTED,
            UPDATED_AT, DATA_SOURCE, INSERT_AT
        ) 
        VALUES (
            SRC.SOURCE_SYSTEM_KEY, SRC.PASSENGER_NAME, SRC.GENDER, SRC.NATIONALITY_NAME,
            SRC.AGE_GROUP, SRC.ID_CARD_NO, SRC.IS_GUEST, SRC.IS_PASSENGER, SRC.IS_BLACKLISTED,
            SYSTIMESTAMP, SRC_DATA_SOURCE, SYSTIMESTAMP
        );
        
        
        -------------------------
        SELECT 
B.ID AS BOOKING_ID,
B.BOOKINGTYPE AS BOOKING_TYPE,
B.TYPE AS BOOKING_CHANNEL,
B.STATUS AS BOOKING_STATUS,
--SALE_TYPE ,-- to be figured out 
DT.DATE_KEY AS DATE_KEY ,
CASE WHEN PD.PASSENGER_KEY IS NULL THEN -1 ELSE PD.PASSENGER_KEY END AS PASSENGER_KEY,
CASE WHEN SCD.SERVICE_CLASS_KEY IS NULL THEN -1 ELSE SCD.SERVICE_CLASS_KEY END AS SERVICE_CLASS_KEY ,
CASE WHEN BRD.BRANCH_KEY  IS NULL THEN -1  ELSE BRD.BRANCH_KEY END AS BRANCH_KEY,
CASE WHEN VECLD.VEHICLE_TYPE_KEY  IS NULL THEN -1 ELSE VECLD.VEHICLE_TYPE_KEY END AS VEHICLE_TYPE_KEY,
CASE WHEN VSD.VESSEL_KEY  IS NULL THEN -1 ELSE VSD.VESSEL_KEY END AS  VESSEL_KEY,
CASE WHEN RD.ROUT_KEY  IS NULL THEN -1  ELSE RD.ROUT_KEY END AS ROUT_KEY,
CASE WHEN MD.MEAL_KEY  IS NULL THEN -1  ELSE MD.MEAL_KEY END AS MEAL_KEY,
BV.VEHICLENUMBER AS VEHICLE_NUMBER , --NULLS ON MEAL AND BOOKING 
--VEHICLE_COUNT ,
--IS_EXCLUSIVE ,
SUM(B.ADULT) AS ADULT_COUNT,
SUM(B.CHILD) AS CHILD_COUNT,
SUM(B.INFANT)AS INFANT_COUNT,
PT.PRICETYPE AS FARE_TYPE_NAME ,
B.AMOUNT AS FARE_AMOUNT ,
B.FAREAMOUNTADULT AS FARE_AMOUNT_ADULT ,
B.FAREAMOUNTCHILD AS FARE_AMOUNT_CHILD,
B.FAREAMOUNTINFANT AS FARE_AMOUNT_INFANT,
B.DISCOUNT AS DISCOUNT_AMOUNT ,
B.TOTALAMOUNT AS TOTAL_AMOUNT,
ROUND(B.AMOUNT * 5 / 105, 2) AS VAT_AMOUNT ,
CASE WHEN B.STATUS = 'Cancelled' THEN 1 ELSE 0 END AS IS_CANCELLED ,
CASE WHEN BM.MEALCODE IS NOT NULL THEN 1 ELSE 0 END AS MEAL_QUANTITY,
B.MEALAMOUNT AS MEAL_AMOUNT ,
'MWS_DB' AS DATA_SOURCE ,
SYSDATE AS INSERT_AT ,
SYSDATE AS UPDATED_AT            
FROM MWS_FB_BOOKING_EXT_R B
LEFT JOIN MWS_FB_BOOKINGMEAL_EXT_R BM ON B.ID = BM.ID
LEFT JOIN MWS_FB_BOOKINGCANCEL_EXT_R BC ON BM.BOOKINGID = BC.BOOKINGID 
LEFT JOIN MWS_FB_BOOKINGVEHICLE_EXT_R BV ON BV.ID = B.ID
LEFT JOIN MWS_FB_EXCLUSIVETRIP_EXT_R EXC ON B.ID = EXC.ID
LEFT JOIN MWS_FB_VEHICLE_TYPE_DIM VECLD ON VECLD.VEHICLE_TYPE_ID = BV.VEHICLETYPEID
LEFT JOIN MWS_FERRY_PASSENGER_EXT_R FP ON FP.ID = B.ID
LEFT JOIN MWS_FB_PASSENGER_DIM PD ON FP.ID = PD.SOURCE_SYSTEM_KEY
LEFT JOIN MWS_FB_DATE_DIM DT ON DT.FULL_DATE = TRUNC(B.TRANSDATE)
LEFT JOIN MWS_FB_BRANCH_DIM BRD ON BRD.BRANCH_CODE = B.BRANCHCODE
LEFT JOIN MWS_FB_SERVICE_CLASS_DIM SCD ON SCD.SERVICE_CLASS_ID = B.SERVICECLASSID
LEFT JOIN MWS_FB_MEAL_DIM MD ON MD.MEAL_CODE = BM.MEALCODE
LEFT JOIN MWS_FB_VESSELBOOKINGS_EXT_R VSB on VSB.id = b.id 
LEFT JOIN MWS_FB_VESSEL_DIM VSD ON  VSD.VESSEL_ID = VSB.VESSELID 
LEFT JOIN MWS_FB_ROUT_DIM RD ON VSB.ROUTENO = RD.ROUTE_NO
LEFT JOIN MWS_FB_PRICETYPE_EXT_R PT ON B.PRICETYPEID = PT.ID
--WHERE B.ID =1055791
GROUP BY 
B.ID,
B.BOOKINGTYPE,
B.TYPE ,
B.STATUS,
DT.DATE_KEY,
PD.PASSENGER_KEY,
SCD.SERVICE_CLASS_KEY,
BRD.BRANCH_KEY,
VECLD.VEHICLE_TYPE_KEY,
VSD.VESSEL_KEY,
RD.ROUT_KEY ,
MD.MEAL_KEY ,
BV.VEHICLENUMBER,
IS_CANCELLED,
B.MEALAMOUNT,
B.TOTALAMOUNT ,
B.DISCOUNT,
B.FAREAMOUNTINFANT,
B.FAREAMOUNTCHILD,
B.FAREAMOUNTADULT,
B.AMOUNT,
BM.MEALCODE,
PT.PRICETYPE
ORDER BY DT.DATE_KEY;
---------------------------------
SELECT * FROM 


drop TABLE MWS_FB_SALES_FACT

SELECT
  (SELECT NVL(MAX(SALES_KEY),0) + 1 FROM MWS_FB_SALES_FACT),
  TO_CHAR(b.ID),
  NVL(b.BOOKINGTYPE, 'Unknown'),
  'Booking',
  TO_NUMBER(TO_CHAR(b.TRANSDATE, 'YYYYMMDD')),
  NVL(p.PASSENGER_KEY, -1),
  -1, NVL(br.BRANCH_KEY, -1), -1, -1,
  -1, -1,
  0,
  NVL(b.TYPE, 'Unknown'),
  NVL(b.STATUS, 'Unknown'),
  b.ADULT, b.CHILD, b.INFANT,
  NVL(pt.PRICETYPE, 'Unknown'),
  b.AMOUNT, b.FAREAMOUNTADULT, b.FAREAMOUNTCHILD, b.FAREAMOUNTINFANT,
  b.DISCOUNT, b.TOTALAMOUNT,
  CASE WHEN EXISTS (SELECT 1 FROM MWS_FB_BOOKINGCANCEL_EXT_R c
                    WHERE TO_CHAR(c.BOOKINGID) = TO_CHAR(b.ID)) THEN 1 ELSE 0 END,
  0, 0, 0,
  SYSDATE, 'MWS_FB_BOOKING_EXT_R', SYSDATE
FROM MWS_FB_BOOKING_EXT_R b
LEFT JOIN MWS_FB_PRICETYPE_EXT_R pt ON pt.ID = b.PRICETYPEID
LEFT JOIN MWS_FB_PASSENGER_DIM p    ON p.SOURCE_SYSTEM_KEY = TO_CHAR(b.CUSTOMERID)
LEFT JOIN MWS_FB_BRANCH_DIM br      ON br.BRANCH_CODE = b.BRANCHCODE
WHERE b.TRANSDATE IS NOT NULL AND b.CHILD > 0 AND b.TOTALAMOUNT > 0
FETCH FIRST 1 ROW ONLY;



SELECT
                bM.booking_id,
                SUM(bm.quantity)    AS meal_quantity,
                SUM(bm.TOTALPRICE) AS meal_amount
            FROM MWS_FB_BOOKINGMEAL_EXT_R bm
            WHERE bm.booking_id = p_id
            GROUP BY bm.booking_id
            
            
            
            
            SELECT 
B.ID AS BOOKING_ID,
TRIM(B.BOOKINGTYPE) AS BOOKING_TYPE,
TRIM(B.TYPE) AS BOOKING_CHANNEL,
TRIM(B.STATUS) AS BOOKING_STATUS, 
DT.DATE_KEY AS DATE_KEY ,
CASE WHEN PD.PASSENGER_KEY IS NULL THEN -1 ELSE PD.PASSENGER_KEY END AS PASSENGER_KEY,
CASE WHEN SCD.SERVICE_CLASS_KEY IS NULL THEN -1 ELSE SCD.SERVICE_CLASS_KEY END AS SERVICE_CLASS_KEY ,
CASE WHEN BRD.BRANCH_KEY  IS NULL THEN -1  ELSE BRD.BRANCH_KEY END AS BRANCH_KEY,
CASE WHEN VECLD.VEHICLE_TYPE_KEY  IS NULL THEN -1 ELSE VECLD.VEHICLE_TYPE_KEY END AS VEHICLE_TYPE_KEY,
CASE WHEN VSD.VESSEL_KEY  IS NULL THEN -1 ELSE VSD.VESSEL_KEY END AS  VESSEL_KEY,
CASE WHEN RD.ROUT_KEY  IS NULL THEN -1  ELSE RD.ROUT_KEY END AS ROUT_KEY,
CASE WHEN MD.MEAL_KEY  IS NULL THEN -1  ELSE MD.MEAL_KEY END AS MEAL_KEY,
BV.VEHICLENUMBER AS VEHICLE_NUMBER , 
CASE WHEN BV.BOOKINGID IS NOT NULL THEN 1 ELSE 0 END AS VEHICLE_COUNT,
CASE WHEN EXC.ID IS NOT NULL THEN 1 ELSE 0 END AS IS_EXCLUSIVE,
SUM(B.ADULT) AS ADULT_COUNT,
SUM(B.CHILD) AS CHILD_COUNT,
SUM(B.INFANT)AS INFANT_COUNT,
TRIM(PT.PRICETYPE) AS FARE_TYPE_NAME ,
B.AMOUNT AS FARE_AMOUNT ,
B.FAREAMOUNTADULT AS FARE_AMOUNT_ADULT ,
B.FAREAMOUNTCHILD AS FARE_AMOUNT_CHILD,
B.FAREAMOUNTINFANT AS FARE_AMOUNT_INFANT,
B.DISCOUNT AS DISCOUNT_AMOUNT ,
B.TOTALAMOUNT AS TOTAL_AMOUNT,
ROUND(B.AMOUNT * 5 / 105, 2) AS VAT_AMOUNT ,
CASE WHEN B.STATUS = 'Cancelled' THEN 1 ELSE 0 END AS IS_CANCELLED ,
CASE WHEN BM.MEALCODE IS NOT NULL THEN 1 ELSE 0 END AS MEAL_QUANTITY,
B.MEALAMOUNT AS MEAL_AMOUNT ,
'MWS_DB' AS DATA_SOURCE ,
SYSDATE AS INSERT_AT ,
SYSDATE AS UPDATED_AT            
FROM MWS_FB_BOOKING_EXT_R B
LEFT JOIN MWS_FB_BOOKINGMEAL_EXT_R BM ON B.ID = BM.ID
LEFT JOIN MWS_FB_BOOKINGCANCEL_EXT_R BC ON BM.BOOKINGID = BC.BOOKINGID 
LEFT JOIN MWS_FB_BOOKINGVEHICLE_EXT_R BV ON BV.BOOKINGID = B.ID
LEFT JOIN MWS_FB_EXCLUSIVETRIP_EXT_R EXC ON B.ID = EXC.ID
LEFT JOIN MWS_FB_VEHICLE_TYPE_DIM VECLD ON VECLD.VEHICLE_TYPE_ID = BV.VEHICLETYPEID
--LEFT JOIN MWS_FERRY_PASSENGER_EXT_R FP ON FP.ID = B.ID
LEFT JOIN MWS_FB_PASSENGER_DIM PD ON PD.SOURCE_SYSTEM_KEY= TO_CHAR(B.CUSTOMERID) 
LEFT JOIN MWS_FB_DATE_DIM DT ON DT.FULL_DATE = TRUNC(B.TRANSDATE)
LEFT JOIN MWS_FB_BRANCH_DIM BRD ON BRD.BRANCH_CODE = B.BRANCHCODE
LEFT JOIN MWS_FB_SERVICE_CLASS_DIM SCD ON SCD.SERVICE_CLASS_ID = B.SERVICECLASSID
LEFT JOIN MWS_FB_MEAL_DIM MD ON MD.MEAL_CODE = BM.MEALCODE
LEFT JOIN MWS_FB_VESSELBOOKINGS_EXT_R VSB on VSB.id = b.id 
LEFT JOIN MWS_FB_VESSEL_DIM VSD ON  VSD.VESSEL_ID = VSB.VESSELID 
LEFT JOIN MWS_FB_ROUT_DIM RD ON VSB.ROUTENO = RD.ROUTE_NO
LEFT JOIN MWS_FB_PRICETYPE_EXT_R PT ON B.PRICETYPEID = PT.ID
--WHERE B.ID =1308198
GROUP BY 
B.ID,
EXC.ID,
BV.BOOKINGID,
B.BOOKINGTYPE,
B.TYPE ,
B.STATUS,
DT.DATE_KEY,
PD.PASSENGER_KEY,
SCD.SERVICE_CLASS_KEY,
BRD.BRANCH_KEY,
VECLD.VEHICLE_TYPE_KEY,
VSD.VESSEL_KEY,
RD.ROUT_KEY ,
MD.MEAL_KEY ,
BV.VEHICLENUMBER,
IS_CANCELLED,
B.MEALAMOUNT,
B.TOTALAMOUNT ,
B.DISCOUNT,
B.FAREAMOUNTINFANT,
B.FAREAMOUNTCHILD,
B.FAREAMOUNTADULT,
B.AMOUNT,
BM.MEALCODE,
PT.PRICETYPE
ORDER BY DT.DATE_KEY;





INSERT INTO mws.mws_fb_sales_fact (
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
    vehiclenumber,
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
    insert_at,
    updated_at
)

    SELECT
        b.id                         AS booking_id,
        CASE WHEN TRIM(b.bookingtype) IS NULL THEN 'UNKNOWN' ELSE TRIM(b.bookingtype) END AS booking_type,
        NVL(TRIM(b.type),'UNKNOWN' )  AS booking_channel,
        NVL(TRIM(b.status) ,  'UNKNOWN') AS booking_status,
        dt.date_key                  AS date_key,
        CASE
            WHEN pd.passenger_key IS NULL THEN
                - 1
            ELSE
                pd.passenger_key
        END                          AS passenger_key,
        CASE
            WHEN scd.service_class_key IS NULL THEN
                - 1
            ELSE
                scd.service_class_key
        END                          AS service_class_key,
        CASE
            WHEN brd.branch_key IS NULL THEN
                - 1
            ELSE
                brd.branch_key
        END                          AS branch_key,
        CASE
            WHEN vecld.vehicle_type_key IS NULL THEN
                - 1
            ELSE
                vecld.vehicle_type_key
        END                          AS vehicle_type_key,
        CASE
            WHEN vsd.vessel_key IS NULL THEN
                - 1
            ELSE
                vsd.vessel_key
        END                          AS vessel_key,
        CASE
            WHEN rd.rout_key IS NULL THEN
                - 1
            ELSE
                rd.rout_key
        END                          AS rout_key,
        CASE
            WHEN md.meal_key IS NULL THEN
                - 1
            ELSE
                md.meal_key
        END                          AS meal_key,
        bv.vehiclenumber             AS vehiclenumber,
        CASE
            WHEN bv.bookingid IS NOT NULL THEN
                1
            ELSE
                0
        END                          AS vehicle_count,
        CASE
            WHEN exc.id IS NOT NULL THEN
                1
            ELSE
                0
        END                          AS is_exclusive,
        SUM(b.adult)                 AS adult_count,
        SUM(b.child)                 AS child_count,
        SUM(b.infant)                AS infant_count,
        TRIM(pt.pricetype)           AS fare_type_name,
        b.amount                     AS fare_amount,
        b.fareamountadult            AS fare_amount_adult,
        b.fareamountchild            AS fare_amount_child,
        b.fareamountinfant           AS fare_amount_infant,
        b.discount                   AS discount_amount,
        b.totalamount                AS total_amount,
        round(b.amount * 5 / 105, 2) AS vat_amount,
        CASE
            WHEN b.status = 'Cancelled' THEN
                1
            ELSE
                0
        END                          AS is_cancelled,
        CASE
            WHEN bm.mealcode IS NOT NULL THEN
                1
            ELSE
                0
        END                          AS meal_quantity,
        b.mealamount                 AS meal_amount,
        'MWS_DB'                     AS data_source,
        sysdate                      AS insert_at,
        sysdate                      AS updated_at
    FROM
        mws_fb_booking_ext_r        b
        LEFT JOIN mws_fb_bookingmeal_ext_r    bm ON b.id = bm.id
        LEFT JOIN mws_fb_bookingcancel_ext_r  bc ON bm.bookingid = bc.bookingid
        LEFT JOIN mws_fb_bookingvehicle_ext_r bv ON bv.bookingid = b.id
        LEFT JOIN mws_fb_exclusivetrip_ext_r  exc ON b.id = exc.id
        LEFT JOIN mws_fb_vehicle_type_dim     vecld ON vecld.vehicle_type_id = bv.vehicletypeid
--LEFT JOIN MWS_FERRY_PASSENGER_EXT_R FP ON FP.ID = B.ID
        LEFT JOIN mws_fb_passenger_dim        pd ON pd.source_system_key = to_char(b.customerid)
        LEFT JOIN mws_fb_date_dim             dt ON dt.full_date = trunc(b.transdate)
        LEFT JOIN mws_fb_branch_dim           brd ON brd.branch_code = b.branchcode
        LEFT JOIN mws_fb_service_class_dim    scd ON scd.service_class_id = b.serviceclassid
        LEFT JOIN mws_fb_meal_dim             md ON md.meal_code = bm.mealcode
        LEFT JOIN mws_fb_vesselbookings_ext_r vsb ON vsb.id = b.id
        LEFT JOIN mws_fb_vessel_dim           vsd ON vsd.vessel_id = vsb.vesselid
        LEFT JOIN mws_fb_rout_dim             rd ON vsb.routeno = rd.route_no
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
        dt.date_key;
        
     SELECT passenger_key FROM   TEMP_SALES_FACT
     MINUS SELECT DISTINCT(passenger_key) FROM mws_fb_passenger_dim; 
     
     SELECT *FROM mws_fb_passenger_dim WHERE passenger_key = -1; 
     
     INSERT INTO MWS_FB_PASSENGER_DIM
  (PASSENGER_KEY, SOURCE_SYSTEM_KEY, PASSENGER_NAME, UPDATED_AT, DATA_SOURCE, INSERT_AT)
VALUES (-1, 'UNKNOWN', 'Unknown', SYSDATE, 'MWS-DB', SYSDATE);

SELECT column_name, identity_column, data_default, nullable
FROM all_tab_columns
WHERE owner       = 'MWS'
  AND table_name  = 'MWS_FB_SALES_FACT'
  AND column_name = 'SALES_KEY';
  
  SELECT sequence_name
FROM all_sequences
WHERE sequence_owner = 'MWS'
ORDER BY sequence_name;

SELECT COUNT(*) AS fact_rows,
       MAX(sales_key) AS highest_sales_key
FROM "MWS"."MWS_FB_SALES_FACT";

"MWS"."MWS_FB_SALES_FACT"."SALES_KEY"

CREATE SEQUENCE MWS.MWS_FB_SALES_FACT_SEQ
    START WITH 1
    INCREMENT BY 1;
    
   MWS.MWS_FB_SALES_FACT_SEQ.NEXTVAL
   
     ALTER TABLE MWS.MWS_FB_SALES_FACT
    MODIFY (SALES_KEY DEFAULT MWS_FB_SALES_FACT_SEQ.NEXTVAL);
    
 ALTER TABLE MWS.MWS_FB_SALES_FACT
    MODIFY (VEHICLENUMBER VARCHAR2(100));
    
    SELECT DATE_KEY FROM TEMP_SALES_FACT
    MINUS
    SELECT DATE_KEY FROM mws_fb_date_dim WHERE DATE_KEY = -1
    
    INSERT INTO BRANCH_DIM
  (BRANCH_KEY, BRANCH_CODE, BRANCH_NAME, UPDATED_AT, DATA_SOURCE, INSERT_AT, IS_ACTIVE)
VALUES (-1, 'UNKNOWN', 'Unknown', SYSDATE, 'DB', SYSDATE, 0);

INSERT INTO mws_fb_date_dim (
    DATE_KEY,
    FULL_DATE,
    YEAR,
    QUARTER,
    MONTH_NUMBER,
    MONTH_NAME,
    DAY_OF_WEEK_NUMBER,
    DAY_NAME,
    IS_WEEKEND,
    UPDATED_AT,
    DATA_SOURCE,
    INSERT_AT
)
SELECT
    -1,                 -- DATE_KEY
    DATE '1900-01-01',  -- FULL_DATE placeholder
    0,                  -- YEAR
    0,                  -- QUARTER
    0,                  -- MONTH_NUMBER
    'Unknown',          -- MONTH_NAME
    0,                  -- DAY_OF_WEEK_NUMBER
    'Unknown',          -- DAY_NAME
    0,                  -- IS_WEEKEND placeholder
    SYSTIMESTAMP,       -- UPDATED_AT
    'DWH',              -- DATA_SOURCE
    SYSTIMESTAMP        -- INSERT_AT
FROM dual
WHERE NOT EXISTS (
    SELECT 1
    FROM mws_fb_date_dim
    WHERE DATE_KEY = -1
       OR FULL_DATE = DATE '1900-01-01'
);


INSERT INTO mws.mws_fb_sales_fact (
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
    vehiclenumber,
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
    insert_at,
    updated_at
)

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
        dt.date_key;
        COMMIT;
        
        select * from mws.mws_fb_sales_fact
        
        ALTER SEQUENCE MWS_FB_SALES_FACT_SEQ
RESTART START WITH 1;

TRUNCATE TABLE MWS.mws_fb_sales_fact
RESTART IDENTITY;

        
        TRUNCATE TABLE mws.mws_fb_sales_fact
        
        
        SELECT
    ROUTE_NO,
    COUNT(*) AS row_count
FROM (
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
ORDER BY fn.ROUTE_NO
) a
GROUP BY ROUTE_NO
HAVING COUNT(*) > 1;


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
where fn.ROUTE_NO = 10
ORDER BY fn.ROUTE_NO
