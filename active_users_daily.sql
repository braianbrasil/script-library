-- Daily Active Users (DAU) with 7-day rolling average

SELECT
  activity_date,
  COUNT(DISTINCT user_id)   AS dau,
  ROUND(AVG(COUNT(DISTINCT user_id)) OVER (
    ORDER BY activity_date
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 0)                     AS rolling_7d_avg
FROM user_events
WHERE activity_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY activity_date
ORDER BY activity_date DESC;
