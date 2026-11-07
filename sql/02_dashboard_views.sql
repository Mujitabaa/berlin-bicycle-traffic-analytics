USE berlin_bicycle_analytics;

-- View 1: Dashboard-ready bicycle traffic data

CREATE OR REPLACE VIEW vw_bicycle_traffic AS

SELECT
    b.timestamp,
    b.station_id,
    s.station_name,
    s.latitude,
    s.longitude,
    b.bicycle_count,
    b.year,
    b.month,
    b.day,
    b.hour,
    b.day_of_week,
    b.weekday_number,
    b.is_weekend,
    b.season

FROM bicycle_counts AS b

JOIN stations AS s
    ON b.station_id = s.station_id;


SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT station_id) AS unique_stations,
    SUM(bicycle_count IS NULL) AS missing_counts
FROM vw_bicycle_traffic;