-- ============================================================================
-- VETTY SQL ASSIGNMENT
-- ============================================================================
-- This file contains SQL queries to answer 8 questions based on 
-- transactions and items tables.
--
-- Assumptions:
-- 1. A refunded purchase is identified by having a non-null refund_item value
-- 2. Purchase_time and refund_item are timestamp columns
-- 3. All monetary values are stored as numeric/decimal (not strings with $)
-- 4. For question 3, if a store has no refunds, it will be excluded from results
-- 5. For question 4, "first order" means the earliest purchase_time per store
-- 6. For question 5, "first purchase" means the earliest purchase_time per buyer
-- 7. For question 6, 72 hours = 72 * 60 = 4320 minutes
-- 8. For question 7 & 8, we ignore transactions that have refunds (refund_item IS NOT NULL)
-- ============================================================================

-- ============================================================================
-- QUESTION 1: Count of purchases per month (excluding refunded purchases)
-- ============================================================================
-- Approach: 
-- - Filter out refunded purchases (WHERE refund_item IS NULL)
-- - Extract year and month from purchase_time
-- - Group by year and month
-- - Count the transactions
-- ============================================================================

SELECT 
    EXTRACT(YEAR FROM purchase_time) AS year,
    EXTRACT(MONTH FROM purchase_time) AS month,
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_item IS NULL  -- Excluding refunded purchases
GROUP BY EXTRACT(YEAR FROM purchase_time), EXTRACT(MONTH FROM purchase_time)
ORDER BY year, month;


-- ============================================================================
-- QUESTION 2: How many stores receive at least 5 orders/transactions in October 2020?
-- ============================================================================
-- Approach:
-- - Filter transactions for October 2020
-- - Group by store_id
-- - Count transactions per store
-- - Filter stores with count >= 5
-- - Count the number of such stores
-- ============================================================================

SELECT COUNT(DISTINCT store_id) AS store_count
FROM (
    SELECT 
        store_id,
        COUNT(*) AS transaction_count
    FROM transactions
    WHERE EXTRACT(YEAR FROM purchase_time) = 2020
      AND EXTRACT(MONTH FROM purchase_time) = 10
    GROUP BY store_id
    HAVING COUNT(*) >= 5
) AS stores_with_5_plus_orders;


-- ============================================================================
-- QUESTION 3: For each store, what is the shortest interval (in min) from purchase to refund time?
-- ============================================================================
-- Approach:
-- - Filter only transactions that have refunds (refund_item IS NOT NULL)
-- - Calculate the difference between refund_item and purchase_time in minutes
-- - Group by store_id
-- - Find the minimum interval per store
-- ============================================================================

SELECT 
    store_id,
    MIN(EXTRACT(EPOCH FROM (refund_item - purchase_time)) / 60) AS shortest_refund_interval_minutes
FROM transactions
WHERE refund_item IS NOT NULL  -- Only consider transactions with refunds
GROUP BY store_id
ORDER BY store_id;


-- ============================================================================
-- QUESTION 4: What is the gross_transaction_value of every store's first order?
-- ============================================================================
-- Approach:
-- - Use window function to rank orders by purchase_time per store
-- - Filter for rank = 1 (first order)
-- - Select store_id and gross_transaction_value
-- ============================================================================

SELECT 
    store_id,
    gross_transaction_value
FROM (
    SELECT 
        store_id,
        gross_transaction_value,
        purchase_time,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time ASC) AS order_rank
    FROM transactions
) AS ranked_orders
WHERE order_rank = 1
ORDER BY store_id;


-- ============================================================================
-- QUESTION 5: What is the most popular item name that buyers order on their first purchase?
-- ============================================================================
-- Approach:
-- - Join transactions with items table to get item_name
-- - Use window function to identify first purchase per buyer
-- - Filter for first purchases only
-- - Count occurrences of each item_name
-- - Order by count descending and limit to 1
-- ============================================================================

SELECT 
    i.item_name,
    COUNT(*) AS first_purchase_count
FROM (
    SELECT 
        buyer_id,
        item_id,
        store_id,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS purchase_rank
    FROM transactions
) AS first_purchases
JOIN items i ON first_purchases.store_id = i.store_id 
             AND first_purchases.item_id = i.item_id
WHERE first_purchases.purchase_rank = 1
GROUP BY i.item_name
ORDER BY first_purchase_count DESC
LIMIT 1;


-- ============================================================================
-- QUESTION 6: Create a flag in the transaction items table indicating whether 
--             the refund can be processed or not. The condition for a refund 
--             to be processed is that it has to happen within 72 hours of Purchase time.
-- ============================================================================
-- Approach:
-- - Calculate the time difference between refund_item and purchase_time
-- - Convert to hours (or minutes and check if <= 72*60)
-- - Create a flag column (1 if refundable, 0 or NULL if not)
-- - Expected: Only 1 of the three refunds would be processed
-- ============================================================================

SELECT 
    buyer_id,
    purchase_time,
    refund_item,
    store_id,
    item_id,
    gross_transaction_value,
    CASE 
        WHEN refund_item IS NOT NULL 
             AND EXTRACT(EPOCH FROM (refund_item - purchase_time)) / 3600 <= 72 
        THEN 1  -- Refund can be processed
        WHEN refund_item IS NOT NULL 
             AND EXTRACT(EPOCH FROM (refund_item - purchase_time)) / 3600 > 72 
        THEN 0  -- Refund cannot be processed (beyond 72 hours)
        ELSE NULL  -- No refund requested
    END AS refund_processable_flag
FROM transactions
ORDER BY buyer_id, purchase_time;


-- ============================================================================
-- QUESTION 7: Create a rank by buyer_id column in the transaction items table 
--             and filter for only the second purchase per buyer. (Ignore refunds here)
-- ============================================================================
-- Approach:
-- - Filter out refunded purchases (refund_item IS NULL)
-- - Use ROW_NUMBER() window function to rank purchases by buyer_id
-- - Order by purchase_time to determine purchase sequence
-- - Filter for rank = 2 (second purchase)
-- - Expected: Only the second purchase of buyer_id 3 should be the output
-- ============================================================================

SELECT 
    buyer_id,
    purchase_time,
    refund_item,
    store_id,
    item_id,
    gross_transaction_value,
    purchase_rank
FROM (
    SELECT 
        buyer_id,
        purchase_time,
        refund_item,
        store_id,
        item_id,
        gross_transaction_value,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS purchase_rank
    FROM transactions
    WHERE refund_item IS NULL  -- Ignoring refunds
) AS ranked_purchases
WHERE purchase_rank = 2;


-- ============================================================================
-- QUESTION 8: How will you find the second transaction time per buyer 
--             (don't use min/max; assume there were more transactions per buyer in the table)
-- ============================================================================
-- Approach:
-- - Use window function ROW_NUMBER() or RANK() to order transactions per buyer
-- - Filter for rank = 2 to get second transaction
-- - Select buyer_id and purchase_time (timestamp)
-- - Expected: Only the second purchase of buyer_id along with a timestamp
-- ============================================================================

SELECT 
    buyer_id,
    purchase_time AS second_transaction_time
FROM (
    SELECT 
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS transaction_rank
    FROM transactions
) AS ranked_transactions
WHERE transaction_rank = 2
ORDER BY buyer_id;

