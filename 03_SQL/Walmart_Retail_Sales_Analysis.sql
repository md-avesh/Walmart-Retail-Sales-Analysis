
/* ============================
   STEP 1 — Database verify 👇🏻
   ============================ */

SELECT current_database();


/* ====================================
   STEP 2 - Table Create 👇🏻
   ==================================== */
  
CREATE TABLE walmart_master (
    store INTEGER,
    dept INTEGER,
    date DATE,
    weekly_sales NUMERIC(14,2),
    isholiday BOOLEAN,
    temperature NUMERIC(10,2),
    fuel_price NUMERIC(10,3),
    markdown1 NUMERIC(14,2),
    markdown2 NUMERIC(14,2),
    markdown3 NUMERIC(14,2),
    markdown4 NUMERIC(14,2),
    markdown5 NUMERIC(14,2),
    type CHAR(1),
    size INTEGER
);


/* ====================================
   STEP 3 - Staging Table Creation 👇🏻
   ==================================== */
   
CREATE TABLE walmart_master_staging (
    store TEXT,
    dept TEXT,
    date TEXT,
    weekly_sales TEXT,
    isholiday TEXT,
    temperature TEXT,
    fuel_price TEXT,
    markdown1 TEXT,
    markdown2 TEXT,
    markdown3 TEXT,
    markdown4 TEXT,
    markdown5 TEXT,
    type TEXT,
    size TEXT
);

/* ====================================
   STEP 4 - staging date check 👇🏻
   ==================================== */
   
SELECT COUNT(*)
FROM walmart_master_staging;

SELECT 
date,
To_DATE(date,'DD-MM-YYYY') AS converted_date
FROM walmart_master_staging
LIMIT 10;

/* ====================================
   STEP 5 - Final Table Data Insert 👇🏻
   ==================================== */

INSERT INTO walmart_master (
    store,
    dept,
    date,
    weekly_sales,
    isholiday,
    temperature,
    fuel_price,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    type,
    size
)
SELECT
    store::INTEGER,
    dept::INTEGER,
    TO_DATE(date, 'DD-MM-YYYY'),
    weekly_sales::NUMERIC(14,2),
    isholiday::BOOLEAN,
    temperature::NUMERIC(10,2),
    fuel_price::NUMERIC(10,3),
    NULLIF(markdown1, '')::NUMERIC(14,2),
    NULLIF(markdown2, '')::NUMERIC(14,2),
    NULLIF(markdown3, '')::NUMERIC(14,2),
    NULLIF(markdown4, '')::NUMERIC(14,2),
    NULLIF(markdown5, '')::NUMERIC(14,2),
    type::CHAR(1),
    size::INTEGER
FROM walmart_master_staging;

/* ========================================
   STEP 6 - Row Count + Date Validation 👇🏻
   ======================================== */

SELECT
COUNT(*) AS total_records,
MIN(date) AS min_date,
MAX(DATE) AS max_date,
COUNT(DISTINCT date) AS unique_dates,
COUNT(*) FILTER(WHERE store IS NULL) AS missing_store,
COUNT(*) FILTER(WHERE dept IS NULL) AS missing_dept,
COUNT(*) FILTER(WHERE date IS NULL) AS missing_date,
COUNT(*) FILTER(WHERE weekly_sales IS NULL) AS missing_sales,
COUNT(*) FILTER(WHERE isholiday IS NULL) AS missing_holiday
FROM walmart_master;

/* =================================================
   STEP 7 - Excel vs PostgreSQL Sales Validation 👇🏻
   ================================================= */

SELECT 
SUM(weekly_sales) AS total_weekly_sales,
ROUND (AVG(weekly_sales), 4) AS averagw_weekly_sales,
MIN(weekly_sales) AS minimum_weekly_sales,
MAX(weekly_sales) AS maximum_weekly_sales
FROM walmart_master;

-- =====================================================
-- STEP 8 — STORE & DEPARTMENT MASTER VALIDATION
-- Purpose: Validate unique stores, unique departments,
--          and their ID ranges in walmart_master 👇🏻
-- =====================================================

SELECT
COUNT (DISTINCT store) AS unique_stores,
MIN(store) AS min_store_id,
MAX(store) AS max_store_id,
COUNT(DISTINCT dept) AS unique_departments,
MIN(dept) AS min_department_id,
MAX(dept) AS max_department_id
FROM walmart_master;

