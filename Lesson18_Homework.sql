---# Lesson-18: View, temp table, variable, functions
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10,2)
);

CREATE TABLE Sales1 (
    SaleID INT PRIMARY KEY,
    ProductID INT,
    Quantity INT,
    SaleDate DATE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

INSERT INTO Products (ProductID, ProductName, Category, Price)
VALUES
(1, 'Samsung Galaxy S23', 'Electronics', 899.99),
(2, 'Apple iPhone 14', 'Electronics', 999.99),
(3, 'Sony WH-1000XM5 Headphones', 'Electronics', 349.99),
(4, 'Dell XPS 13 Laptop', 'Electronics', 1249.99),
(5, 'Organic Eggs (12 pack)', 'Groceries', 3.49),
(6, 'Whole Milk (1 gallon)', 'Groceries', 2.99),
(7, 'Alpen Cereal (500g)', 'Groceries', 4.75),
(8, 'Extra Virgin Olive Oil (1L)', 'Groceries', 8.99),
(9, 'Mens Cotton T-Shirt', 'Clothing', 12.99),
(10, 'Womens Jeans - Blue', 'Clothing', 39.99),
(11, 'Unisex Hoodie - Grey', 'Clothing', 29.99),
(12, 'Running Shoes - Black', 'Clothing', 59.95),
(13, 'Ceramic Dinner Plate Set (6 pcs)', 'Home & Kitchen', 24.99),
(14, 'Electric Kettle - 1.7L', 'Home & Kitchen', 34.90),
(15, 'Non-stick Frying Pan - 28cm', 'Home & Kitchen', 18.50),
(16, 'Atomic Habits - James Clear', 'Books', 15.20),
(17, 'Deep Work - Cal Newport', 'Books', 14.35),
(18, 'Rich Dad Poor Dad - Robert Kiyosaki', 'Books', 11.99),
(19, 'LEGO City Police Set', 'Toys', 49.99),
(20, 'Rubiks Cube 3x3', 'Toys', 7.99);

INSERT INTO Sales1 (SaleID, ProductID, Quantity, SaleDate)
VALUES
(1, 1, 2, '2025-04-01'),
(2, 1, 1, '2025-04-05'),
(3, 2, 1, '2025-04-10'),
(4, 2, 2, '2025-04-15'),
(5, 3, 3, '2025-04-18'),
(6, 3, 1, '2025-04-20'),
(7, 4, 2, '2025-04-21'),
(8, 5, 10, '2025-04-22'),
(9, 6, 5, '2025-04-01'),
(10, 6, 3, '2025-04-11'),
(11, 10, 2, '2025-04-08'),
(12, 12, 1, '2025-04-12'),
(13, 12, 3, '2025-04-14'),
(14, 19, 2, '2025-04-05'),
(15, 20, 4, '2025-04-19'),
(16, 1, 1, '2025-03-15'),
(17, 2, 1, '2025-03-10'),
(18, 5, 5, '2025-02-20'),
(19, 6, 6, '2025-01-18'),
(20, 10, 1, '2024-12-25'),
(21, 1, 1, '2024-04-20');

---### 1. Create a temporary table named MonthlySales to store the total quantity sold and total revenue for each product in the current month.
--**Return: ProductID, TotalQuantity, TotalRevenue**
Answer:
-- 1. Vaqtinchalik jadval yaratish
CREATE TABLE #MonthlySales (
    ProductID INT,
    TotalQuantity INT,
    TotalRevenue DECIMAL(10,2)
);

-- 2. Vaqtinchalik jadvalni ma'lumotlar bilan to'ldirish
INSERT INTO #MonthlySales (ProductID, TotalQuantity, TotalRevenue)
SELECT 
    s.ProductID,
    SUM(s.Quantity) AS TotalQuantity,
    SUM(s.Quantity * p.Price) AS TotalRevenue
FROM Sales1 s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE YEAR(s.SaleDate) = YEAR(GETDATE()) 
    AND MONTH(s.SaleDate) = MONTH(GETDATE())
GROUP BY s.ProductID;

-- 3. Natijani ko'rish
SELECT * FROM #MonthlySales
ORDER BY TotalRevenue DESC;

-- 4. Agar kerak bo'lsa, vaqtinchalik jadvalni tozalash
DROP TABLE #MonthlySales;
SELECT 
    s.ProductID,
    p.ProductName,
    p.Category,
    SUM(s.Quantity) AS TotalQuantity,
    SUM(s.Quantity * p.Price) AS TotalRevenue
