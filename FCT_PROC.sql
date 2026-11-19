CREATE OR REPLACE PROCEDURE LOAD_MWS_FB_SALES_FACT AS
    e_unstable_merge EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_unstable_merge, -30926);
BEGIN MERGE INTO mws_fb_sales_fact tgt
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
        RAISE_APPLICATION_ERROR(
            -20001,
            'CHECK WHETHER THE MERGE SOURCE RETURNS MULTIPLE ROWS FOR A BOOKING_ID.',
            TRUE
        );

    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'A UNIQUE KEY WAS VIOLATED WHILE LOADING THE SALES FACT.',
            TRUE
        );

    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'LOAD_SALES_FACT FAILED.',
            TRUE
        );
END LOAD_MWS_FB_SALES_FACT;
/

BEGIN
    LOAD_MWS_FB_SALES_FACT();
END;
/

SELECT COUNT(*) FROM MWS_FB_SALES_FACT;
SELECT * FROM mws.mws_fb_sales_fact
SHOW ERRORS PROCEDURE load_fact_booking;
TRUNCATE TABLE MWS.mws_fb_sales_fact
     ALTER SEQUENCE MWS_FB_SALES_FACT_SEQ
RESTART START WITH 1;