-- =====================================================
-- STEP 9 — HOLIDAY FLAG VALIDATION
-- Purpose: Validate TRUE/FALSE holiday records and
--          check for missing holiday values
-- =====================================================

SELECT
COUNT(*) AS total_records,
COUNT(*) FILTER(WHERE isholiday= TRUE) AS holiday_records,
COUNT(*) FILTER(WHERE isholiday= FALSE) AS non_holiday_records,
COUNT(*) FILTER(WHERE isholiday IS NULL) AS missing_holiday_records
FROM walmart_master;

-- =====================================================
-- STEP 10 — STORE TYPE & SIZE VALIDATION
-- Purpose: Validate store types, store size range,
--          and missing store master values
-- =====================================================

SELECT 
COUNT(DISTINCT type) AS unique_store_type,
COUNT(*) FILTER (WHERE type = 'A') AS type_a_records,
COUNT(*) FILTER (WHERE type = 'B') AS type_b_records,
COUNT(*) FILTER (WHERE type = 'C') AS type_c_records,
COUNT(*) FILTER (WHERE type IS NULL) AS missing_store_type,
COUNT(*) FILTER (WHERE size IS NULL) AS missing_store_size,
MIN(size) AS minimum_store_size,
MAX(size) AS maximum_store_size
FROM walmart_master;

-- =====================================================
-- STEP 11 — STORE MASTER UNIQUENESS VALIDATION
-- Purpose: Verify that each Store ID has exactly one
--          Store Type and one Store Size
-- =====================================================

SELECT
store,
COUNT(DISTINCT type) AS type_count,
COUNT(DISTINCT size) AS size_count
FROM walmart_master
GROUP BY store
HAVING COUNT(DISTINCT type) <> 1
OR COUNT(DISTINCT size) <> 1;

-- =====================================================
-- STEP 12 — DEPARTMENT COVERAGE VALIDATION
-- Purpose: Validate department IDs and confirm the
--          number of unique departments in walmart_master
-- =====================================================

SELECT
    COUNT(DISTINCT dept) AS unique_departments,
    MIN(dept) AS minimum_department_id,
    MAX(dept) AS maximum_department_id
FROM walmart_master;

-- =====================================================
-- STEP 13 — STORE TYPE SALES ANALYSIS
-- Purpose: Compare total and average weekly sales
--          across Store Types A, B and C
-- =====================================================

SELECT
    type AS store_type,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales,
    ROUND(AVG(weekly_sales), 2) AS average_weekly_sales,
    COUNT(DISTINCT store) AS store_count
FROM walmart_master
GROUP BY type
ORDER BY type;

-- =====================================================
-- STEP 14 — STORE TYPE SALES CONTRIBUTION %
-- Purpose: Calculate each Store Type's contribution
--          to overall Walmart Weekly Sales
-- =====================================================

SELECT
    type AS store_type,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales,
    ROUND(
        SUM(weekly_sales) * 100.0
        / SUM(SUM(weekly_sales)) OVER (),
        2
    ) AS sales_contribution_pct
FROM walmart_master
GROUP BY type
ORDER BY type;

-- =====================================================
-- STEP 15 — STORE-LEVEL SALES PERFORMANCE
-- Purpose: Analyze total and average weekly sales
--          for each Walmart store
-- =====================================================

SELECT
    store,
    type AS store_type,
    size AS store_size,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales,
    ROUND(AVG(weekly_sales), 2) AS average_weekly_sales
FROM walmart_master
GROUP BY store, type, size
ORDER BY total_weekly_sales DESC;

-- =====================================================
-- STEP 16 — TOP 10 STORES BY TOTAL SALES
-- Purpose: Identify the 10 highest-performing Walmart
--          stores based on total weekly sales
-- =====================================================

SELECT
    store,
    type AS store_type,
    size AS store_size,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales
FROM walmart_master
GROUP BY store, type, size
ORDER BY total_weekly_sales DESC
LIMIT 10;

-- =====================================================
-- STEP 17 — BOTTOM 10 STORES BY TOTAL SALES
-- Purpose: Identify the 10 lowest-performing Walmart
--          stores based on total weekly sales
-- =====================================================

SELECT
    store,
    type AS store_type,
    size AS store_size,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales
FROM walmart_master
GROUP BY store, type, size
ORDER BY total_weekly_sales ASC
LIMIT 10;