INTO #MonthlySales
FROM Sales1 s
INNER JOIN Products p ON s.ProductID = p.ProductID
WHERE YEAR(s.SaleDate) = 2025 AND MONTH(s.SaleDate) = 4
GROUP BY s.ProductID, p.ProductName, p.Category;

SELECT * FROM #MonthlySales ORDER BY TotalRevenue DESC;

--### 2. Create a view named vw_ProductSalesSummary that returns product info along with total sales quantity across all time.
--**Return: ProductID, ProductName, Category, TotalQuantitySold**
Answer:
-- Avval mavjud view ni o'chirish (agar bor bo'lsa)
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_ProductSalesSummary')
    DROP VIEW vw_ProductSalesSummary;
GO

-- Yangi view yaratish
CREATE VIEW vw_ProductSalesSummary
WITH SCHEMABINDING
AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    ISNULL(SUM(s.Quantity), 0) AS TotalQuantitySold,
    COUNT_BIG(*) AS TotalRows
FROM dbo.Products p
LEFT JOIN dbo.Sales1 s ON p.ProductID = s.ProductID
GROUP BY p.ProductID, p.ProductName, p.Category;
GO
SELECT * FROM vw_ProductSalesSummary 
ORDER BY TotalQuantitySold DESC;
-- View ni ishlatish
SELECT * FROM vw_ProductSalesSummary 
ORDER BY TotalQuantitySold DESC;

