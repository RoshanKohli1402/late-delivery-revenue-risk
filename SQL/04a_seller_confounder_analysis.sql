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

-- Seller-level confounder check: does late/on-time delivery split
-- within each seller change repeat-purchase rate?
WITH delivery_status AS (
    SELECT
        order_id,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On Time'
        END AS delivery_status
    FROM orders
    WHERE order_status='delivered'
      AND order_delivered_customer_date IS NOT NULL
),

customer_retention AS (
    SELECT
        c.customer_unique_id,
        CASE
            WHEN COUNT(o.order_id)>1
            THEN 'Repeat'
            ELSE 'One-Time'
        END AS customer_type
    FROM customers c
    JOIN orders o
        ON c.customer_id=o.customer_id
    WHERE o.order_status='delivered'
    GROUP BY c.customer_unique_id
),

seller_stats AS (

SELECT

    oi.seller_id,

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

GROUP BY
    oi.seller_id,
    ds.delivery_status

HAVING COUNT(DISTINCT c.customer_unique_id)>=50

)

SELECT

    seller_id,

    MAX(CASE WHEN delivery_status='Late' THEN customers END) AS late_customers,

    MAX(CASE WHEN delivery_status='On Time' THEN customers END) AS ontime_customers,

    MAX(CASE WHEN delivery_status='Late' THEN repeat_rate END) AS late_repeat_rate,

    MAX(CASE WHEN delivery_status='On Time' THEN repeat_rate END) AS ontime_repeat_rate,

    ROUND(

        MAX(CASE WHEN delivery_status='On Time' THEN repeat_rate END)

        -

        MAX(CASE WHEN delivery_status='Late' THEN repeat_rate END),

        2

    ) AS repeat_rate_gap,

    CASE

        WHEN

            MAX(CASE WHEN delivery_status='Late' THEN repeat_rate END)

            <

            MAX(CASE WHEN delivery_status='On Time' THEN repeat_rate END)

        THEN 'Supports Hypothesis'

        ELSE 'Opposite Direction'

    END AS result

FROM seller_stats

GROUP BY seller_id

ORDER BY repeat_rate_gap DESC;
