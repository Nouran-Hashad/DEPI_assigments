--1. Customer Spending Analysis
DECLARE @total_spent DECIMAL(10,2);

SELECT @total_spent = SUM(I.list_price)
FROM sales.customers C
JOIN sales.orders O ON C.customer_id = O.customer_id
JOIN sales.order_items I ON O.order_id = I.order_id
WHERE C.customer_id = 1;

IF @total_spent > 5000
    PRINT 'VIP Customer';
ELSE
    PRINT 'Regular Customer';

--2. Product Price Threshold Report
DECLARE @ex_products INT
SELECT 
@ex_products = COUNT(product_id)
FROM production.products 
WHERE list_price>1500
PRINT 'The products that cost more than 1500$ are: '+ CAST(@ex_products AS VARCHAR)

--3. Staff Performance Calculator
DECLARE @id INT;
DECLARE @year VARCHAR(4);
DECLARE @Num_of_orders INT;

SELECT 
  @id = staff_id,
  @year = CAST(YEAR(shipped_date) AS VARCHAR),
  @Num_of_orders = COUNT(order_id)
FROM sales.orders
WHERE staff_id = 2 AND YEAR(shipped_date) = 2017
GROUP BY staff_id, YEAR(shipped_date);

PRINT 'Staff ID: ' + CAST(@id AS VARCHAR);
PRINT 'Year: ' + @year;
PRINT 'Number of Orders: ' + CAST(@Num_of_orders AS VARCHAR);

--4. Global Variables Information
PRINT 'Server Name: ' + CAST(@@SERVERNAME AS VARCHAR);
PRINT 'SQL Server Version: ' + CAST(@@VERSION AS VARCHAR);
PRINT 'Rows Affected by Last Statement: ' + CAST(@@ROWCOUNT AS VARCHAR);

--5.Write a query that checks the inventory level for product ID 1 in store ID 1. Use IF statements to display different messages based on stock levels
DECLARE @quantity INT;

SELECT @quantity = quantity
FROM production.stocks
WHERE product_id = 1 AND store_id = 1;

IF @quantity > 20
    PRINT 'Well stocked';
ELSE IF @quantity BETWEEN 10 AND 20
    PRINT 'Moderate stock';
ELSE IF @quantity < 10
    PRINT 'Low stock - reorder needed';
ELSE
    PRINT 'Product not found or no stock info';

--6.Create a WHILE loop that updates low-stock items (quantity < 5) in batches of 3 products at a time. Add 10 units to each product and display progress messages after each batch.
DECLARE @ProductID INT;
DECLARE @Counter INT = 0;

WHILE EXISTS (
    SELECT TOP 1 product_id 
    FROM production.stocks 
    WHERE quantity < 5 AND product_id NOT IN (
        SELECT TOP (@Counter) product_id 
        FROM production.stocks 
        WHERE quantity < 5
        ORDER BY product_id
    )
)
BEGIN
    UPDATE TOP (3) production.stocks
    SET quantity = quantity + 10
    WHERE quantity < 5 
    AND product_id NOT IN (
        SELECT TOP (@Counter) product_id 
        FROM production.stocks 
        WHERE quantity < 5
        ORDER BY product_id
    );

    SET @Counter = @Counter + 3;

    PRINT 'Batch updated. Total products updated so far: ' + CAST(@Counter AS VARCHAR);
END;

--7. Product Price Categorization
SELECT 
    product_id,
    product_name,
    list_price,
    CASE 
        WHEN list_price < 300 THEN 'Budget'
        WHEN list_price BETWEEN 300 AND 800 THEN 'Mid-Range'
        WHEN list_price BETWEEN 801 AND 2000 THEN 'Premium'
        WHEN list_price > 2000 THEN 'Luxury'
        ELSE 'Unknown'
    END AS price_category
FROM production.products;

--8. Customer Order Validation
DECLARE @CustomerID INT = 5;
DECLARE @OrderCount INT;

IF EXISTS (SELECT 1 FROM sales.customers WHERE customer_id = @CustomerID)
BEGIN
    SELECT @OrderCount = COUNT(*) 
    FROM sales.orders 
    WHERE customer_id = @CustomerID;

    PRINT 'Customer ID ' + CAST(@CustomerID AS VARCHAR) + ' exists.';
    PRINT 'Total Orders: ' + CAST(@OrderCount AS VARCHAR);
END
ELSE
BEGIN
    PRINT 'Customer ID ' + CAST(@CustomerID AS VARCHAR) + ' does not exist.';
