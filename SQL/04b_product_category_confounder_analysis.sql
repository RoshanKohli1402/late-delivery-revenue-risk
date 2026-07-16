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

-- Category-level confounder check: same fix applied
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
      AND order_delivered_customer_date IS NOT NULL
),

customer_retention AS (
    SELECT
        c.customer_unique_id,
        CASE
            WHEN COUNT(o.order_id) > 1 THEN 'Repeat'
            ELSE 'One-Time'
        END AS customer_type
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

category_stats AS (

SELECT
    p.product_category_name,

    ds.delivery_status,

    COUNT(DISTINCT c.customer_unique_id) AS customers,

    COUNT(DISTINCT CASE
            WHEN cr.customer_type='Repeat'
            THEN c.customer_unique_id
        END) AS repeat_customers,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN cr.customer_type='Repeat'
            THEN c.customer_unique_id
        END)*100.0
        /
        COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS repeat_rate

FROM orders o

JOIN customers c
ON o.customer_id=c.customer_id

JOIN customer_retention cr
ON c.customer_unique_id=cr.customer_unique_id

JOIN delivery_status ds
ON o.order_id=ds.order_id

JOIN order_items oi
ON o.order_id=oi.order_id

JOIN products p
ON oi.product_id=p.product_id

GROUP BY
    p.product_category_name,
    ds.delivery_status

HAVING COUNT(DISTINCT c.customer_unique_id) >= 50
)

SELECT

    product_category_name,

    MAX(CASE
            WHEN delivery_status='Late'
            THEN customers
        END) AS late_customers,

    MAX(CASE
            WHEN delivery_status='On Time'
            THEN customers
        END) AS ontime_customers,

    MAX(CASE
            WHEN delivery_status='Late'
            THEN repeat_rate
        END) AS late_repeat_rate,

    MAX(CASE
            WHEN delivery_status='On Time'
            THEN repeat_rate
        END) AS ontime_repeat_rate,

    ROUND(

        MAX(CASE
                WHEN delivery_status='On Time'
                THEN repeat_rate
            END)

        -

        MAX(CASE
                WHEN delivery_status='Late'
                THEN repeat_rate
            END),

        2

    ) AS repeat_rate_gap,

    CASE

        WHEN

            MAX(CASE
                    WHEN delivery_status='Late'
                    THEN repeat_rate
                END)

            <

            MAX(CASE
                    WHEN delivery_status='On Time'
                    THEN repeat_rate
                END)

        THEN 'Supports Hypothesis'

        ELSE 'Opposite Direction'

    END AS result

FROM category_stats

GROUP BY product_category_name

ORDER BY repeat_rate_gap DESC;
