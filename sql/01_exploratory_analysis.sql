-- Berlin Bicycle Traffic Analytics
-- SQL Exploratory Data Analysis
-- Dataset: Berlin Bicycle Counting Data, 2025

USE berlin_bicycle_analytics;

SELECT COUNT(*) AS total_records
FROM bicycle_counts;


-- Query 1: Bicycle traffic by counting station
-- Objective: Identify stations with the highest recorded traffic

SELECT
    s.station_id,
    s.station_name,
    SUM(b.bicycle_count) AS total_bicycles,
    COUNT(b.bicycle_count) AS valid_hours,
    COUNT(*) AS expected_hours,
    ROUND(
        COUNT(b.bicycle_count) * 100.0 / COUNT(*),
        2
    ) AS coverage_percentage
FROM bicycle_counts AS b
JOIN stations AS s
    ON b.station_id = s.station_id
GROUP BY
    s.station_id,
    s.station_name
ORDER BY total_bicycles DESC;

-- FINDINGS:
-- Oberbaumbrücke Ost recorded the highest bicycle
-- volume in 2025, with 2,087,711 passages.
--
-- Oberbaumbrücke West ranked second with 1,951,446.
--
-- Maybachufer ranked third with 1,639,918.
--
-- Schönhauser Allee ranked fourth with 1,321,849.
--
-- Data coverage for these stations exceeded 99.7%.
--
-- Note: Counts represent bicycle passages,
-- not unique cyclists.



-- Query 2: Average bicycle traffic by hour
-- Objective: Identify peak cycling hours

SELECT
    hour,
    ROUND(AVG(bicycle_count), 2)
        AS avg_bicycles_per_station_hour,
    COUNT(bicycle_count)
        AS valid_observations
FROM bicycle_counts
GROUP BY hour
ORDER BY hour;

-- FINDINGS:
-- The highest average bicycle traffic occurs at 18:00,
-- with 195.14 bicycle passages per valid station-hour.
--
-- The morning peak occurs at 08:00, with an average
-- of 163.10 passages per valid station-hour.
--
-- The quietest hour is 03:00, averaging 5.05 passages.
--
-- The results suggest morning and evening traffic peaks.
-- Further weekday/weekend analysis is needed to
-- investigate whether these reflect commuting patterns.



-- Query 3: Weekday vs Weekend Bicycle Traffic
-- Objective: Compare average cycling activity by day type

SELECT
    CASE
        WHEN is_weekend = 1 THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,

    ROUND(AVG(bicycle_count), 2)
        AS avg_bicycles_per_station_hour,

    COUNT(bicycle_count)
        AS valid_observations,

    ROUND(
        COUNT(bicycle_count) * 100.0 / COUNT(*),
        2
    ) AS coverage_percentage

FROM bicycle_counts

GROUP BY is_weekend

ORDER BY is_weekend;

-- FINDINGS:
-- Weekday average: 105.27 bicycles per valid station-hour.
-- Weekend average: 64.86 bicycles per valid station-hour.
--
-- Weekday traffic is approximately 62.3% higher.
--
-- Data coverage is similar:
-- Weekday: 98.57%
-- Weekend: 98.53%
--
-- This pattern is consistent with commuting activity,
-- but journey purposes cannot be confirmed from counts alone.



-- Query 4: Hourly bicycle traffic by day type
-- Objective: Compare weekday and weekend traffic patterns

SELECT
    hour,

    ROUND(
        AVG(CASE
            WHEN is_weekend = 0
            THEN bicycle_count
        END), 2
    ) AS weekday_average,

    ROUND(
        AVG(CASE
            WHEN is_weekend = 1
            THEN bicycle_count
        END), 2
    ) AS weekend_average,

    COUNT(CASE
        WHEN is_weekend = 0
        THEN bicycle_count
    END) AS weekday_valid_observations,

    COUNT(CASE
        WHEN is_weekend = 1
        THEN bicycle_count
    END) AS weekend_valid_observations

FROM bicycle_counts

GROUP BY hour
ORDER BY hour;

-- FINDINGS:
-- Weekday morning peak: 08:00 (216.72 bicycles/station-hour).
-- Weekday evening peak: 18:00 (224.75 bicycles/station-hour).
--
-- Weekend peak: 14:00 (131.16 bicycles/station-hour).
--
-- Weekday traffic at 08:00 is approximately
-- 7.6 times the weekend traffic at the same hour.
--
-- Weekend midnight activity is approximately
-- twice the weekday midnight activity.
--
-- These patterns are consistent with different
-- commuting and leisure behaviors, but journey
-- purposes cannot be established from counts alone.



-- Query 5: Monthly Bicycle Traffic Analysis
-- Objective: Identify monthly cycling patterns
-- and assess data completeness.

