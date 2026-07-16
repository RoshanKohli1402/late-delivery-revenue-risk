/*
==========================================================
Query 3: Customer Retention Analysis

Business Question:
Does experiencing a late delivery influence customer
retention and repeat purchasing?

Metrics:
- Total Customers
- Repeat Customers
- Repeat Rate
- Average Orders
- Ever Experienced Late Delivery
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
		AND order_delivered_customer_date IS NOT NULL
),

retention_check AS (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS total_orders,
        CASE
            WHEN COUNT(o.order_id) > 1 THEN 'Repeat'
            ELSE 'One-Time' END AS customer_type,
        SUM(CASE 
				WHEN ds.delivery_status = 'Late' THEN 1
                ELSE 0
            END
        ) AS late_orders,
        SUM(  CASE
                WHEN ds.delivery_status = 'On Time' THEN 1
                ELSE 0
            END
        ) AS on_time_orders,
        CASE
            WHEN MAX(CASE
                        WHEN ds.delivery_status = 'Late' THEN 1
                        ELSE 0
                    END
                 ) = 1
            THEN 'Yes'
            ELSE 'No'
        END AS ever_late
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN delivery_status ds ON o.order_id = ds.order_id
	GROUP BY c.customer_unique_id
),

retention_analysis as (SELECT
    ever_late,
    COUNT(*) AS total_customers,
    ROUND(AVG(total_orders),2) AS avg_orders,
    SUM(CASE
            WHEN customer_type = 'Repeat' THEN 1
            ELSE 0
        END
    ) AS repeat_customers,
    ROUND(SUM(CASE
                WHEN customer_type = 'Repeat' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),2) AS repeat_rate
    #ROUND(AVG(late_orders),2) AS avg_late_orders,
    #ROUND(AVG(on_time_orders),2) AS avg_on_time_orders
FROM retention_check
GROUP BY ever_late
)

SELECT * FROM retention_analysis;