-- =====================================================
-- STEP 18 — STORE SALES PER SIZE UNIT
-- Purpose: Measure sales efficiency relative to each
--          store's physical size
-- =====================================================

SELECT
    store,
    type AS store_type,
    size AS store_size,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales,
    ROUND(
        SUM(weekly_sales) / NULLIF(size, 0),
        6
    ) AS sales_per_size_unit
FROM walmart_master
GROUP BY store, type, size
ORDER BY sales_per_size_unit DESC;

-- =====================================================
-- STEP 19 — DEPARTMENT SALES ANALYSIS
-- Purpose: Analyze total and average weekly sales
--          across Walmart departments
-- =====================================================

SELECT
    dept AS department,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales,
    ROUND(AVG(weekly_sales), 2) AS average_weekly_sales,
    COUNT(DISTINCT store) AS store_count
FROM walmart_master
GROUP BY dept
ORDER BY total_weekly_sales DESC;

-- =====================================================
-- STEP 20 — TOP 10 DEPARTMENTS BY TOTAL SALES
-- Purpose: Identify the 10 highest-performing Walmart
--          departments based on total weekly sales
-- =====================================================

SELECT
    dept AS department,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales
FROM walmart_master
GROUP BY dept
ORDER BY total_weekly_sales DESC
LIMIT 10;

-- =====================================================
-- STEP 21 — BOTTOM 10 DEPARTMENTS BY TOTAL SALES
-- Purpose: Identify the 10 lowest-performing Walmart
--          departments based on total weekly sales
-- =====================================================

SELECT
    dept AS department,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales
FROM walmart_master
GROUP BY dept
ORDER BY total_weekly_sales ASC
LIMIT 10;

-- =====================================================
-- STEP 22 — DEPARTMENT SALES CONTRIBUTION %
-- Purpose: Calculate each department's contribution
--          to overall Walmart Weekly Sales
-- =====================================================

SELECT
    dept AS department,
    ROUND(SUM(weekly_sales), 2) AS total_weekly_sales,
    ROUND(
        SUM(weekly_sales) * 100.0
        / SUM(SUM(weekly_sales)) OVER (),
        2
    ) AS sales_contribution_pct
FROM walmart_master
GROUP BY dept
ORDER BY sales_contribution_pct DESC;

-- =====================================================
-- STEP 23 — DEPARTMENT AVERAGE SALES VS OVERALL AVERAGE
-- Purpose: Compare each department's average weekly sales
--          with the overall Walmart average
-- =====================================================

WITH department_avg AS (
    SELECT
        dept,
        AVG(weekly_sales) AS department_avg_sales
    FROM walmart_master
    GROUP BY dept
)

SELECT
    dept AS department,

    ROUND(department_avg_sales, 2)
        AS department_average_sales,

    ROUND(
        (SELECT AVG(weekly_sales) FROM walmart_master),
        2
    ) AS overall_average_sales,

    ROUND(
        department_avg_sales
        - (SELECT AVG(weekly_sales) FROM walmart_master),
        2
    ) AS difference_from_overall_average,

    ROUND(
        (
            department_avg_sales
            - (SELECT AVG(weekly_sales) FROM walmart_master)
        )
        / NULLIF(
            (SELECT AVG(weekly_sales) FROM walmart_master),
            0
        ) * 100,
        2
    ) AS difference_pct

FROM department_avg
ORDER BY difference_from_overall_average DESC;

-- =====================================================
-- STEP 24 — DEPARTMENT PERFORMANCE STATUS
-- Purpose: Classify each department as Above Average
--          or Below Average based on overall sales average
-- =====================================================

WITH department_avg AS (
    SELECT
        dept,
        AVG(weekly_sales) AS department_avg_sales
    FROM walmart_master
    GROUP BY dept
),

overall_avg AS (
    SELECT
        AVG(weekly_sales) AS overall_average_sales
    FROM walmart_master
)

SELECT
    d.dept AS department,

    ROUND(d.department_avg_sales, 2)
        AS average_weekly_sales,

    ROUND(o.overall_average_sales, 2)
        AS overall_average_sales,

    CASE
        WHEN d.department_avg_sales >= o.overall_average_sales
            THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_status

FROM department_avg d
CROSS JOIN overall_avg o
ORDER BY d.dept;

-- =====================================================
-- STEP 25 — DEPARTMENT PERFORMANCE STATUS SUMMARY
-- Purpose: Count departments classified as Above Average
--          and Below Average
-- =====================================================