SELECT
    month,
    MONTHNAME(timestamp) AS month_name,

    SUM(bicycle_count) AS recorded_bicycles,

    ROUND(AVG(bicycle_count), 2)
        AS avg_bicycles_per_station_hour,

    COUNT(bicycle_count) AS valid_observations,

    COUNT(*) AS expected_observations,

    ROUND(
        COUNT(bicycle_count) * 100.0 / COUNT(*),
        2
    ) AS coverage_percentage

FROM bicycle_counts

GROUP BY
    month,
    MONTHNAME(timestamp)

ORDER BY month;

-- FINDINGS:
-- June had the highest average recorded bicycle traffic:
-- 120.22 passages per valid station-hour.
--
-- December had the lowest average:
-- 60.73 passages per valid station-hour.
--
-- Recorded cycling activity generally increased
-- toward summer and decreased toward winter.
--
-- Monthly coverage fell to approximately 94%
-- during October, November, and December.
--
-- This may influence monthly comparisons because
-- some counting stations have extended data gaps.
--
-- Next: Use coverage-based station selection
-- to obtain more consistent monthly comparisons.



-- Query 6: Monthly traffic at high-coverage stations
-- Objective: Reduce bias from extended station outages

WITH station_coverage AS (
    SELECT
        station_id,
        COUNT(bicycle_count) AS valid_hours,
        COUNT(*) AS total_hours,
        COUNT(bicycle_count) * 100.0 / COUNT(*)
            AS coverage_percentage
    FROM bicycle_counts
    GROUP BY station_id
),

reliable_stations AS (
    SELECT station_id
    FROM station_coverage
    WHERE coverage_percentage >= 99
)

SELECT
    b.month,
    MONTHNAME(b.timestamp) AS month_name,

    ROUND(AVG(b.bicycle_count), 2)
        AS avg_bicycles_per_station_hour,

    COUNT(DISTINCT b.station_id)
        AS selected_stations,

    ROUND(
        COUNT(b.bicycle_count) * 100.0 / COUNT(*),
        2
    ) AS monthly_coverage_percentage

FROM bicycle_counts AS b
JOIN reliable_stations AS r
    ON b.station_id = r.station_id

GROUP BY
    b.month,
    MONTHNAME(b.timestamp)

ORDER BY b.month;

-- FINDINGS:
-- 32 of 35 stations met the minimum 99% annual
-- data coverage threshold.
--
-- June remained the busiest month, averaging
-- 122.29 bicycle passages per valid station-hour.
--
-- December remained the quietest month, averaging
-- 61.02 bicycle passages per valid station-hour.
--
-- Filtering low-coverage stations preserved the
-- overall seasonal pattern.
--
-- September's average increased from 114.12 to 119.03,
-- demonstrating the impact of station selection.
--
-- The high-coverage subset is suitable for more
-- consistent monthly comparisons.


-- Query 7: Month-over-Month Bicycle Traffic Changes
-- Objective: Calculate monthly percentage changes
-- using a SQL window function.

WITH station_coverage AS (
    SELECT
        station_id,
        COUNT(bicycle_count) * 100.0 / COUNT(*)
            AS coverage_percentage
    FROM bicycle_counts
    GROUP BY station_id
),

reliable_stations AS (
    SELECT station_id
    FROM station_coverage
    WHERE coverage_percentage >= 99
),

monthly_traffic AS (
    SELECT
        b.month,
        MONTHNAME(b.timestamp) AS month_name,
        AVG(b.bicycle_count) AS avg_traffic
    FROM bicycle_counts AS b
    JOIN reliable_stations AS r
        ON b.station_id = r.station_id
    GROUP BY b.month, MONTHNAME(b.timestamp)
),

monthly_comparison AS (
    SELECT
        month,
        month_name,
        avg_traffic,
        LAG(avg_traffic) OVER (
            ORDER BY month
        ) AS previous_month_avg
    FROM monthly_traffic
)

SELECT
    month,
    month_name,

    ROUND(avg_traffic, 2) AS current_month_avg,

    ROUND(previous_month_avg, 2) AS previous_month_avg,

    ROUND(
        (avg_traffic - previous_month_avg)
        / NULLIF(previous_month_avg, 0) * 100,
        2
    ) AS monthly_change_percentage

FROM monthly_comparison

ORDER BY month;

-- FINDINGS:
-- The largest month-over-month increase occurred
-- between February and March: +54.13%.
--
-- June had the highest average bicycle traffic,
-- with 122.29 passages per valid station-hour.
--
-- The largest monthly decline occurred between
-- September and October: -25.88%.
--
-- December declined by 25.12% compared with November.
--
-- The analysis uses 32 stations with at least
-- 99% annual reporting coverage.
--
-- Monthly changes may reflect seasonality, weather,
-- and other factors not yet included in our dataset.




