--List all products with list price greater than 1000
SELECT *
FROM production.products
WHERE list_price > 1000
order by list_price;


--Get customers from "CA" or "NY" states
SELECT *
FROM sales.customers
WHERE state in('CA','NY');

--Retrieve all orders placed in 2023
SELECT *
FROM sales.orders
WHERE order_date >='2023-01-01' AND order_date < '2024-01-01';

--Show customers whose emails end with @gmail.com
SELECT *
FROM sales.customers
WHERE email LIKE '%@gmail.com';

--Show all inactive staff
SELECT *
FROM sales.staffs
WHERE active=0;

--List top 5 most expensive products
SELECT TOP (5) product_name, list_price
FROM production.products
ORDER BY list_price DESC;

--Show latest 10 orders sorted by date
SELECT TOP (10) *
FROM sales.orders
ORDER BY order_date DESC;

--Retrieve the first 3 customers alphabetically by last name
SELECT TOP (3) *
FROM sales.customers
ORDER BY last_name ;

--Find customers who did not provide a phone number
SELECT  *
FROM sales.customers
WHERE phone IS NULL;

--Show all staff who have a manager assigned
SELECT  *
FROM sales.staffs
WHERE manager_id IS NOT NULL ;

--Count number of products in each category
SELECT C.category_name ,count(*) as num_of_Products
FROM production.products P
JOIN production.categories C
ON P.category_id = C.category_id
group by C.category_name;

--Count number of customers in each state
SELECT state,count(*) as num_of_Customers
FROM sales.customers
GROUP BY state;

--Get average list price of products per brand
SELECT B.brand_name ,avg(P.list_price) as Avg_Price
FROM production.products P
JOIN production.brands B
ON P.brand_id = B.brand_id
GROUP BY B.brand_name ;

--Show number of orders per staff
SELECT CONCAT(S.first_name, S.last_name) AS staff_member,count(order_id) as num_of_Orders
FROM sales.orders O
JOIN sales.staffs S
ON O.staff_id = S.staff_id
GROUP BY CONCAT(S.first_name, S.last_name);

--Find customers who made more than 2 orders
SELECT CONCAT(S.first_name,S.last_name) AS customer_name,COUNT(order_id)as numofOrders
FROM sales.orders O
JOIN sales.customers S
ON O.customer_id = S.customer_id
GROUP BY CONCAT(S.first_name,S.last_name)
HAVING count(order_id) >2;

--Products priced between 500 and 1500
SELECT *
FROM production.products
WHERE list_price BETWEEN  500 AND 1500 ;

--Customers in cities starting with "S"
SELECT *
FROM sales.customers
WHERE city LIKE 'S%';

--Orders with order_status either 2 or 4
SELECT *
FROM sales.orders
WHERE order_status  IN (2, 4);

--Products from category_id IN (1, 2, 3)
SELECT *
FROM production.products
WHERE category_id IN (1, 2, 3);

--Staff working in store_id = 1 OR without phone number
SELECT *
FROM  sales.staffs
WHERE store_id = 1 OR phone IS NULL;