WITH department_avg AS (
    SELECT
        dept,
        AVG(weekly_sales) AS department_avg_sales
    FROM walmart_master
    GROUP BY dept
),

overall_avg AS (
    SELECT
        AVG(weekly_sales) AS overall_average_sales
    FROM walmart_master
)

SELECT
    CASE
        WHEN d.department_avg_sales >= o.overall_average_sales
            THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_status,
    COUNT(*) AS department_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM department_avg d
CROSS JOIN overall_avg o
GROUP BY
    CASE
        WHEN d.department_avg_sales >= o.overall_average_sales
            THEN 'Above Average'
        ELSE 'Below Average'
    END
ORDER BY performance_status;

-- =====================================================
-- STEP 26 — HOLIDAY VS NON-HOLIDAY SALES ANALYSIS
-- Purpose: Compare Holiday and Non-Holiday sales
--          across Walmart Store Types
-- =====================================================

SELECT
    type AS store_type,

    ROUND(
        SUM(weekly_sales) FILTER (WHERE isholiday = TRUE),
        2
    ) AS holiday_sales,

    ROUND(
        SUM(weekly_sales) FILTER (WHERE isholiday = FALSE),
        2
    ) AS non_holiday_sales,

    ROUND(
        SUM(weekly_sales),
        2
    ) AS total_sales,

    ROUND(
        SUM(weekly_sales) FILTER (WHERE isholiday = TRUE)
        * 100.0
        / NULLIF(SUM(weekly_sales), 0),
        2
    ) AS holiday_sales_contribution_pct

FROM walmart_master
GROUP BY type
ORDER BY type;


-- =====================================================
-- STEP 27 — OVERALL HOLIDAY VS NON-HOLIDAY SALES
-- Purpose: Compare total Walmart sales on Holiday
--          and Non-Holiday weeks
-- =====================================================

SELECT
    ROUND(
        SUM(weekly_sales) FILTER (WHERE isholiday = TRUE),
        2
    ) AS holiday_sales,

    ROUND(
        SUM(weekly_sales) FILTER (WHERE isholiday = FALSE),
        2
    ) AS non_holiday_sales,

    ROUND(
        SUM(weekly_sales),
        2
    ) AS total_sales,

    ROUND(
        SUM(weekly_sales) FILTER (WHERE isholiday = TRUE)
        * 100.0
        / NULLIF(SUM(weekly_sales), 0),
        2
    ) AS holiday_sales_contribution_pct

FROM walmart_master;

-- =====================================================
-- STEP 28 — HOLIDAY VS NON-HOLIDAY AVERAGE SALES
-- Purpose: Compare average weekly sales between
--          Holiday and Non-Holiday weeks
-- =====================================================

SELECT
    CASE
        WHEN isholiday = TRUE THEN 'Holiday'
        ELSE 'Non-Holiday'
    END AS sales_period,

    COUNT(*) AS record_count,

    ROUND(AVG(weekly_sales), 2) AS average_weekly_sales

FROM walmart_master
GROUP BY isholiday
ORDER BY isholiday DESC;

-- =====================================================
-- STEP 29 — STORE × HOLIDAY PERFORMANCE
-- Purpose: Compare each store's average weekly sales
--          during Holiday and Non-Holiday periods
-- =====================================================

SELECT
    store,

    ROUND(
        AVG(weekly_sales) FILTER (WHERE isholiday = TRUE),
        2
    ) AS holiday_avg_sales,

    ROUND(
        AVG(weekly_sales) FILTER (WHERE isholiday = FALSE),
        2
    ) AS non_holiday_avg_sales,

    ROUND(
        AVG(weekly_sales) FILTER (WHERE isholiday = TRUE)
        - AVG(weekly_sales) FILTER (WHERE isholiday = FALSE),
        2
    ) AS difference,

    ROUND(
        (
            AVG(weekly_sales) FILTER (WHERE isholiday = TRUE)
            - AVG(weekly_sales) FILTER (WHERE isholiday = FALSE)
        )
        / NULLIF(
            AVG(weekly_sales) FILTER (WHERE isholiday = FALSE),
            0
        ) * 100,
        2
    ) AS difference_pct

FROM walmart_master
GROUP BY store
ORDER BY difference_pct DESC;

-- =====================================================
-- STEP 30 — STORE HOLIDAY PERFORMANCE SUMMARY
-- Purpose: Summarize how many stores perform better
--          or worse during Holiday periods
-- =====================================================