END

--9. Shipping Cost Calculator Function
CREATE FUNCTION CalculateShipping (@OrderTotal DECIMAL(10, 2))
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @ShippingCost DECIMAL(5, 2);

    IF @OrderTotal > 100
        SET @ShippingCost = 0.00;
    ELSE IF @OrderTotal BETWEEN 50 AND 99.99
        SET @ShippingCost = 5.99;
    ELSE
        SET @ShippingCost = 12.99;

    RETURN @ShippingCost;
END;

--10. Product Category Function
CREATE FUNCTION GetProductsByPriceRange (
    @MinPrice DECIMAL(10, 2),
    @MaxPrice DECIMAL(10, 2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.product_id,
        p.product_name,
        p.list_price,
        b.brand_name,
        c.category_name
    FROM production.products p
    JOIN production.brands b ON p.brand_id = b.brand_id
    JOIN production.categories c ON p.category_id = c.category_id
    WHERE p.list_price BETWEEN @MinPrice AND @MaxPrice
);

--11. Customer Sales Summary Function
CREATE FUNCTION GetCustomerYearlySummary (
    @CustomerID INT
)
RETURNS @Summary TABLE (
    Year INT,
    TotalOrders INT,
    TotalSpent DECIMAL(18, 2),
    AvgOrderValue DECIMAL(18, 2)
)
AS
BEGIN
    INSERT INTO @Summary
    SELECT 
        YEAR(o.order_date) AS Year,
        COUNT(o.order_id) AS TotalOrders,
        SUM(od.quantity * od.list_price * (1 - od.discount)) AS TotalSpent,
        AVG(od.quantity * od.list_price * (1 - od.discount)) AS AvgOrderValue
    FROM sales.orders o
    JOIN sales.order_items od ON o.order_id = od.order_id
    WHERE o.customer_id = @CustomerID
    GROUP BY YEAR(o.order_date)

    RETURN
END

--12. Discount Calculation Function
CREATE FUNCTION CalculateBulkDiscount (
    @Quantity INT
)
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @Discount DECIMAL(5, 2)

    IF @Quantity BETWEEN 1 AND 2
        SET @Discount = 0.00
    ELSE IF @Quantity BETWEEN 3 AND 5
        SET @Discount = 5.00
    ELSE IF @Quantity BETWEEN 6 AND 9
        SET @Discount = 10.00
    ELSE IF @Quantity >= 10
        SET @Discount = 15.00
    ELSE
        SET @Discount = 0.00  -- In case of invalid quantity like 0 or negative

    RETURN @Discount
END

--13.Customer Order History Procedure
CREATE PROCEDURE sp_GetCustomerOrderHistory
    @CustomerID INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_amount
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = @CustomerID
      AND (@StartDate IS NULL OR o.order_date >= @StartDate)
      AND (@EndDate IS NULL OR o.order_date <= @EndDate)
    GROUP BY o.order_id, o.order_date
    ORDER BY o.order_date DESC;
END

--14.Inventory Restock Procedure
CREATE PROCEDURE sp_RestockProduct
    @StoreID INT,
    @ProductID INT,
    @RestockQty INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Print old quantity
    SELECT quantity AS OldQty
    FROM store.stock
    WHERE store_id = @StoreID AND product_id = @ProductID;

    -- Update quantity
    UPDATE store.stock
    SET quantity = quantity + @RestockQty
    WHERE store_id = @StoreID AND product_id = @ProductID;

    -- Print new quantity
    SELECT quantity AS NewQty
    FROM store.stock
    WHERE store_id = @StoreID AND product_id = @ProductID;
END;

--15. Order Processing Procedure
CREATE PROCEDURE sp_ProcessNewOrder
    @CustomerID INT,
    @ProductID INT,
    @Quantity INT,
    @StoreID INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Get available stock
        DECLARE @Stock INT;
        SELECT @Stock = quantity
        FROM store.stock
        WHERE store_id = @StoreID AND product_id = @ProductID;

        IF @Stock IS NULL OR @Stock < @Quantity
        BEGIN
            RAISERROR('Not enough stock.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Reduce stock
        UPDATE store.stock
        SET quantity = quantity - @Quantity
        WHERE store_id = @StoreID AND product_id = @ProductID;

        -- Create order
        DECLARE @OrderID INT;
        INSERT INTO sales.orders (customer_id, order_date, store_id, staff_id)
        VALUES (@CustomerID, GETDATE(), @StoreID, 1);

        SET @OrderID = SCOPE_IDENTITY();

        -- Add product to order
        INSERT INTO sales.order_items (order_id, item_id, product_id, quantity, list_price, discount)
        VALUES (
            @OrderID,
            1,
            @ProductID,
            @Quantity,
            (SELECT list_price FROM production.products WHERE product_id = @ProductID),
            0
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT ERROR_MESSAGE();
    END CATCH
END;

--16.
CREATE PROCEDURE sp_SearchProducts
    @Name NVARCHAR(100) = NULL,
    @CategoryID INT = NULL,
    @MinPrice DECIMAL(10,2) = NULL,
    @MaxPrice DECIMAL(10,2) = NULL,
    @SortColumn NVARCHAR(50) = NULL
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM production.products WHERE 1=1';

    IF @Name IS NOT NULL
        SET @SQL += ' AND product_name LIKE ''%' + @Name + '%''';

    IF @CategoryID IS NOT NULL
        SET @SQL += ' AND category_id = ' + CAST(@CategoryID AS NVARCHAR);

    IF @MinPrice IS NOT NULL
        SET @SQL += ' AND list_price >= ' + CAST(@MinPrice AS NVARCHAR);

    IF @MaxPrice IS NOT NULL
        SET @SQL += ' AND list_price <= ' + CAST(@MaxPrice AS NVARCHAR);

    IF @SortColumn IS NOT NULL
        SET @SQL += ' ORDER BY ' + QUOTENAME(@SortColumn);

    EXEC sp_executesql @SQL;
END;

--17.
DECLARE @StartDate DATE = '2025-01-01';
DECLARE @EndDate DATE = '2025-03-31';
DECLARE @LowBonus DECIMAL(5,2) = 0.05;
DECLARE @HighBonus DECIMAL(5,2) = 0.10;

SELECT 
    s.staff_id,
    s.first_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS TotalSales,
    CASE 
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 50000 THEN @HighBonus
        ELSE @LowBonus
    END AS BonusRate,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)) *
        CASE 
            WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 50000 THEN @HighBonus
            ELSE @LowBonus
        END, 2) AS BonusAmount
