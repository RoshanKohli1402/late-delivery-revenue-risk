/*
==========================================================
Query 2: Customer Review Score Distribution

Business Question:
What is the overall quality of customer reviews?

Metrics:
- Average Review Score
- Median Review Score
- Percentage of 1-Star Reviews
- Percentage of 5-Star Reviews
==========================================================
*/

WITH ranked AS (
    SELECT
        review_score,
        ROW_NUMBER() OVER (ORDER BY review_score) AS rn,
        COUNT(*) OVER () AS total_rows
    FROM order_reviews
)

SELECT
     AVG(review_score) AS avg_score,

    (SELECT AVG(review_score)
     FROM ranked
     WHERE rn IN (
         FLOOR((total_rows + 1) / 2),
         FLOOR((total_rows + 2) / 2)
     )) AS median_score,

    avg(if(review_score = 1 , 1 , 0)) * 100 as '1-star percentage',
    avg(if(review_score = 5 , 1 , 0)) * 100 as '5-star percentage' 
    from order_reviews;
