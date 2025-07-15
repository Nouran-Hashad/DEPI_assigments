--1.Write a query that classifies all products into price categories.
SELECT 
	P.product_id, 
	P.product_name,
	CASE 
		WHEN P.list_price<300 THEN 'Economy'
		WHEN P.list_price BETWEEN 300 AND 999 THEN 'Standard'
		WHEN P.list_price BETWEEN 1000 AND 2499 THEN 'Premium'
		WHEN P.list_price >= 2500 THEN 'Luxury'
	END AS price_categoriy
FROM production.products P;

--2.Create a query that shows order processing information with user-friendly status descriptions.
SELECT
	order_id, 
	CASE
		WHEN order_status = 1 THEN 'Order Received'
		WHEN order_status = 2 THEN 'In Preparation'
		WHEN order_status = 3 THEN 'Order Cancelled'
		WHEN order_status = 4 THEN 'Order Delivered'
		END AS status,
		CASE 
		WHEN DATEDIFF(DAY,GETDATE(),order_date)>5 AND order_status = 1 THEN 'URGENT'
		WHEN DATEDIFF(DAY,GETDATE(),order_date)>3 AND order_status = 2 THEN 'HIGH'
		ELSE 'NORMAL'
	END AS 'priority level'
FROM sales.orders;

--3.Write a query that categorizes staff based on the number of orders they've handled.
SELECT 
	S.first_name+' '+S.last_name AS stuff_name,
	CASE 
		WHEN COUNT(O.order_id) = 0 THEN 'New Staff'
		WHEN COUNT(O.order_id) BETWEEN 1 AND 10 THEN 'Junior Staff'
		WHEN COUNT(O.order_id) BETWEEN 11 AND 25 THEN 'Senior Staff'
		WHEN COUNT(O.order_id) >=26 THEN 'Expert Staff'
	END AS 'Level'
FROM sales.staffs S
LEFT JOIN sales.orders O ON S.staff_id = O.staff_id
GROUP BY S.first_name+' '+S.last_name;

--4.Create a query that handles missing customer contact information.
SELECT 
	first_name+' '+last_name AS Full_name,
	ISNULL(phone, 'Phone Not Available') AS phone,
	COALESCE(phone, email, 'No Contant Method') AS 'Contact',
	street+' -'+city +' -'+ state AS address,
	zip_code
FROM sales.customers;

--5.Write a query that safely calculates price per unit in stock.
SELECT 
	P.product_name,
	ISNULL(S.quantity, 0) AS 'stock_quantity',
	P.list_price/NULLIF(S.quantity, 0) AS 'unit price'
FROM production.stocks S
RIGHT JOIN production.products P ON S.product_id = P.product_id AND store_id= 1;

--6.Create a query that formats complete addresses safely.
SELECT 
	COALESCE(street, 'NO address info') AS Street,
	COALESCE(city, 'No City Info') AS city,
	COALESCE(state, 'No state info') AS state,
	COALESCE(zip_code, 'No zip_code info') AS zip_code,
	street+' -'+city +' -'+ state AS address,
	ISNULL(zip_code, 'No info') AS zip_code
FROM sales.customers;

--7.Use a CTE to find customers who have spent more than $1,500 total.
WITH customer_spent AS(
SELECT 
	C.customer_id,
	C.first_name+' '+C.last_name AS customer_name,
	SUM(I.list_price) AS spent
FROM sales.customers C
JOIN sales.orders O ON C.customer_id = O.customer_id
JOIN sales.order_items I ON O.order_id = I.order_id
GROUP BY C.first_name+' '+C.last_name, C.customer_id
)
SELECT 
	SP.customer_name,
	C.phone,
	C.street+' -'+C.city+' -'+state AS Address,
	SP.spent
FROM customer_spent SP
JOIN sales.customers C ON SP.customer_id = C.customer_id
ORDER BY SP.spent DESC;