FROM sales.staffs s
JOIN sales.orders o ON o.staff_id = s.staff_id
JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE o.order_date BETWEEN @StartDate AND @EndDate
GROUP BY s.staff_id, s.first_name;

--18.
SELECT 
    p.product_id,
    p.product_name,
    s.quantity AS Stock,
    p.category_id,
    CASE 
        WHEN s.quantity < 10 AND p.category_id = 1 THEN 50
        WHEN s.quantity < 10 AND p.category_id = 2 THEN 30
        WHEN s.quantity < 10 THEN 20
        ELSE 0
    END AS ReorderQuantity
FROM store.stock s
JOIN production.products p ON s.product_id = p.product_id;

--19.
SELECT 
    c.customer_id,
    c.first_name,
    ISNULL(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 0) AS TotalSpent,
    CASE 
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) IS NULL THEN 'No Orders'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 10000 THEN 'Gold'
        WHEN SUM(oi.quantity * oi.list_price * (1 - oi.discount)) >= 5000 THEN 'Silver'
        ELSE 'Bronze'
    END AS LoyaltyTier
FROM sales.customers c
LEFT JOIN sales.orders o ON o.customer_id = c.customer_id
LEFT JOIN sales.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.first_name;

--20.
CREATE PROCEDURE sp_DiscontinueProduct
    @ProductID INT,
    @ReplacementID INT = NULL
AS
BEGIN
    -- Check for pending orders
    IF EXISTS (
        SELECT 1 FROM sales.order_items oi
        JOIN sales.orders o ON oi.order_id = o.order_id
        WHERE oi.product_id = @ProductID AND o.status != 'Shipped'
    )
    BEGIN
        PRINT 'Cannot discontinue: Product is in pending orders.';
        RETURN;
    END

    -- Optional: Replace product in orders
    IF @ReplacementID IS NOT NULL
    BEGIN
        UPDATE sales.order_items
        SET product_id = @ReplacementID
        WHERE product_id = @ProductID;
    END

    -- Clear stock
    UPDATE store.stock
    SET quantity = 0
    WHERE product_id = @ProductID;

    -- Mark as discontinued
    UPDATE production.products
    SET discontinued = 1
    WHERE product_id = @ProductID;

    PRINT 'Product discontinued successfully.';
END;

