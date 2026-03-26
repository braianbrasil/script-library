-- Monthly Revenue Report
-- Compares current month vs same month last year

WITH monthly_sales AS (
  SELECT
    DATE_TRUNC('month', created_at) AS month,
    category,
    SUM(amount)                     AS revenue
  FROM orders
  WHERE status = 'completed'
  GROUP BY 1, 2
)
SELECT
  month,
  category,
  revenue,
  LAG(revenue, 12) OVER (
    PARTITION BY category ORDER BY month
  ) AS revenue_prev_year,
  ROUND(
    (revenue - LAG(revenue, 12) OVER (PARTITION BY category ORDER BY month))
    / NULLIF(LAG(revenue, 12) OVER (PARTITION BY category ORDER BY month), 0) * 100, 2
  ) AS yoy_growth_pct
FROM monthly_sales
ORDER BY month DESC, revenue DESC;