WITH store_performance AS (
    SELECT
        store,
        AVG(weekly_sales) FILTER (WHERE isholiday = TRUE)
            AS holiday_avg_sales,
        AVG(weekly_sales) FILTER (WHERE isholiday = FALSE)
            AS non_holiday_avg_sales
    FROM walmart_master
    GROUP BY store
)

SELECT
    CASE
        WHEN holiday_avg_sales > non_holiday_avg_sales
            THEN 'Holiday Higher'
        ELSE 'Holiday Lower'
    END AS performance_status,

    COUNT(*) AS store_count,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM store_performance
GROUP BY
    CASE
        WHEN holiday_avg_sales > non_holiday_avg_sales
            THEN 'Holiday Higher'
        ELSE 'Holiday Lower'
    END
ORDER BY performance_status;

-- =====================================================
-- STEP 30 — STORE SALES RANKING & PERFORMANCE SUMMARY
-- Purpose: Create a consolidated performance view of
--          all Walmart stores
-- =====================================================

WITH store_performance AS (
    SELECT
        store,
        SUM(weekly_sales) AS total_sales,
        AVG(weekly_sales) AS average_weekly_sales
    FROM walmart_master
    GROUP BY store
),

ranked_stores AS (
    SELECT
        store,
        total_sales,
        average_weekly_sales,

        RANK() OVER (
            ORDER BY total_sales DESC
        ) AS sales_rank,

        AVG(total_sales) OVER () AS overall_store_avg_sales

    FROM store_performance
)

SELECT
    store,

    ROUND(total_sales, 2) AS total_sales,

    ROUND(average_weekly_sales, 2)
        AS average_weekly_sales,

    sales_rank,

    CASE
        WHEN total_sales >= overall_store_avg_sales
            THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_status

FROM ranked_stores
ORDER BY sales_rank;

-- =====================================================
-- STEP 31 — FINAL STORE PERFORMANCE SUMMARY
-- Purpose: Summarize stores performing above or below
--          the overall average store sales
-- =====================================================

WITH store_sales AS (
    SELECT
        store,
        SUM(weekly_sales) AS total_sales
    FROM walmart_master
    GROUP BY store
),

classified_stores AS (
    SELECT
        store,
        total_sales,

        CASE
            WHEN total_sales >= AVG(total_sales) OVER ()
                THEN 'Above Average'
            ELSE 'Below Average'
        END AS performance_status

    FROM store_sales
)

SELECT
    performance_status,
    COUNT(*) AS store_count,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM classified_stores
GROUP BY performance_status
ORDER BY performance_status;

-- =====================================================
-- STEP 32 — FINAL DATA QUALITY & BUSINESS VALIDATION
-- Purpose: Final validation of the Walmart master dataset
--          before closing the SQL analysis phase
-- =====================================================

SELECT

    -- Record count
    COUNT(*) AS total_records,

    -- Business dimensions
    COUNT(DISTINCT store) AS unique_stores,
    COUNT(DISTINCT dept) AS unique_departments,

    -- Missing-value checks
    COUNT(*) FILTER (WHERE store IS NULL)
        AS missing_store,

    COUNT(*) FILTER (WHERE dept IS NULL)
        AS missing_department,

    COUNT(*) FILTER (WHERE date IS NULL)
        AS missing_date,

    COUNT(*) FILTER (WHERE weekly_sales IS NULL)
        AS missing_weekly_sales,

    COUNT(*) FILTER (WHERE isholiday IS NULL)
        AS missing_holiday_flag,

    -- Negative and zero sales checks
    COUNT(*) FILTER (WHERE weekly_sales < 0)
        AS negative_sales_records,

    COUNT(*) FILTER (WHERE weekly_sales = 0)
        AS zero_sales_records,

    -- Date coverage
    MIN(date) AS minimum_date,
    MAX(date) AS maximum_date

FROM walmart_master;

-- =====================================================
-- STEP 33 — DUPLICATE BUSINESS KEY VALIDATION
-- Purpose: Check duplicate Store + Department + Date
--          combinations
-- =====================================================

SELECT
    COUNT(*) AS duplicate_business_keys
FROM (
    SELECT
        store,
        dept,
        date
    FROM walmart_master
    GROUP BY
        store,
        dept,
        date
    HAVING COUNT(*) > 1
) AS duplicate_check;