--8.Create a multi-CTE query for category analysis.
WITH TotalRevenuePerCategory AS (
    SELECT 
        C.category_id,
        C.category_name,
        SUM(P.list_price * OD.quantity) AS total_revenue
    FROM production.products P
    JOIN production.categories C ON P.category_id = C.category_id
    JOIN sales.order_items OD ON P.product_id = OD.product_id
    GROUP BY C.category_id, C.category_name
),
AverageOrderValuePerCategory AS (
    SELECT 
        C.category_id,
        AVG(OD.quantity * P.list_price) AS avg_order_value
    FROM production.products P
    JOIN production.categories C ON P.category_id = C.category_id
    JOIN sales.order_items OD ON P.product_id = OD.product_id
    GROUP BY C.category_id
)

SELECT 
    T.category_name,
    T.total_revenue,
    A.avg_order_value,
    CASE 
        WHEN T.total_revenue > 50000 THEN 'Excellent'
        WHEN T.total_revenue > 20000 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS performance_rating
FROM TotalRevenuePerCategory T
JOIN AverageOrderValuePerCategory A 
  ON T.category_id = A.category_id;

--9.Use CTEs to analyze monthly sales trends
WITH MonthlySales AS (
    SELECT 
        FORMAT(order_date, 'yyyy-MM') AS order_month,
        SUM(oi.quantity * p.list_price) AS total_sales
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON p.product_id = oi.product_id
    GROUP BY FORMAT(order_date, 'yyyy-MM')
),
WithPreviousMonth AS (
    SELECT 
        order_month,
        total_sales,
        LAG(total_sales) OVER (ORDER BY order_month) AS previous_sales
    FROM MonthlySales
)

SELECT 
    order_month,
    total_sales,
    previous_sales,
    ROUND(
        CASE 
            WHEN previous_sales IS NULL THEN NULL
            WHEN previous_sales = 0 THEN NULL
            ELSE ((total_sales - previous_sales) * 1.0 / previous_sales) * 100
        END, 2
    ) AS growth_percentage
FROM WithPreviousMonth;

--10.Create a query that ranks products within each category
WITH ProductRanks AS (
    SELECT 
        C.category_name,
        P.product_name,
        P.list_price,
        ROW_NUMBER() OVER (PARTITION BY C.category_id ORDER BY P.list_price DESC) AS row_num,
        RANK() OVER (PARTITION BY C.category_id ORDER BY P.list_price DESC) AS price_rank,
        DENSE_RANK() OVER (PARTITION BY C.category_id ORDER BY P.list_price DESC) AS dense_rank
    FROM production.products P
    JOIN production.categories C ON P.category_id = C.category_id
)

SELECT * 
FROM ProductRanks
WHERE row_num <= 3;

--11.Rank customers by their total spending.
WITH CustomerSpending AS (
    SELECT 
        C.customer_id,
        C.first_name + ' ' + C.last_name AS customer_name,
        SUM(oi.quantity * p.list_price) AS total_spending
    FROM sales.customers C
    JOIN sales.orders o ON C.customer_id = o.customer_id
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON oi.product_id = p.product_id
    GROUP BY C.customer_id, C.first_name, C.last_name
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spending DESC) AS spending_rank,
        NTILE(5) OVER (ORDER BY total_spending DESC) AS spending_group
    FROM CustomerSpending
)

SELECT 
    customer_name,
    total_spending,
    spending_rank,
    spending_group,
    CASE spending_group
        WHEN 1 THEN 'VIP'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        WHEN 4 THEN 'Bronze'
        ELSE 'Standard'
    END AS spending_tier
FROM RankedCustomers;

--12.Create a comprehensive store performance ranking
WITH StorePerformance AS (
    SELECT 
        s.store_id,
        s.store_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * p.list_price) AS total_revenue
    FROM sales.stores s
    LEFT JOIN sales.orders o ON s.store_id = o.store_id
    LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
    LEFT JOIN production.products p ON oi.product_id = p.product_id
    GROUP BY s.store_id, s.store_name
),
RankedStores AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY total_orders DESC) AS order_rank,
        PERCENT_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_percentile
    FROM StorePerformance
)

SELECT * FROM RankedStores;

