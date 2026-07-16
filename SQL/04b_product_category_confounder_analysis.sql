/*
==========================================================
Query 4B: Product Category Confounder Analysis

Business Question:
Is the relationship between late deliveries and repeat
purchases consistent across different product categories,
or is it influenced by the type of products being sold?

Tables Used:
- orders
- order_items
- products
- customers

Metrics:
- Product Category
- Total Orders
- Late Delivery Percentage
- Repeat Purchase Percentage
- Revenue

Purpose:
Evaluate whether delivery delays and customer retention
vary significantly across product categories.
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
    p.product_category_name,

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
        SUM(oi.price),
        2
    ) AS revenue

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products p
    ON oi.product_id = p.product_id

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN retention_check rc
    ON c.customer_unique_id = rc.customer_unique_id

JOIN delivery_status ds
    ON o.order_id = ds.order_id

GROUP BY p.product_category_name

HAVING COUNT(DISTINCT o.order_id) >= 30

ORDER BY late_percentage DESC;
