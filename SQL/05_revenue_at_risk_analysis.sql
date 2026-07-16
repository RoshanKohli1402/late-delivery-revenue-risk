/*
==========================================================
Query 5: Revenue at Risk Analysis

Business Question:
How much future revenue could Olist be losing because
customers who experienced late deliveries are less likely
to make repeat purchases?

Tables Used:
- orders
- customers
- order_payments

Metrics:
- Late Customers
- Repeat Rate (Late vs On-Time)
- Repeat Rate Difference
- Average Order Value
- Estimated Revenue at Risk

Purpose:
Estimate the potential future revenue loss associated with
late deliveries by combining customer retention behavior
with average order value.
==========================================================
*/
WITH delivery_status AS (
    SELECT
        order_id,
        customer_id,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On Time'
        END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered'
),

customer_retention AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders,
        CASE
            WHEN COUNT(o.order_id) > 1 THEN 'Repeat'
            ELSE 'One-Time'
        END AS customer_type,
        CASE
            WHEN MAX(ds.delivery_status = 'Late') = 1
            THEN 'Late Customer'
            ELSE 'On-Time Customer'
        END AS customer_group
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN delivery_status ds
        ON o.order_id = ds.order_id
    GROUP BY c.customer_unique_id
),

repeat_rates AS (
    SELECT
        customer_group,
        COUNT(*) AS customers,
        SUM(customer_type='Repeat') AS repeat_customers,
        SUM(customer_type='Repeat') / COUNT(*) AS repeat_rate
    FROM customer_retention
    GROUP BY customer_group
),

avg_order_value AS (
    SELECT
        AVG(payment_value) AS avg_order_value
    FROM order_payments
)
SELECT MAX(CASE
            WHEN customer_group='Late Customer'
            THEN customers
        END) AS late_customers,

    ROUND(MAX(CASE
                WHEN customer_group='On-Time Customer'
                THEN repeat_rate
            END) - MAX(CASE
                WHEN customer_group='Late Customer'
                THEN repeat_rate
            END),4) AS repeat_rate_difference,
	ROUND(avg_order_value,2) AS average_order_value,
    ROUND(MAX(CASE
                WHEN customer_group='Late Customer'
                THEN customers
            END) * (
        MAX(CASE
                WHEN customer_group='On-Time Customer'
                THEN repeat_rate
            END) -  MAX(CASE
                WHEN customer_group='Late Customer'
                THEN repeat_rate
            END)
        ) * avg_order_value, 2
    ) AS estimated_revenue_at_risk

FROM repeat_rates
CROSS JOIN avg_order_value;
