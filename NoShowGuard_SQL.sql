USE noshowguard;

-- Task 2.2: No-show rate by clinic
SELECT
    c.clinic_name,
    c.city,
    COUNT(*) AS appointments,
    SUM(a.no_show) AS no_shows,
    ROUND(100.0 * SUM(a.no_show) / COUNT(*), 1) AS no_show_pct

FROM appointments AS a

JOIN clinics AS c
    ON a.clinic_id = c.clinic_id

GROUP BY
    c.clinic_id,
    c.clinic_name,
    c.city

ORDER BY no_show_pct DESC;


-- Task 2.3: No-show rate by lead-time group

SELECT
    CASE
        WHEN lead_days BETWEEN 1 AND 7 THEN '1-7'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14'
        WHEN lead_days BETWEEN 15 AND 30 THEN '15-30'
        WHEN lead_days >= 31 THEN '31+'
    END AS lead_group,

    COUNT(*) AS appointments,
    SUM(no_show) AS no_shows,

    ROUND(
        100.0 * SUM(no_show) / COUNT(*), 1
    ) AS no_show_pct

FROM appointments

GROUP BY lead_group

ORDER BY
    CASE lead_group
        WHEN '1-7' THEN 1
        WHEN '8-14' THEN 2
        WHEN '15-30' THEN 3
        WHEN '31+' THEN 4
    END;



-- Task 2.4: Monthly No-show trend
WITH monthly_stats AS (
    SELECT
        DATE_FORMAT(appt_date, '%Y-%m') AS month,
        COUNT(*) AS appointments,
        ROUND(
            100.0 * SUM(no_show) / COUNT(*), 1
        ) AS no_show_rate
    FROM appointments
    GROUP BY DATE_FORMAT(appt_date, '%Y-%m')
),

monthly_trends AS (
    SELECT
        month,
        appointments,
        no_show_rate,
        LAG(no_show_rate) OVER (ORDER BY month) AS previous_rate
    FROM monthly_stats
)

SELECT
    month,
    appointments,
    no_show_rate,
    ROUND(no_show_rate - previous_rate, 1) AS monthly_change
FROM monthly_trends
ORDER BY month;


-- Task 2.5: Clinic comparison with overall rate
WITH overall_rate AS (
    SELECT
        100.0 * SUM(no_show) / COUNT(*) AS overall_pct
    FROM appointments
),

clinic_stats AS (
    SELECT
        c.city,
        c.clinic_name,
        COUNT(*) AS appointments,
        SUM(a.no_show) AS no_shows,
        ROUND(
            100.0 * SUM(a.no_show) / COUNT(*), 1
        ) AS no_show_pct
    FROM appointments AS a
    JOIN clinics AS c
        ON a.clinic_id = c.clinic_id
    GROUP BY
        c.city,
        c.clinic_id,
        c.clinic_name
),

ranked_clinics AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY city
            ORDER BY no_show_pct DESC
        ) AS city_rank
    FROM clinic_stats
)

SELECT
    r.city,
    r.clinic_name,
    r.no_show_pct,
    r.city_rank,
    CASE
        WHEN r.no_show_pct > o.overall_pct THEN 'above'
        ELSE 'below'
    END AS comparison
FROM ranked_clinics AS r
CROSS JOIN overall_rate AS o
ORDER BY
    r.city,
    r.city_rank;