--### 3. Create a function named fn_GetTotalRevenueForProduct(@ProductID INT)
--**Return: total revenue for the given product ID**
Answer:
-- 1. Funksiyani yaratish
CREATE FUNCTION fn_GetTotalRevenueForProduct (@ProductID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @TotalRevenue DECIMAL(10,2);
    
    SELECT @TotalRevenue = ISNULL(SUM(s.Quantity * p.Price), 0)
    FROM Sales1 s
    INNER JOIN Products p ON s.ProductID = p.ProductID
    WHERE s.ProductID = @ProductID;
    
    RETURN @TotalRevenue;
END;
GO

-- 2. Funksiyani test qilish
SELECT dbo.fn_GetTotalRevenueForProduct(1) AS Revenue_Product1;
SELECT dbo.fn_GetTotalRevenueForProduct(2) AS Revenue_Product2;
SELECT dbo.fn_GetTotalRevenueForProduct(5) AS Revenue_Product5;

---### 4. Create an function fn_GetSalesByCategory(@Category VARCHAR(50))
--**Return: ProductName, TotalQuantity, TotalRevenue for all products in that category.**
Answer:
-- 1. Avval funksiya borligini tekshirish va o'chirish
IF OBJECT_ID('dbo.fn_GetSalesByCategory', 'TF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetSalesByCategory;
GO

-- 2. Table-valued function yaratish
CREATE FUNCTION fn_GetSalesByCategory (@Category VARCHAR(50))
RETURNS TABLE
AS
RETURN (
    SELECT 
        p.ProductName,
        ISNULL(SUM(s.Quantity), 0) AS TotalQuantity,
        ISNULL(SUM(s.Quantity * p.Price), 0) AS TotalRevenue
    FROM Products p
    LEFT JOIN Sales1 s ON p.ProductID = s.ProductID
    WHERE p.Category = @Category
    GROUP BY p.ProductID, p.ProductName
);
GO

-- 3. Funksiyani test qilish
SELECT * FROM dbo.fn_GetSalesByCategory('Electronics')
ORDER BY TotalRevenue DESC;

SELECT * FROM dbo.fn_GetSalesByCategory('Groceries')
ORDER BY TotalQuantity DESC;

SELECT * FROM dbo.fn_GetSalesByCategory('Clothing')
ORDER BY ProductName;

--# Now we will move on with 2 Lateral-thinking puzzles (5 and 6th puzzles). Lateral-thinking puzzles are the ones that can’t be solved by straightforward logic — you have to think outside the box. 🔍🧠

--### 5. You have to create a function that get one argument as input from user and the function should return 'Yes' if the input number is a prime number and 'No' otherwise. You can start it like this:
Answer:
-- 1. Funksiyani yaratish
CREATE FUNCTION dbo.fn_IsPrime (@Number INT)
RETURNS VARCHAR(3)
AS
BEGIN
    DECLARE @Result VARCHAR(3) = 'Yes';
    DECLARE @i INT = 2;
    
    -- 0 va 1 prime emas
    IF @Number <= 1
        SET @Result = 'No';
    -- 2 va 3 prime
    ELSE IF @Number <= 3
        SET @Result = 'Yes';
    -- Juft sonlar va 3 ga bo'linadiganlar prime emas
    ELSE IF @Number % 2 = 0 OR @Number % 3 = 0
        SET @Result = 'No';
    ELSE
    BEGIN
        -- 5 dan boshlab sqrt(@Number) gacha tekshirish
        WHILE @i * @i <= @Number
        BEGIN
            IF @Number % @i = 0
            BEGIN
                SET @Result = 'No';
                BREAK;
            END
            SET @i = @i + 1;
        END
    END
    
    RETURN @Result;
END;
GO

-- 2. Funksiyani test qilish
SELECT dbo.fn_IsPrime(1) AS IsPrime;   -- No
SELECT dbo.fn_IsPrime(2) AS IsPrime;   -- Yes
SELECT dbo.fn_IsPrime(3) AS IsPrime;   -- Yes
SELECT dbo.fn_IsPrime(4) AS IsPrime;   -- No
SELECT dbo.fn_IsPrime(5) AS IsPrime;   -- Yes
SELECT dbo.fn_IsPrime(7) AS IsPrime;   -- Yes
SELECT dbo.fn_IsPrime(9) AS IsPrime;   -- No
SELECT dbo.fn_IsPrime(11) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(13) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(17) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(19) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(23) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(29) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(31) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(37) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(41) AS IsPrime;  -- Yes
SELECT dbo.fn_IsPrime(91) AS IsPrime;  -- No (7×13)
SELECT dbo.fn_IsPrime(97) AS IsPrime;  -- Yes

---### 6. Create a table-valued function named fn_GetNumbersBetween that accepts two integers as input:
Answer:
-- 1. Funksiyani yaratish (recursive CTE bilan)
CREATE FUNCTION dbo.fn_GetNumbersBetween (@Start INT, @End INT)
RETURNS TABLE
AS
RETURN (
    WITH NumbersCTE AS (
        -- Anchor: boshlang'ich son
        SELECT @Start AS Number
        UNION ALL
        -- Recursive: keyingi son
        SELECT Number + 1
        FROM NumbersCTE
        WHERE Number < @End
    )
    SELECT Number
    FROM NumbersCTE
);
GO

-- 2. Funksiyani test qilish
SELECT * FROM dbo.fn_GetNumbersBetween(1, 10);
SELECT * FROM dbo.fn_GetNumbersBetween(5, 15);
SELECT * FROM dbo.fn_GetNumbersBetween(-3, 3);
SELECT * FROM dbo.fn_GetNumbersBetween(100, 105);

--### 7. Write a SQL query to return the Nth highest distinct salary from the Employee table. If there are fewer than N distinct salaries, return NULL. 
Answer:
-- 1. Funksiyani yaratish
CREATE FUNCTION getNthHighestSalary(@N INT)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
    
    -- DISTINCT salary larni kamayish tartibida saralab, N-chisini olamiz
    SELECT @Result = Salary
    FROM (
        SELECT 
            DISTINCT Salary,
            DENSE_RANK() OVER (ORDER BY Salary DESC) AS SalaryRank
        FROM Employee
    ) AS RankedSalaries
    WHERE SalaryRank = @N;
    
    RETURN @Result;
END;
GO

-- 2. Test qilish uchun jadval yaratish
CREATE TABLE Employee (
    id INT PRIMARY KEY,
    salary INT
);

INSERT INTO Employee VALUES
(1, 100),
(2, 200),
(3, 300);

-- 3. Testlar
SELECT dbo.getNthHighestSalary(1) AS HighestSalary;   -- 300
SELECT dbo.getNthHighestSalary(2) AS SecondHighest;   -- 200
SELECT dbo.getNthHighestSalary(3) AS ThirdHighest;    -- 100
SELECT dbo.getNthHighestSalary(4) AS FourthHighest;   -- NULL

--### 8. Write a SQL query to find the person who has the most friends.

--**Return: Their id, The total number of friends they have**

--#### Friendship is mutual. For example, if user A sends a request to user B and it's accepted, both A and B are considered friends with each other. The test case is guaranteed to have only one user with the most friends.
Answer:
CREATE TABLE RequestAccepted (
    requester_id INT,
    accepter_id INT,
    accept_date DATE
);

INSERT INTO RequestAccepted VALUES
(1, 2, '2016-06-03'),
(1, 3, '2016-06-08'),
(2, 3, '2016-06-08'),
(3, 4, '2016-06-09');
-- 1. Barcha do'stlik aloqalarini bitta ustunda to'plab, har bir foydalanuvchining do'stlar sonini hisoblash
WITH AllFriendships AS (
    -- Request qiluvchi do'st sifatida
    SELECT requester_id AS user_id, accepter_id AS friend_id
    FROM RequestAccepted
    
    UNION ALL
    
    -- Accept qiluvchi do'st sifatida (o'zaro munosabat)
    SELECT accepter_id AS user_id, requester_id AS friend_id
    FROM RequestAccepted
),
FriendCounts AS (
    -- Har bir foydalanuvchining do'stlar sonini hisoblash
    SELECT 
        user_id AS id,
        COUNT(DISTINCT friend_id) AS num
    FROM AllFriendships
    GROUP BY user_id
)
-- Eng ko'p do'stga ega bo'lgan foydalanuvchini topish
SELECT TOP 1
    id,
    num
FROM FriendCounts
ORDER BY num DESC;

--### 9. Create a View for Customer Order Summary. 
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(50)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES Customers(customer_id),
    order_date DATE,
    amount DECIMAL(10,2)
);

