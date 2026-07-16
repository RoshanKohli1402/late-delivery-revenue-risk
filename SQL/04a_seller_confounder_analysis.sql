/*
==========================================================
Query 4A: Seller-Level Confounder Analysis

Business Question:
Is the relationship between late deliveries and repeat
purchases consistent across different sellers, or is it
driven by specific seller performance?

Tables Used:
- orders
- order_items
- customers
- order_reviews

Metrics:
- Seller ID
- Total Orders
- Late Delivery Percentage
- Repeat Purchase Percentage
- Average Review Score

Purpose:
Identify whether sellers with higher late delivery rates
also tend to have lower customer repeat purchase rates.
==========================================================
*/

WITH delivery_status AS (
    SELECT
        order_id,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On Time'
        END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered'
),

retention_check AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders,
        CASE
            WHEN COUNT(o.order_id) > 1 THEN 'Repeat'
            ELSE 'One-Time'
        END AS customer_type
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    oi.seller_id,

    COUNT(DISTINCT o.order_id) AS total_orders,

    ROUND(
        AVG(ds.delivery_status = 'Late') * 100,
        2
    ) AS late_percentage,

    ROUND(
        AVG(rc.customer_type = 'Repeat') * 100,
        2
    ) AS repeat_percentage,

    ROUND(
        AVG(r.review_score),
        2
    ) AS avg_review_score

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN retention_check rc
    ON c.customer_unique_id = rc.customer_unique_id

JOIN delivery_status ds
    ON o.order_id = ds.order_id

LEFT JOIN order_reviews r
    ON o.order_id = r.order_id

GROUP BY oi.seller_id

HAVING COUNT(DISTINCT o.order_id) >= 30

ORDER BY late_percentage DESC;
