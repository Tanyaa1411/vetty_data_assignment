/*=== SQL Test — Solutions===*/


/* ===================================================================
   1) Count of purchases per month (excluding refunded purchases)
      → Treat only non-refunded rows as actual purchases.
   =================================================================== */

SELECT 
    DATE_TRUNC('month', purchase_time) AS month,
    COUNT(*) AS total_purchases
FROM transactions
WHERE refund_time IS NULL       -- refunded orders excluded
GROUP BY 1
ORDER BY 1;



/* ===================================================================
   2 Stores with at least 5 orders in October 2020
      → Simple filter + group + having.
      Note: In the provided dataset, October 2020 has no records,
            so this will naturally return 0.
   =================================================================== */

SELECT COUNT(*) AS stores_with_5_orders
FROM (
    SELECT store_id, COUNT(*) AS order_count
    FROM transactions
    WHERE purchase_time >= '2020-10-01'
      AND purchase_time <  '2020-11-01'
    GROUP BY store_id
    HAVING COUNT(*) >= 5
) t;



/* ===================================================================
   3) For each store, shortest refund interval (in minutes)
      → Only look at the refunded rows.
      → Compute (refund_time - purchase_time) and convert to minutes.
   =================================================================== */

SELECT
    store_id,
    MIN(EXTRACT(EPOCH FROM (refund_time - purchase_time)) / 60)
        AS shortest_refund_time_min
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id;



/* ===================================================================
   4) Gross transaction value of each store’s FIRST order
      → Use ROW_NUMBER to pick the earliest order per store.
   =================================================================== */

SELECT store_id, gross_transaction_value
FROM (
    SELECT
        t.*,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions t
) x
WHERE rn = 1;



/* ===================================================================
   5) Most popular item from buyers' FIRST purchase
      Steps:
      - Identify each buyer's first-ever purchase.
      - Join with items to get item_name.
      - Count which item shows up most in first purchases.
   =================================================================== */

WITH first_purchase AS (
    SELECT *
    FROM (
        SELECT
            t.*,
            ROW_NUMBER() OVER (
                PARTITION BY buyer_id
                ORDER BY purchase_time
            ) AS rn
        FROM transactions t
    ) a
    WHERE rn = 1   -- first purchase per buyer
)
SELECT
    i.item_name,
    COUNT(*) AS times_ordered
FROM first_purchase fp
JOIN items i ON fp.item_id = i.item_id
GROUP BY i.item_name
ORDER BY times_ordered DESC
LIMIT 1;          -- most popular item



/* ===================================================================
   6) Refund flag: whether refund is allowed (within 72 hours)
      → Convert time difference to hours and compare with 72.
      → Expected: only 1 of the refunds qualifies.
   =================================================================== */

SELECT
    *,
    CASE
        WHEN refund_time IS NULL THEN 'No Refund'
        WHEN EXTRACT(EPOCH FROM (refund_time - purchase_time)) / 3600 <= 72
             THEN 'Refund Processed'
        ELSE 'Refund Too Late'
    END AS refund_flag
FROM transactions;



/* ===================================================================
   7) Second purchase per buyer (ignoring refunds)
      → Keep only non-refunded orders.
      → Rank purchases per buyer.
      → Return rn = 2.
      Expected: Only buyer_id = 3 has a valid second purchase.
   =================================================================== */

WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
    WHERE refund_time IS NULL
)
SELECT *
FROM ranked
WHERE rn = 2;



/* ===================================================================
   8) Find the second transaction time per buyer
      Condition: do NOT use MIN or MAX.
      → Use ROW_NUMBER again.
   =================================================================== */

SELECT buyer_id, purchase_time
FROM (
    SELECT
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
) t
WHERE rn = 2;     -- second transaction --