-- Customers
INSERT INTO Customers (customer_id, name, city)
VALUES
(1, 'Alice Smith', 'New York'),
(2, 'Bob Jones', 'Chicago'),
(3, 'Carol White', 'Los Angeles');

-- Orders
INSERT INTO Orders (order_id, customer_id, order_date, amount)
VALUES
(101, 1, '2024-12-10', 120.00),
(102, 1, '2024-12-20', 200.00),
(103, 1, '2024-12-30', 220.00),
(104, 2, '2025-01-12', 120.00),
(105, 2, '2025-01-20', 180.00);

--**Create a view called vw_CustomerOrderSummary that returns a summary of customer orders. The view must contain the following columns:**

--> - Column Name | Description
--> - customer_id | Unique identifier of the customer
--> - name | Full name of the customer
--> - total_orders | Total number of orders placed by the customer
--> - total_amount | Cumulative amount spent across all orders
--> - last_order_date | Date of the most recent order placed by the customer
Answer:
CREATE VIEW vw_CustomerOrderSummary
AS
SELECT 
    c.customer_id,
    c.name,
    COUNT(o.order_id) AS total_orders,
    ISNULL(SUM(o.amount), 0) AS total_amount,
    MAX(o.order_date) AS last_order_date
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;
GO

-- 3. View ni test qilish
SELECT * FROM vw_CustomerOrderSummary
ORDER BY customer_id;

--### 10. Write an SQL statement to fill in the missing gaps. You have to write only select statement, no need to modify the table.
CREATE TABLE Gaps
(
RowNumber   INTEGER PRIMARY KEY,
TestCase    VARCHAR(100) NULL
);

INSERT INTO Gaps (RowNumber, TestCase) VALUES
(1,'Alpha'),(2,NULL),(3,NULL),(4,NULL),
(5,'Bravo'),(6,NULL),(7,NULL),(8,NULL),(9,NULL),(10,'Charlie'), (11, NULL), (12, NULL)
--Answer:
SELECT 
    g1.RowNumber,
    (
        SELECT TOP 1 TestCase
        FROM Gaps g2
        WHERE g2.RowNumber <= g1.RowNumber
            AND g2.TestCase IS NOT NULL
        ORDER BY g2.RowNumber DESC
    ) AS Workflow
FROM Gaps g1
ORDER BY g1.RowNumber;

WITH FilledGaps AS (
    -- Anchor: birinchi qator
    SELECT 
        RowNumber,
        TestCase AS Workflow
    FROM Gaps
    WHERE RowNumber = 1
    
    UNION ALL
    
    -- Recursive: keyingi qatorlar
    SELECT 
        g.RowNumber,
        COALESCE(g.TestCase, fg.Workflow) AS Workflow
    FROM Gaps g
    INNER JOIN FilledGaps fg ON g.RowNumber = fg.RowNumber + 1
)
SELECT * FROM FilledGaps
ORDER BY RowNumber;