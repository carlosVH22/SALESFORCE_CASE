--DB AND SCHEMA CREATION

USE WORKSPACE SALESFORCE_PROJECT;

CREATE OR REPLACE DATABASE SALESFORCE;

USE DATABASE SALESFORCE;

CREATE OR REPLACE SCHEMA TABLEAU_SCH;

USE SCHEMA TABLEAU_SCH;



--S3 CONECTION AND FORMAT (EXTRACT)

CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE = CSV
SKIP_HEADER = 1
FIELD_DELIMITER = ';'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
NULL_IF = ('NULL', '')
EMPTY_FIELD_AS_NULL = TRUE;


CREATE OR REPLACE STORAGE INTEGRATION AWS_S3_INT
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::717740917877:role/SNOWFLAKE_ROL_TEST'
STORAGE_ALLOWED_LOCATIONS = ('s3://learn-2cloud-snowflake/');

DESCRIBE INTEGRATION AWS_S3_INT;

CREATE OR REPLACE STAGE AWS_STAGE_TEST
STORAGE_INTEGRATION = AWS_S3_INT
URL = 's3://learn-2cloud-snowflake/loadingdata/LOADcsv/'
FILE_FORMAT = CSV_FORMAT;

LIST @AWS_STAGE_TEST;



--CREATION OF RAW TABLES (LOAD)

CREATE OR REPLACE TABLE PROJECTS_RAW (
    ID VARCHAR,
    NAME VARCHAR,
    SUBMITTED_HOURS VARCHAR,
    FORECASTED_HOURS VARCHAR,
    ACTUAL_REVENUE VARCHAR,
    FORECASTED_REVENUE VARCHAR
);



CREATE OR REPLACE TABLE ASSIGNMENTS_RAW (
    ID VARCHAR,
    PRJ_ID VARCHAR,
    ASGN_NAME VARCHAR,
    ASGN_STATUS VARCHAR,
    BILL_RATE VARCHAR,
    SUBMITTED_HOURS VARCHAR,
    FORECASTED_HOURS VARCHAR,
    ACTUAL_REVENUE VARCHAR,
    FORECASTED_REVENUE VARCHAR
);


CREATE OR REPLACE TABLE TIMECARDS_RAW (
    ID VARCHAR,
    ASGN_ID VARCHAR,
    NAME VARCHAR,
    TC_STATUS VARCHAR,
    WEEK_START VARCHAR,
    WEEK_END VARCHAR,
    SUBMITTED_HOURS VARCHAR
);

COPY INTO PROJECTS_RAW
FROM @AWS_STAGE_TEST/Project.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'CONTINUE';


COPY INTO ASSIGNMENTS_RAW
FROM @AWS_STAGE_TEST/Assignment.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO TIMECARDS_RAW
FROM @AWS_STAGE_TEST/Timecards.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'CONTINUE';


--CLEANING DATA (TRANSFORM)

CREATE OR REPLACE TABLE PROJECTS AS

SELECT
    ID AS PROJECT_ID,
    TRIM(NAME) AS PROJECT_NAME,
    
    TRY_TO_DOUBLE(
        REPLACE(
            SUBMITTED_HOURS,
            ',',
            '.'
        )
    ) AS SUBMITTED_HOURS,
    
    TRY_TO_DOUBLE(
        REPLACE(
            FORECASTED_HOURS,
            ',',
            '.'
        )
    ) AS FORECASTED_HOURS,

    TRY_TO_DOUBLE(
        REPLACE(
            REPLACE(
                REPLACE(ACTUAL_REVENUE, '$', ''),
                '.',
                ''
            ),
            ',',
            '.'
        )
    ) AS ACTUAL_REVENUE,

    TRY_TO_DOUBLE(
        REPLACE(
            REPLACE(
                REPLACE(FORECASTED_REVENUE, '$', ''),
                '.',
                ''
            ),
            ',',
            '.'
        )
    ) AS FORECASTED_REVENUE

FROM PROJECTS_RAW

WHERE 1=1 
AND ID IS NOT NULL;





CREATE OR REPLACE TABLE ASSIGNMENTS AS

SELECT
    ID AS ASSIGNMENT_ID,
    PRJ_ID AS PROJECT_ID,
    TRIM(ASGN_NAME) AS ASSIGNMENT_NAME,
    TRIM(ASGN_STATUS) AS ASSIGNMENT_STATUS,

    TRY_TO_DOUBLE(
        REPLACE(
            REPLACE(
                REPLACE(BILL_RATE, '$', ''),
                '.',
                ''
            ),
            ',',
            '.'
        )
    ) AS BILL_RATE,
    
    TRY_TO_DOUBLE(
        REPLACE(
            SUBMITTED_HOURS,
            ',',
            '.'
        )
    ) AS SUBMITTED_HOURS,
    
    TRY_TO_DOUBLE(
        REPLACE(
            FORECASTED_HOURS,
            ',',
            '.'
        )
    ) AS FORECASTED_HOURS,

    TRY_TO_DOUBLE(
        REPLACE(
            REPLACE(
                REPLACE(ACTUAL_REVENUE, '$', ''),
                '.',
                ''
            ),
            ',',
            '.'
        )
    ) AS ACTUAL_REVENUE,

    TRY_TO_DOUBLE(
        REPLACE(
            REPLACE(
                REPLACE(FORECASTED_REVENUE, '$', ''),
                '.',
                ''
            ),
            ',',
            '.'
        )
    ) AS FORECASTED_REVENUE

FROM ASSIGNMENTS_RAW

WHERE 1=1 
AND ID IS NOT NULL;



CREATE OR REPLACE TABLE TIMECARDS AS

SELECT 
    TRIM(ID) AS TIMECARD_ID,
    TRIM(ASGN_ID) AS ASSIGNMENT_ID,
    TRIM(NAME) AS TIMECARD_NAME,
    TRIM(TC_STATUS) AS TIMECARD_STATUS,
    
        TRY_TO_DATE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    REPLACE(LOWER(WEEK_START),
                                                    'ene','jan'),
                                                'feb','feb'),
                                            'mar','mar'),
                                        'abr','apr'),
                                    'may','may'),
                                'jun','jun'),
                            'jul','jul'),
                        'ago','aug'),
                    'sep','sep'),
                'oct','oct'),
            'nov','nov'),
        'dic','dec'),
        'DD/MON/YYYY'
    ) AS WEEK_START,

    TRY_TO_DATE(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    REPLACE(LOWER(WEEK_END),
                                                    'ene','jan'),
                                                'feb','feb'),
                                            'mar','mar'),
                                        'abr','apr'),
                                    'may','may'),
                                'jun','jun'),
                            'jul','jul'),
                        'ago','aug'),
                    'sep','sep'),
                'oct','oct'),
            'nov','nov'),
        'dic','dec'),
        'DD/MON/YYYY'
    ) AS WEEK_END,
    TRY_TO_DOUBLE(
        REPLACE(
            SUBMITTED_HOURS,
            ',',
            '.'
        )
    ) AS SUBMITTED_HOURS,

FROM TIMECARDS_RAW 
WHERE 1=1 
AND ID IS NOT NULL;

SELECT 
    *,
    SUBMITTED_HOURS / 


FROM PROJECTS LIMIT 1;

SELECT * FROM TIMECARDS;