--13.Create a PIVOT table showing product counts by category and brand
SELECT *
FROM (
    SELECT 
        c.category_name,
        b.brand_name,
        p.product_id
    FROM production.products p
    JOIN production.categories c ON p.category_id = c.category_id
    JOIN production.brands b ON p.brand_id = b.brand_id
    WHERE b.brand_name IN ('Electra', 'Haro', 'Trek', 'Surly')
) AS SourceTable
PIVOT (
    COUNT(product_id)
    FOR brand_name IN ([Electra], [Haro], [Trek], [Surly])
) AS PivotTable;

--14.Create a PIVOT showing monthly sales revenue by store
SELECT * FROM (
    SELECT 
        s.store_name,
        MONTH(o.order_date) AS order_month,
        oi.quantity * p.list_price AS revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON p.product_id = oi.product_id
    JOIN sales.stores s ON o.store_id = s.store_id
) AS SourceTable
PIVOT (
    SUM(revenue)
    FOR order_month IN (
        [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12]
    )
) AS PivotTable;

--15.PIVOT order statuses across stores
SELECT * FROM (
    SELECT 
        s.store_name,
        o.order_status
    FROM sales.orders o
    JOIN sales.stores s ON o.store_id = s.store_id
) AS SourceTable
PIVOT (
    COUNT(order_status)
    FOR order_status IN ([1], [2], [3], [4])
) AS PivotTable;

--16
SELECT * FROM (
    SELECT 
        b.brand_name,
        YEAR(o.order_date) AS sales_year,
        oi.quantity * p.list_price AS revenue
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    JOIN production.products p ON p.product_id = oi.product_id
    JOIN production.brands b ON p.brand_id = b.brand_id
) AS SourceTable
PIVOT (
    SUM(revenue)
    FOR sales_year IN ([2016], [2017], [2018])
) AS PivotTable;

--17.
-- In-stock products
SELECT p.product_name, 'In Stock' AS status
FROM production.products p
JOIN production.stocks s ON p.product_id = s.product_id
WHERE s.quantity > 0

UNION

-- Out-of-stock products
SELECT p.product_name, 'Out of Stock' AS status
FROM production.products p
JOIN production.stocks s ON p.product_id = s.product_id
WHERE s.quantity = 0 OR s.quantity IS NULL

UNION

-- Discontinued (not in stocks table at all)
SELECT p.product_name, 'Discontinued' AS status
FROM production.products p
WHERE p.product_id NOT IN (SELECT product_id FROM production.stocks);

--18.
-- Customers in 2017
SELECT DISTINCT customer_id
FROM sales.orders
WHERE YEAR(order_date) = 2017

INTERSECT

-- Customers in 2018
SELECT DISTINCT customer_id
FROM sales.orders
WHERE YEAR(order_date) = 2018;

--19.
-- Products in all 3 stores
SELECT product_id FROM production.stocks WHERE store_id = 1
INTERSECT
SELECT product_id FROM production.stocks WHERE store_id = 2
INTERSECT
SELECT product_id FROM production.stocks WHERE store_id = 3

UNION

-- Products in store 1 but not in store 2
SELECT product_id FROM production.stocks WHERE store_id = 1
EXCEPT
SELECT product_id FROM production.stocks WHERE store_id = 2;

--20.
-- Retained Customers
SELECT customer_id, 'Retained' AS status
FROM sales.orders
WHERE YEAR(order_date) = 2016
INTERSECT
SELECT customer_id, 'Retained'
FROM sales.orders
WHERE YEAR(order_date) = 2017

UNION ALL

-- Lost Customers
SELECT customer_id, 'Lost' AS status
FROM sales.orders
WHERE YEAR(order_date) = 2016
EXCEPT
SELECT customer_id FROM sales.orders WHERE YEAR(order_date) = 2017

UNION ALL

-- New Customers
SELECT customer_id, 'New' AS status
FROM sales.orders
WHERE YEAR(order_date) = 2017
EXCEPT
SELECT customer_id FROM sales.orders WHERE YEAR(order_date) = 2016;
