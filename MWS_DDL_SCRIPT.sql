CREATE TABLE MWS.MWS_FB_VEHICLE_TYPE_DIM (
                VEHICLE_TYPE_KEY NUMBER(10) NOT NULL,
                VEHICLE_TYPE_ID NUMBER(10) NOT NULL,
                VEHICLE_TYPE_NAME VARCHAR2(100) NOT NULL,
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_VEHICLE_TYPE_DIM_PK PRIMARY KEY (VEHICLE_TYPE_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_VEHICLE_TYPE_DIM IS 'A vehicle category carried on the ferry (e.g. car, truck). One row per type, not per vehicle.
Source: MWS_FB_VEHICLETYPE_EXT_R.

Join: MWS_FB_VEHICLE_DIM.VEHICLE_TYPE_ID = MWS_FB_BOOKINGVEHICLE_EXT_R.VEHICLETYPEID (loads MWS_FB_SALES_FACT.VEHICLE_TYPE_KEY, Vehicle rows only).';
COMMENT ON COLUMN MWS.MWS_FB_VEHICLE_TYPE_DIM.VEHICLE_TYPE_KEY IS 'Surrogate key. -1 = not applicable (booking and meal rows) or not found.';
COMMENT ON COLUMN MWS.MWS_FB_VEHICLE_TYPE_DIM.VEHICLE_TYPE_ID IS 'Source: MWS_FB_VEHICLETYPE_EXT_R.ID (business key).';
COMMENT ON COLUMN MWS.MWS_FB_VEHICLE_TYPE_DIM.VEHICLE_TYPE_NAME IS 'Source: MWS_FB_VEHICLETYPE_EXT_R.VEHICLETYPENAME. The vehicle category.';
COMMENT ON COLUMN MWS.MWS_FB_VEHICLE_TYPE_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_VEHICLE_TYPE_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_VEHICLE_TYPE_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_ROUT_DIM (
                ROUT_KEY NUMBER(10) NOT NULL,
                ROUTE_NO VARCHAR2(50) NOT NULL,
                ROUTE_NAME VARCHAR2(200),
                DUTY_ID VARCHAR2(50) NOT NULL,
                DUTY_NAME VARCHAR2(200),
                DEPARTURE_HOUR NUMBER(2),
                DURATION_MINUTES NUMBER(5),
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_ROUT_DIM_PK PRIMARY KEY (ROUT_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_ROUT_DIM IS 'A scheduled departure (duty) with the route it belongs to.
Source: MWS_FB_DUTYMASTER_EXT_R + MWS_FB_ROUTEMASTER_EXT_R.
One row per duty. Each duty''s ROUTEID equals the route''s ROUTENO, so the route name is copied onto the duty.
Routes without duties (16 and 20) are not in this dim.
DEPARTURE_HOUR and DURATION_MINUTES are read from the time window in DUTYNAME. Duty names with no window, a zero-length window, or an end before the start that is not a PM-to-AM overnight get NULL for duration.

Join: MWS_FB_ROUT_DIM.ROUTE_NO + DUTY_ID = MWS_FB_VESSELBOOKINGS_EXT_R.ROUTENO + DUTYNO (loads MWS_FB_OPERATIONS_FACT.DUTY_KEY, Trip rows only).';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.ROUT_KEY IS 'Surrogate key';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.ROUTE_NO IS 'Source: MWS_FB_DUTYMASTER_EXT_R.ROUTEID (equals MWS_FB_ROUTEMASTER_EXT_R.ROUTENO). Business key, together with DUTY_ID.';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.ROUTE_NAME IS 'Source: MWS_FB_ROUTEMASTER_EXT_R.ROUTENAME';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.DUTY_ID IS 'Source: MWS_FB_DUTYMASTER_EXT_R.DUTYID. Business key, together with ROUTE_NO.';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.DUTY_NAME IS 'Source: MWS_FB_DUTYMASTER_EXT_R.DUTYNAME';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.DEPARTURE_HOUR IS 'Hour the duty departs, read from the time window in DUTYNAME. NULL if the name has no window.';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.DURATION_MINUTES IS 'Length of the trip in minutes, read from the time window in DUTYNAME. NULL if no window, a zero-length window, or an end before the start that is not a PM-to-AM overnight.';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_ROUT_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_VESSEL_DIM (
                VESSEL_KEY NUMBER(10) NOT NULL,
                VESSEL_ID NUMBER(10) NOT NULL,
                VESSEL_NAME VARCHAR2(200),
                VESSEL_CODE VARCHAR2(50),
                IS_ACTIVE CHAR(2) NOT NULL,
                VESSEL_TYPE VARCHAR2(50),
                PASSENGER_CAPACITY NUMBER(10),
                VEHICLE_CAPACITY NUMBER(6),
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_VESSEL_DIM_PK PRIMARY KEY (VESSEL_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_VESSEL_DIM IS 'A ferry vessel with its type and passenger and vehicle capacity.
Source: MWS_FB_VESSEL_EXT_R + MWS_FB_FLEETDETAILS_EXT_R.
The two sources share no common ID, so they are linked by vessel name:
UPPER(TRIM(MWS_FB_VESSEL_EXT_R.VESSEL)) = UPPER(TRIM(MWS_FB_FLEETDETAILS_EXT_R.<English name column>)).
One row per MWS_FB_VESSEL_EXT_R.ID. The same physical vessel can have several IDs (HSC Sawqrah has 2, 5, 12, 13), and each gets the same fleet details. Vessels with no fleet row (HSC Shinas) have NULL details.

Join: MWS_FB_VESSEL_DIM.VESSEL_ID = MWS_FB_VESSELBOOKINGS_EXT_R.VESSELID (loads MWS_FB_OPERATIONS_FACT.VESSEL_KEY, Trip rows only).';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.VESSEL_KEY IS 'Surrogate key';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.VESSEL_ID IS 'Source: MWS_FB_VESSEL_EXT_R.ID (business key)';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.VESSEL_NAME IS 'Source: MWS_FB_VESSEL_EXT_R.VESSEL';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.VESSEL_CODE IS 'Source: MWS_FB_VESSEL_EXT_R.CODE';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.IS_ACTIVE IS 'Source: MWS_FB_VESSEL_EXT_R.STATUS';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.VESSEL_TYPE IS 'Source: MWS_FB_FLEETDETAILS_EXT_R. Passenger / Ro-Ro, High Speed Craft or Landing Craft. NULL if the vessel has no fleet row.';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.PASSENGER_CAPACITY IS 'Maximum passengers the vessel can carry. Source: MWS_FB_FLEETDETAILS_EXT_R.PASSENGERS. NULL if no fleet row.';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.VEHICLE_CAPACITY IS 'Maximum vehicles the vessel can carry. Source: MWS_FB_FLEETDETAILS_EXT_R.VEHICLES. NULL if no fleet row.';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_VESSEL_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_PASSENGER_DIM (
                PASSENGER_KEY NUMBER(10) NOT NULL,
                SOURCE_SYSTEM_KEY VARCHAR2(30) NOT NULL,
                PASSENGER_NAME VARCHAR2(200),
                GENDER VARCHAR2(20),
                NATIONALITY_NAME VARCHAR2(100),
                AGE_GROUP VARCHAR2(50),
                ID_CARD_NO VARCHAR2(50),
                IS_GUEST NUMBER(1),
                IS_PASSENGER NUMBER(1),
                IS_BLACKLISTED NUMBER(1),
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_PASSENGER_DIM_PK PRIMARY KEY (PASSENGER_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_PASSENGER_DIM IS 'A person who buys or travels, built by merging MWS_FB_CUSTOMER_EXT_R and MWS_FERRY_PASSENGER_EXT_R.
The two sources share no ID, so rows are linked by matching, in this order:
Civil ID, then email, then mobile number. Name alone is never used to link, only to confirm,
because many different people share the same name.
A person with no match stays as their own row.
Blacklisted people are flagged with IS_BLACKLISTED, not stored as separate rows.

Join: loads PASSENGER_KEY on MWS_FB_SALES_FACT (the buyer) and MWS_FB_OPERATIONS_FACT (the passenger who boarded).';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.PASSENGER_KEY IS 'Surrogate key';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.SOURCE_SYSTEM_KEY IS 'SOURCE SYSTEM PK';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.PASSENGER_NAME IS 'PII. Only for named reports';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.GENDER IS 'Source: GENDER';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.NATIONALITY_NAME IS 'Source: MWS_FB_NATIONALITY_EXT_R.NATIONALITY, joined on MWS_FERRY_PASSENGER_EXT_R.NATIONALITYID = NATIONALITY.ID';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.AGE_GROUP IS 'Derived from DATE_OF_BIRTH';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.ID_CARD_NO IS 'Source: IDCARDNO.

Kept only because the blacklist matches on it. Restrict access';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.IS_GUEST IS 'Source: MWS_FB_CUSTOMER_EXT_R.ISGUEST. 1 if the person booked only as a guest, without a registered account. 0 if registered, or if there is no customer record (passenger only). When several customer records merge into one person, 1 only if all of them are guest. A guest may not be traceable across bookings, so repeat customers can be undercounted.';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.IS_PASSENGER IS '1 if the person has a record in MWS_FERRY_PASSENGER_EXT_R, otherwise 0.';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.IS_BLACKLISTED IS '1 if ID_CARD_NO appears in MWS_FB_PASSENGER_BLACKLIST_EXT_R.PASSENGERIDCARD, otherwise 0. Current state only';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_PASSENGER_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_MEAL_DIM (
                MEAL_KEY NUMBER NOT NULL,
                MEAL_CODE VARCHAR2 NOT NULL,
                MEAL_NAME VARCHAR2,
                MEAL_TYPE_NAME VARCHAR2,
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_MEAL_DIM_PK PRIMARY KEY (MEAL_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_MEAL_DIM IS 'A menu item sold on board, with its diet type.
Source: MWS_FB_MEALMASTER_EXT_R + MWS_FB_MEALTYPE_EXT_R.

Join: MWS_FB_MEAL_DIM.MEAL_CODE = MWS_FB_BOOKINGMEAL_EXT_R.MEALCODE (loads MWS_FB_SALES_FACT.MEAL_KEY, Meal rows only).';
COMMENT ON COLUMN MWS.MWS_FB_MEAL_DIM.MEAL_KEY IS 'Surrogate key';
COMMENT ON COLUMN MWS.MWS_FB_MEAL_DIM.MEAL_CODE IS 'Source: MWS_FB_MEALMASTER_EXT_R.SHORTCODE (business key). Matches the meal code on a booked meal';
COMMENT ON COLUMN MWS.MWS_FB_MEAL_DIM.MEAL_NAME IS 'Source: MWS_FB_MEALMASTER_EXT_R.MENUNAME. The menu item';
COMMENT ON COLUMN MWS.MWS_FB_MEAL_DIM.MEAL_TYPE_NAME IS 'Source: MWS_FB_MEALTYPE_EXT_R.MEALTYPENAME. Diet type, e.g. Vegetarian or Non-Vegetarian';
COMMENT ON COLUMN MWS.MWS_FB_MEAL_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_MEAL_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_MEAL_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_BRANCH_DIM (
                BRANCH_KEY NUMBER NOT NULL,
                BRANCH_CODE VARCHAR2 NOT NULL,
                BRANCH_NAME VARCHAR2,
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_BRANCH_DIM_PK PRIMARY KEY (BRANCH_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_BRANCH_DIM IS 'Station or branch where a booking was sold.
Source: MWS_FB_STATIONS_EXT_R.

Join: MWS_FB_BRANCH_DIM.BRANCH_CODE = MWS_FB_BOOKING_EXT_R.BRANCHCODE (loads MWS_FB_SALES_FACT.BRANCH_KEY).';
COMMENT ON COLUMN MWS.MWS_FB_BRANCH_DIM.BRANCH_KEY IS 'Surrogate key';
COMMENT ON COLUMN MWS.MWS_FB_BRANCH_DIM.BRANCH_CODE IS 'Source: MWS_FB_STATIONS_EXT_R.BRANCHCODE (business key, text). This is what the booking joins on';
COMMENT ON COLUMN MWS.MWS_FB_BRANCH_DIM.BRANCH_NAME IS 'Source: MWS_FB_STATIONS_EXT_R.NAME';
COMMENT ON COLUMN MWS.MWS_FB_BRANCH_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_BRANCH_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_BRANCH_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_SERVICE_CLASS_DIM (
                SERVICE_CLASS_KEY NUMBER(10) NOT NULL,
                SERVICE_CLASS_ID NUMBER(10) NOT NULL,
                SERVICE_CLASS_NAME VARCHAR2,
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_SERVICE_CLASS_DIM_PK PRIMARY KEY (SERVICE_CLASS_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_SERVICE_CLASS_DIM IS 'Join: MWS_FB_SERVICE_CLASS_DIM.SERVICE_CLASS_ID = MWS_FB_SERVICECLASS_EXT_R.ID (loads SERVICE_CLASS_KEY on MWS_FB_SALES_FACT and, via the booking, on the Boarding rows of MWS_FB_OPERATIONS_FACT).';
COMMENT ON COLUMN MWS.MWS_FB_SERVICE_CLASS_DIM.SERVICE_CLASS_KEY IS 'Surrogate key';
COMMENT ON COLUMN MWS.MWS_FB_SERVICE_CLASS_DIM.SERVICE_CLASS_ID IS 'Source: MWS_FB_SERVICECLASS_EXT_R.ID (business key)';
COMMENT ON COLUMN MWS.MWS_FB_SERVICE_CLASS_DIM.SERVICE_CLASS_NAME IS 'The class name like Business Class or Economic';
COMMENT ON COLUMN MWS.MWS_FB_SERVICE_CLASS_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_SERVICE_CLASS_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_SERVICE_CLASS_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_DATE_DIM (
                DATE_KEY NUMBER(8) NOT NULL,
                FULL_DATE DATE NOT NULL,
                YEAR NUMBER(4) NOT NULL,
                QUARTER NUMBER(1) NOT NULL,
                MONTH_NUMBER NUMBER(2) NOT NULL,
                MONTH_NAME VARCHAR2(20) NOT NULL,
                DAY_OF_WEEK_NUMBER NUMBER(1) NOT NULL,
                DAY_NAME VARCHAR2(20) NOT NULL,
                IS_WEEKEND NUMBER(1) NOT NULL,
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_DATE_DIM_PK PRIMARY KEY (DATE_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_DATE_DIM IS 'Calendar date, one row per day.
Generated by the ETL, there is no source table.

Join: MWS_FB_DATE_DIM.DATE_KEY = DATE_KEY on MWS_FB_SALES_FACT and MWS_FB_OPERATIONS_FACT.';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.DATE_KEY IS 'Surrogate key format YYYYMMDD';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.FULL_DATE IS 'calendar date';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.YEAR IS 'Number of year like 1999';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.QUARTER IS 'Generated, 1 to 4';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.MONTH_NUMBER IS 'Number of the month 1,2,3...';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.MONTH_NAME IS 'Month name e.g. July';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.DAY_OF_WEEK_NUMBER IS '1 to 7';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.DAY_NAME IS 'Name of the day e.g. Thursday';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.IS_WEEKEND IS '1 for weekend days, otherwise 0';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_DATE_DIM.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


CREATE TABLE MWS.MWS_FB_OPERATIONS_FACT (
                OPERATION_KEY NUMBER(12) NOT NULL,
                SOURCE_SYSTEM_KEY NUMBER(12) NOT NULL,
                OPERATION_TYPE VARCHAR2(20) NOT NULL,
                TRIP_CODE VARCHAR2(50),
                BOOKING_ID VARCHAR2(50),
                DATE_KEY NUMBER(8) NOT NULL,
                VESSEL_KEY NUMBER(10) NOT NULL,
                ROUT_KEY NUMBER(10) NOT NULL,
                PASSENGER_KEY NUMBER(10) NOT NULL,
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                SERVICE_CLASS_KEY NUMBER(10) NOT NULL,
                CONSTRAINT MWS_FB_OPERATIONS_FACT_PK PRIMARY KEY (OPERATION_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_OPERATIONS_FACT IS 'One row per ferry event: a stacked fact for sailings and boardings.

Sources: MWS_FB_VESSELBOOKINGS_EXT_R (Trip rows), MWS_FB_REPORTINGFORBOARDING_EXT_R (Boarding rows), stacked with UNION ALL.

Grain: one ferry sailing (ROW_TYPE = Trip), one passenger who boarded (Boarding Passenger), or one vehicle that boarded (Boarding Vehicle).

Filter on ROW_TYPE when counting. VESSEL_KEY and DUTY_KEY are filled on Trip rows only. PASSENGER_KEY and BOOKING_ID are filled on Boarding rows only. Keys that do not apply are -1 (Unknown).';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.OPERATION_KEY IS 'Unique number of the row. Primary key of the fact.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.SOURCE_SYSTEM_KEY IS 'ID of this event in its source table (the trip table for Trip rows, the boarding table for Boarding rows). Used to trace the row back to the source.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.OPERATION_TYPE IS 'Kind of event the row records: Trip (one ferry sailing), Boarding Passenger (one passenger who boarded) or Boarding Vehicle (one vehicle that boarded). Filter on this column when counting, e.g. count the rows where ROW_TYPE =  Trip  to get the number of trips.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.TRIP_CODE IS 'Code of the trip, from MWS_FB_VESSELBOOKINGS_EXT_R.CODE. Trip rows only; blank on Boarding rows.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.BOOKING_ID IS 'ID of the booking the boarded passenger or vehicle belongs to, from MWS_FB_REPORTINGFORBOARDING_EXT_R.BOOKINGID. Filled on Boarding rows only.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.DATE_KEY IS 'Date of the event. Links to DIM_DATE. The sailing date for Trip rows, the trip date for Boarding rows.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.VESSEL_KEY IS 'The ship that made the trip. To MWS_FB_VESSEL_DIM. Trip rows only; -1 (Unknown) if the trip has no vessel, and on Boarding rows.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.ROUT_KEY IS 'The route and schedule of the trip. To MWS_FB_ROUT_DIM. Trip rows only; -1 (Unknown) if no match, and on Boarding rows.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.PASSENGER_KEY IS 'The passenger who boarded. Links to DIM_PASSENGER. Filled on Boarding Passenger rows. -1 (Unknown) on Trip rows and when the passenger can t be matched.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';
COMMENT ON COLUMN MWS.MWS_FB_OPERATIONS_FACT.SERVICE_CLASS_KEY IS 'To MWS_FB_SERVICE_CLASS_DIM. The service class of the booking the boarded passenger or vehicle belongs to, looked up by BOOKING_ID from MWS_FB_BOOKING_EXT_R (Booking service class). Filled on Boarding rows only; -1 (Unknown) on Trip rows and when the booking can t be matched.';


CREATE TABLE MWS.MWS_FB_SALES_FACT (
                SALES_KEY NUMBER(12) NOT NULL,
                BOOKING_ID VARCHAR2(50) NOT NULL,
                BOOKING_TYPE VARCHAR2(50) NOT NULL,
                BOOKING_CHANNEL VARCHAR2(50) NOT NULL,
                BOOKING_STATUS VARCHAR2(50) NOT NULL,
                SALE_TYPE VARCHAR2(20) NOT NULL,
                DATE_KEY NUMBER(8) NOT NULL,
                PASSENGER_KEY NUMBER(10) NOT NULL,
                SERVICE_CLASS_KEY NUMBER(10) NOT NULL,
                BRANCH_KEY NUMBER(10) NOT NULL,
                VEHICLE_TYPE_KEY NUMBER(10) NOT NULL,
                VESSEL_KEY NUMBER(10) NOT NULL,
                ROUT_KEY NUMBER(10) NOT NULL,
                MEAL_KEY NUMBER NOT NULL,
                VEHICLENUMBER VARCHAR2(9),
                VEHICLE_COUNT NUMBER(1),
                IS_EXCLUSIVE NUMBER(1) NOT NULL,
                ADULT_COUNT NUMBER(5),
                CHILD_COUNT NUMBER(5),
                INFANT_COUNT NUMBER(5),
                FARE_TYPE_NAME VARCHAR2(100),
                FARE_AMOUNT NUMBER(19),
                FARE_AMOUNT_ADULT NUMBER(19),
                FARE_AMOUNT_CHILD NUMBER(19),
                FARE_AMOUNT_INFANT NUMBER(19),
                DISCOUNT_AMOUNT NUMBER(19),
                TOTAL_AMOUNT NUMBER(19),
                VAT_AMOUNT NUMBER(19),
                IS_CANCELLED NUMBER(1),
                MEAL_QUANTITY NUMBER(5),
                MEAL_AMOUNT NUMBER(19),
                UPDATED_AT TIMESTAMP NOT NULL,
                DATA_SOURCE VARCHAR2(100) NOT NULL,
                INSERT_AT TIMESTAMP NOT NULL,
                CONSTRAINT MWS_FB_SALES_FACT_PK PRIMARY KEY (SALES_KEY)
);
COMMENT ON TABLE MWS.MWS_FB_SALES_FACT IS 'One row per booking, meal line or vehicle: a stacked fact for everything the customer buys.

Sources: MWS_FB_BOOKING_EXT_R (Booking rows, TRANSDATE not null, with cancellation flag from MWS_FB_BOOKINGCANCEL_EXT_R), MWS_FB_BOOKINGMEAL_EXT_R (Meal rows), MWS_FB_BOOKINGVEHICLE_EXT_R (Vehicle rows), stacked with UNION ALL.

Grain: one booking (ROW_TYPE = Booking), one meal line on a booking (Meal), or one vehicle on a booking (Vehicle).

Every measure is filled only on its own row type and is 0 on the others, so sums need no filter. Meal and Vehicle rows copy the booking''s date, buyer, service class, branch, price type, booking kind, channel and status.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.SALES_KEY IS 'Surrogate key generated in the load.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.BOOKING_ID IS 'Source booking ID. On meal and vehicle rows, the booking they belong to.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.BOOKING_TYPE IS 'Source: MWS_FB_BOOKING_EXT_R.BOOKINGTYPE. Single or Return. Meal and Vehicle rows copy it from their booking.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.BOOKING_CHANNEL IS 'How the booking was made. Source: MWS_FB_BOOKING_EXT_R.TYPE. Meal and Vehicle rows copy it from their booking.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.BOOKING_STATUS IS 'Source: MWS_FB_BOOKING_EXT_R.STATUS. Null source values are shown as Unknown. Meal and Vehicle rows copy it from their booking.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.SALE_TYPE IS 'Booking, Meal or Vehicle.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.DATE_KEY IS 'To DIM_DATE, from TRANSDATE (booking date).';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.PASSENGER_KEY IS 'To DIM_PASSENGER, the buyer, from MWS_FERRY_PASSENGER_EXT_R.ID';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.SERVICE_CLASS_KEY IS 'To DIM_SERVICE_CLASS, from MWS_FB_SERVICECLASS_EXT_R.ID';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.BRANCH_KEY IS 'To DIM_BRANCH, from MWS_FB_STATIONS_EXT_R.BRANCHCODE';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.VEHICLE_TYPE_KEY IS 'To MWS_FB_VEHICLE_DIM, from MWS_FB_BOOKINGVEHICLE_EXT_R.VEHICLETYPEID. Vehicle rows only; -1 (not applicable) on Booking and Meal rows.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.VESSEL_KEY IS 'The ship that made the booking s trip. To MWS_FB_VESSEL_DIM. Looked up from the booking s trip code: MWS_FB_BOOKING_EXT_R trip code = MWS_FB_VESSELBOOKINGS_EXT_R.CODE, then VESSELID. Meal and Vehicle rows copy it from their booking. -1 (Unknown) if the booking has no trip code or no match.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.ROUT_KEY IS 'The route and schedule of the booking s trip. To MWS_FB_ROUT_DIM. Looked up from the booking s trip code: MWS_FB_BOOKING_EXT_R trip code = MWS_FB_VESSELBOOKINGS_EXT_R.CODE, then ROUTENO + DUTYNO. Meal and Vehicle rows copy it from their booking. -1 (Unknown) if the booking has no trip code or no match.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.MEAL_KEY IS 'Surrogate key';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.VEHICLENUMBER IS 'Source: MWS_FB_BOOKINGVEHICLE_EXT_R.VEHICLENUMBER. Vehicle rows only; blank on Booking and Meal rows.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.VEHICLE_COUNT IS '1 on vehicle rows.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.IS_EXCLUSIVE IS 'Flag. 1 if the booking belongs to an exclusive (private charter) trip, found by matching the booking''s trip code to MWS_FB_EXCLUSIVETRIP_EXT_R.TRIPCODE; otherwise 0. Use it to count and sum exclusive bookings.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.ADULT_COUNT IS 'From MWS_FB_BOOKING_EXT_R.ADULT';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.CHILD_COUNT IS 'From MWS_FB_BOOKING_EXT_R.CHILD';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.INFANT_COUNT IS 'From MWS_FB_BOOKING_EXT_R.INFANT';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.FARE_TYPE_NAME IS 'Fare type of the booking: the pricing category by customer group, e.g. General, CSR, Child Only. From MWS_FB_PRICETYPE_EXT_R.PRICETYPE via MWS_FB_BOOKING_EXT_R.PRICETYPEID. Unknown if missing. Meal and Vehicle rows copy it from their booking.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.FARE_AMOUNT IS 'From MWS_FB_BOOKING_EXT_R.AMOUNT';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.FARE_AMOUNT_ADULT IS 'From MWS_FB_BOOKING_EXT_R.FAREAMOUNTADULT';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.FARE_AMOUNT_CHILD IS 'From MWS_FB_BOOKING_EXT_R.FAREAMOUNTCHILD';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.FARE_AMOUNT_INFANT IS 'From MWS_FB_BOOKING_EXT_R.FAREAMOUNTINFANT';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.DISCOUNT_AMOUNT IS 'From MWS_FB_BOOKING_EXT_R.DISCOUNT';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.TOTAL_AMOUNT IS 'From MWS_FB_BOOKING_EXT_R.TOTALAMOUNT';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.VAT_AMOUNT IS 'Not in the source, calculated in the load as <formula> from TOTAL_AMOUNT. Booking rows only.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.IS_CANCELLED IS '1 if the booking ID exists in MWS_FB_BOOKINGCANCEL_EXT_R.BOOKINGID, otherwise 0. Booking rows only; 0 on meal and vehicle rows.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.MEAL_QUANTITY IS 'Number of units on the meal line. Source: MWS_FB_BOOKINGMEAL_EXT_R.<quantity column>. Meal rows only.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.MEAL_AMOUNT IS 'From MWS_FB_BOOKINGMEAL_EXT_R.TOTALPRICE. Meal rows.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.UPDATED_AT IS 'Date and time the row was last loaded or changed by the ETL.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.DATA_SOURCE IS 'Source table the row was loaded from, e.g. MWS_FB_BOOKING_EXT_R. Used to trace a row back to its source.';
COMMENT ON COLUMN MWS.MWS_FB_SALES_FACT.INSERT_AT IS 'INSERT_AT: Date and time the row was first inserted by the ETL. UPDATED_AT is the last time it changed.';


ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT DIM_VEHICLE_TYPE_FACT_SALES_FK
FOREIGN KEY (VEHICLE_TYPE_KEY)
REFERENCES MWS.MWS_FB_VEHICLE_TYPE_DIM (VEHICLE_TYPE_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_OPERATIONS_FACT ADD CONSTRAINT DIM_DUTY_FACT_OPERATIONS_FK
FOREIGN KEY (ROUT_KEY)
REFERENCES MWS.MWS_FB_ROUT_DIM (ROUT_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT MWS_FB_ROUT_DIM_MWS_FB_SALE261
FOREIGN KEY (ROUT_KEY)
REFERENCES MWS.MWS_FB_ROUT_DIM (ROUT_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_OPERATIONS_FACT ADD CONSTRAINT DIM_VESSEL_FACT_OPERATIONS_FK
FOREIGN KEY (VESSEL_KEY)
REFERENCES MWS.MWS_FB_VESSEL_DIM (VESSEL_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT MWS_FB_VESSEL_DIM_MWS_FB_SA651
FOREIGN KEY (VESSEL_KEY)
REFERENCES MWS.MWS_FB_VESSEL_DIM (VESSEL_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT DIM_PASSENGER_FACT_SALES_FK
FOREIGN KEY (PASSENGER_KEY)
REFERENCES MWS.MWS_FB_PASSENGER_DIM (PASSENGER_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_OPERATIONS_FACT ADD CONSTRAINT DIM_PASSENGER_FACT_OPERATIO593
FOREIGN KEY (PASSENGER_KEY)
REFERENCES MWS.MWS_FB_PASSENGER_DIM (PASSENGER_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT MWS_FB_MEAL_DIM_MWS_FB_SALE910
FOREIGN KEY (MEAL_KEY)
REFERENCES MWS.MWS_FB_MEAL_DIM (MEAL_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT DIM_BRANCH_FACT_SALES_FK
FOREIGN KEY (BRANCH_KEY)
REFERENCES MWS.MWS_FB_BRANCH_DIM (BRANCH_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT DIM_SERVICE_CLASS_FACT_SALE419
FOREIGN KEY (SERVICE_CLASS_KEY)
REFERENCES MWS.MWS_FB_SERVICE_CLASS_DIM (SERVICE_CLASS_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_OPERATIONS_FACT ADD CONSTRAINT MWS_FB_SERVICE_CLASS_DIM_MW613
FOREIGN KEY (SERVICE_CLASS_KEY)
REFERENCES MWS.MWS_FB_SERVICE_CLASS_DIM (SERVICE_CLASS_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_SALES_FACT ADD CONSTRAINT DIM_DATE_FACT_SALES_FK
FOREIGN KEY (DATE_KEY)
REFERENCES MWS.MWS_FB_DATE_DIM (DATE_KEY)
NOT DEFERRABLE;

ALTER TABLE MWS.MWS_FB_OPERATIONS_FACT ADD CONSTRAINT DIM_DATE_FACT_OPERATIONS_FK
FOREIGN KEY (DATE_KEY)
REFERENCES MWS.MWS_FB_DATE_DIM (DATE_KEY)
NOT DEFERRABLE;
