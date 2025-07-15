--1.Count the total number of products in the database.
SELECT 
	COUNT(*) AS Total_products
FROM production.products;

--2. Find the average, minimum, and maximum price of all products.
SELECT 
	MIN(list_price) AS Minimum_price,
	AVG(list_price) AS average_price,
	MAX(list_price) AS Maximum_price
FROM production.products;

--3. Count how many products are in each category.
SELECT 
	c.category_name,
	COUNT(product_id) AS number_of_products
FROM production.products p
JOIN production.categories c ON p.category_id= c.category_id
GROUP BY category_name
ORDER BY number_of_products DESC;

--4. Find the total number of orders for each store.
SELECT  
	S.store_name,
	COUNT(O.order_id) AS Number_of_orders
FROM sales.orders O
JOIN sales.stores S ON O.store_id = S.store_id
GROUP BY S.store_name
ORDER BY Number_of_orders DESC;

--5. Show customer first names in UPPERCASE and last names in lowercase for the first 10 customers.
SELECT TOP 10
	UPPER(first_name) AS first_name_upper,
	LOWER(last_name) AS last_name_lower
FROM sales.customers;

--6. Get the length of each product name. Show product name and its length for the first 10 products.
SELECT 
	product_name,
	LEN(product_name) AS name_Length
FROM production.products
ORDER BY name_Length DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

--7. Format customer phone numbers to show only the area code (first 3 digits) for customers 1-15.
SELECT TOP 15 
	first_name,
	LEFT(phone, 3) AS code_area
FROM sales.customers;

--8. Show the current date and extract the year and month from order dates for orders 1-10.
SELECT 
	order_id,
	CAST(GETDATE() AS DATE) AS Today_date,
	YEAR(order_date) AS year,
	MONTH(order_date) AS month 
FROM sales.orders
ORDER BY order_id
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

--9.Join products with their categories. Show product name and category name for first 10 products.
SELECT TOP 10 
	p.product_name,
	c.category_name
FROM production.products P
JOIN production.categories C ON P.category_id = C.category_id;

--10.Join customers with their orders. Show customer name and order date for first 10 orders.
SELECT TOP 10 C.first_name+' '+ C.last_name AS customer_name, O.order_date
FROM sales.customers C
JOIN sales.orders O ON C.customer_id = O.customer_id
ORDER BY order_date DESC;

--11. Show all products with their brand names, even if some products don't have brands. Include product name, brand name (show 'No Brand' if null).
SELECT 
	P.product_name, 
	COALESCE(B.brand_name, 'No Brand') AS 'Brand_name'
FROM production.products P
LEFT JOIN production.brands B ON P.brand_id = B.brand_id;

--12. Find products that cost more than the average product price. Show product name and price.
SELECT 
	product_name,
	list_price AS Price
FROM production.products 
WHERE list_price > (SELECT AVG(list_price) FROM production.products);

--13.Find customers who have placed at least one order. Use a subquery with IN. Show customer_id and customer_name.
SELECT 
	C.customer_id,C.first_name+' '+C.last_name AS customer_name
FROM sales.customers C
WHERE C.customer_id IN (SELECT O.customer_id FROM sales.orders O );

--14. For each customer, show their name and total number of orders using a subquery in the SELECT clause.
SELECT 
	C.customer_id,C.first_name+' '+C.last_name AS customer_name,
	(SELECT COUNT(O.order_id) FROM sales.orders O WHERE C.customer_id = O.customer_id ) AS number_of_orders
FROM sales.customers C;

--15. Create a simple view called easy_product_list that shows product name, category name, and price. Then write a query to select all products from this view where price > 100.
CREATE VIEW easy_product_list AS
SELECT
	P.product_name,
	C.category_name,
	P.list_price
FROM production.products P
JOIN production. categories C ON P.category_id = C.category_id;

SELECT * 
FROM easy_product_list
WHERE list_price>100;

--Create a view called customer_info that shows customer ID, full name (first + last), email, and city and state combined. Then use this view to find all customers from California (CA).
CREATE VIEW customer_info AS
SELECT 
	customer_id, 
	first_name+' '+last_name AS full_name,
	email,
	city,
	state
FROM sales.customers;

SELECT *
FROM customer_info
WHERE state = 'CA';

--17. Find all products that cost between $50 and $200. Show product name and price, ordered by price from lowest to highest.
SELECT product_name, list_price
FROM production.products
WHERE list_price BETWEEN 50 AND 200
ORDER BY list_price;

--18. Count how many customers live in each state. Show state and customer count, ordered by count from highest to lowest.
SELECT 
	state, 
	COUNT(customer_id) AS number_of_customers
FROM sales.customers
GROUP BY state
ORDER BY number_of_customers DESC;

--important
--19. Find the most expensive product in each category. Show category name, product name, and price.
SELECT 
	C.category_name,
	P.product_name,
	P.list_price
FROM production.products P
JOIN production.categories C ON P.category_id = C.category_id
WHERE p.list_price = (SELECT MAX(list_price) FROM production.products P2 WHERE P2.category_id = C.category_id)

--20. Show all stores and their cities, including the total number of orders from each store. Show store name, city, and order count.
SELECT S.store_name, S.city, COUNT(order_id) AS number_of_orders
FROM sales.stores S
LEFT JOIN sales.orders O ON S.store_id = O.store_id
GROUP BY S.store_name, S.city;