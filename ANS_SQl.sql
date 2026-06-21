-- ============================================================
-- E-commerce Orders Analysis (Brazil) - SQL Queries
-- ============================================================

-- ============================================================
-- SECTION 1: Exploratory Data Analysis
-- ============================================================

-- 1.1 Data type of all columns in the "customers" table
DESCRIBE customers;

-- 1.2 Time range between which the orders were placed
SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 1.3 Count the Cities & States of customers who ordered during the given period
SELECT
    COUNT(DISTINCT c.customer_city) AS total_cities,
    COUNT(DISTINCT c.customer_state) AS total_states
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;


-- ============================================================
-- SECTION 2: In-depth Exploration
-- ============================================================

-- 2.1 Is there a growing trend in the no. of orders placed over the past years?
SELECT
    YEAR(order_purchase_timestamp) AS year,
    COUNT(*) AS total_orders
FROM orders
GROUP BY year
ORDER BY year;

-- 2.2 Monthly seasonality in terms of the no. of orders being placed
SELECT
    MONTH(order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;

-- 2.3 During what time of the day do Brazilian customers mostly place orders?
-- (Dawn: 0-6 hrs, Morning: 7-12 hrs, Afternoon: 13-18 hrs, Night: 19-23 hrs)
SELECT
    CASE
        WHEN HOUR(order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
        WHEN HOUR(order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
        WHEN HOUR(order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
        ELSE 'Night'
    END AS time_of_day,
    COUNT(*) AS total_orders
FROM orders
GROUP BY time_of_day;


-- ============================================================
-- SECTION 3: Evolution of E-commerce Orders in the Brazil Region
-- ============================================================

-- 3.1 Month on month no. of orders placed in each state
SELECT
    c.customer_state,
    YEAR(o.order_purchase_timestamp) AS year,
    MONTH(o.order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state, year, month
ORDER BY c.customer_state, year, month;

-- 3.2 How are the customers distributed across all the states?
SELECT
    customer_state,
    COUNT(*) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;


-- ============================================================
-- SECTION 4: Impact on Economy (Order Prices, Freight & Others)
-- ============================================================

-- 4.1 % increase in the cost of orders from 2017 to 2018 (Jan-Aug only)
 
SELECT
    ((MAX(total_sales) - MIN(total_sales)) / MIN(total_sales)) * 100 AS percentage_increase
FROM (
    SELECT
        YEAR(o.order_purchase_timestamp) AS year,
        SUM(p.payment_value) AS total_sales
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    WHERE MONTH(o.order_purchase_timestamp) BETWEEN 1 AND 8
        AND YEAR(o.order_purchase_timestamp) IN (2017, 2018)
    GROUP BY year
) AS yearly;

-- 4.2 Total & Average value of order price for each state
SELECT
    c.customer_state,
    SUM(oi.price) AS total_price,
    AVG(oi.price) AS avg_price
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state;

-- 4.3 Total & Average value of order freight for each state
SELECT
    c.customer_state,
    SUM(oi.freight_value) AS total_freight,
    AVG(oi.freight_value) AS avg_freight
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state;


-- ============================================================
-- SECTION 5: Analysis Based on Sales, Freight & Delivery Time
-- ============================================================

-- 5.1 No. of days taken to deliver each order (from purchase date),
-- and the difference (in days) between estimated & actual delivery date
-- time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
-- diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date
SELECT
    order_id,
    DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS delivery_days,
    DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) AS estimated_diff_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- 5.2 Top 5 states with the highest average freight value
SELECT
    c.customer_state,
    AVG(oi.freight_value) AS avg_freight
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight DESC
LIMIT 5;

-- 5.2 Top 5 states with the lowest average freight value
SELECT
    c.customer_state,
    AVG(oi.freight_value) AS avg_freight
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight ASC
LIMIT 5;

-- 5.3 Top 5 states with the highest average delivery time
SELECT
    c.customer_state,
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC
LIMIT 5;

-- 5.3 Top 5 states with the lowest average delivery time
SELECT
    c.customer_state,
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)) AS avg_delivery_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days ASC
LIMIT 5;

-- 5.4 Top 5 states where order delivery is fastest compared to the estimated delivery date
-- (using the difference between averages of estimated & actual delivery date)
SELECT
    c.customer_state,
    AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS faster_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY faster_days DESC
LIMIT 5;


-- ============================================================
-- SECTION 6: Analysis Based on Payments
-- ============================================================

-- 6.1 Month on month no. of orders placed using different payment types
SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    MONTH(o.order_purchase_timestamp) AS month,
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY year, month, p.payment_type
ORDER BY year, month;

-- 6.2 No. of orders placed based on the number of payment installments paid
SELECT
    payment_installments,
    COUNT(DISTINCT order_id) AS total_orders
FROM payments
GROUP BY payment_installments
ORDER BY payment_installments;
