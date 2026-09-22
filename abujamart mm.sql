create database Abujamart;  	-- creating the database 
use Abujamart;					-- use the database 

-- Exploratory Data Analytics
select * from customers;
select * from orders;
select * from products;

-- describe the table to know the structure( column names, data type)
describe customers;
describe orders;
describe products;

-- to count rows
select count(*) as 'Total Customer' from customers;  -- 53 rows
select count(*) as 'Total Order' from orders;   -- 121 rows
select count(*) as 'Total Product' from products;  -- 16 rows 

-- Data Cleaning Customer Table 

-- 1. Find duplicate rows 
select CustomerID,
count(*) as Occurences 
from customers 
group by customerID
having count(*)> 1;   -- we have three duplicate 

-- Remove Duplicate
create table customers_clean as select distinct * from customers;
drop table customers;
rename table customers_clean to customers;

 -- Find Missing Value
 
 select * from customers where Email is null or Email = '';  -- 3 blanks 
 select * from customers where Phone is null or Phone =  '';  -- 2 blanks 
 select * from customers where City is null or City = '';  -- 0 blanks
 select * from customers where FirstName is null or FirstName = ''; -- 0 blanks 
 
 -- handle Midding Values.
 update customers set Email = 'Not provided' where Email is null or Email = '';
  set sql_safe_updates = 0;
  
  -- check city column
  
  select distinct City from customers order by City;
  
  -- handling the spelling problem 

  update customers set city = trim(City);
  update customers set city = 'Abuja' where upper(city) = 'ABUJA';
  update customers set city = 'Enugu' where upper(city) = 'enugu';
  update customers set city = 'Benin City' where upper(city) = 'benin city';
  update customers set city = 'Ibadan' where upper(city) = 'ibadan';
  update customers set city = 'Lagos' where upper(city) = 'LAGOS';
  update customers set city = 'Port Harcourt' where upper(city) IN ('PH', 'PORTHARCOURT');
  
 
 
 -- View Signupdate and update signupdate
  select distinct Dates from customers;
  Alter table customers add column SignupDateclean Date;
  
  update customers
  set SignupDateclean = str_to_date(Dates, '%Y-%M-%d')
  where Dates like '_-_-_';
  
  UPDATE Customers
SET SignupDateClean = STR_TO_DATE(Dates, '%d/%m/%Y')
WHERE Dates LIKE '_//_';


UPDATE Customers
SET SignupDateClean = STR_TO_DATE(Dates, '%d.%m.%Y')
WHERE Dates LIKE '_.._';
 
 -- Swap the clean column in for the messy one (DDL: ALTER TABLE)
ALTER TABLE Customers DROP COLUMN Dates; -- delete the column command 
ALTER TABLE Customers CHANGE COLUMN SignupDateClean SignupDate DATE;  -- change column name 
 

-- ADD Primary Key 
 alter table customers add primary key(CustomerID);
 describe customers;
 
 -- Sanity Check 
 select * from customers order by CustomerID;


-- Pull raw SignupDate back in
ALTER TABLE customers ADD COLUMN SignupDateRaw VARCHAR(20);  -- create a new empty text column to hold the raw dates

UPDATE customers c
JOIN `customers.signup` r ON c.CustomerID = r.CustomerID   -- match each customer to their row in the freshly re-imported raw table
SET c.SignupDateRaw = r.SignupDate;                          -- copy the original messy date text across

-- Convert it properly this time
ALTER TABLE customers ADD COLUMN SignupDateClean DATE;       -- create a new proper DATE column, still empty for now

UPDATE customers
SET SignupDateClean = STR_TO_DATE(SignupDateRaw, '%Y-%m-%d') -- parse the ISO-style dates (e.g. 2024-06-09)
WHERE SignupDateRaw LIKE '_--_';                        -- only touch rows that actually look like YYYY-MM-DD

UPDATE customers
SET SignupDateClean = STR_TO_DATE(SignupDateRaw, '%d/%m/%Y') -- parse the slash-style dates (e.g. 09/06/2024)
WHERE SignupDateRaw LIKE '_//_';                        -- only touch rows that look like DD/MM/YYYY

UPDATE customers
SET SignupDateClean = STR_TO_DATE(SignupDateRaw, '%d.%m.%Y') -- parse the dot-style dates (e.g. 09.06.2024)
WHERE SignupDateRaw LIKE '_.._';                        -- only touch rows that look like DD.MM.YYYY

-- Check before cleanup
SELECT SignupDateRaw, SignupDateClean FROM customers;         -- eyeball every row side-by-side, make sure nothing is still NULL
select * from customers;

-- Cleanup once confirmed correct
ALTER TABLE customers DROP COLUMN SignupDate;                 -- remove the old broken/empty DATE column
ALTER TABLE customers DROP COLUMN SignupDateRaw;               -- remove the temporary raw-text column, job done
ALTER TABLE customers CHANGE COLUMN SignupDateClean SignupDate DATE;  -- rename the clean column back to SignupDate
DROP TABLE customers.signup;                                -- delete the temporary import table, no longer needed





-- Remove duplicate 
-- find the missing order of date 
-- remove the null in the order of date 
--  fix the impossible value in quantity because qtty cannot be negative 
--  check both product and payment and see they are correctly spelt 

-- data cleaning order 



-- ---------------------------------------------------------------------
-- 5.2  PRODUCTS TABLE
-- ---------------------------------------------------------------------

-- Step 1 & 2: Remove the duplicate product row
CREATE TABLE Products_Clean AS
SELECT DISTINCT * FROM Products;                                    -- build a fresh table keeping only unique rows (drops the exact duplicate)

DROP TABLE Products;                                                 -- delete the old messy table
RENAME TABLE Products_Clean TO Products;                             -- rename the clean copy back to Products

-- Step 3: Find missing prices
SELECT * FROM Products WHERE Price IS NULL or price = '';                          -- show which products have no price recorded
select * from products;
-- Step 4: Fix missing prices. In a real project you'd confirm these
-- with DeltaMart's inventory team -- here we use the known list price.
UPDATE Products SET Price = 2500  WHERE ProductID = 3  AND Price IS NULL; -- Bar Soap Pack -- manually enter the correct known price
UPDATE Products SET Price = 27500 WHERE ProductID = 9  AND Price IS NULL; -- Blender 1.5L  -- manually enter the correct known price

-- Step 5: Fix the impossible value -- stock can't be negative
SELECT * FROM Products WHERE StockQuantity < 0;                      -- find any product with a negative stock count (data entry error)
UPDATE Products SET StockQuantity = ABS(StockQuantity) WHERE StockQuantity < 0; -- flip negative numbers to positive using ABS()

 
-- Step 6: Standardize Category casing
select distinct Category from products;
UPDATE Products SET Category = 'Groceries'   WHERE UPPER(Category) = 'GROCERIES';   -- catch every casing variant of "Groceries"
UPDATE Products SET Category = 'Household'   WHERE UPPER(Category) = 'HOUSEHOLD';   -- catch every casing variant of "Household"
UPDATE Products SET Category = 'Electronics' WHERE UPPER(Category) = 'ELECTRONICS'; -- catch every casing variant of "Electronics"
UPDATE Products SET Category = 'Baby Care'   WHERE UPPER(Category) = 'BABY CARE';   -- catch every casing variant of "Baby Care"
UPDATE Products SET Category = 'Fashion'     WHERE UPPER(Category) = 'FASHION';     -- catch every casing variant of "Fashion"
UPDATE Products SET Category = 'Furniture'   WHERE UPPER(Category) = 'FURNITURE';   -- catch every casing variant of "Furniture"

-- Step 7: Lock in the primary key
ALTER TABLE Products ADD PRIMARY KEY (ProductID);                    -- now that duplicates are gone, enforce ProductID uniqueness

SELECT * FROM Products ORDER BY ProductID;  
describe table products;                         -- sanity check: eyeball the fully cleaned table


-- ---------------------------------------------------------------------
-- 5.3  ORDERS TABLE
-- ---------------------------------------------------------------------

-- Step 1 & 2: Remove the exact duplicate order row
CREATE TABLE Orders_Clean AS
SELECT DISTINCT * FROM Orders;                                       -- build a fresh table keeping only unique rows

DROP TABLE Orders;                                                    -- delete the old messy table
RENAME TABLE Orders_Clean TO Orders;                                  -- rename the clean copy back to Orders


-- Step 3: Find missing OrderDates
SELECT * FROM Orders WHERE OrderDate IS NULL OR OrderDate = '';       -- show orders with no date recorded

-- Step 4: We have no reliable way to guess a missing OrderDate, so we
-- remove those rows rather than invent a date (DML: DELETE).
DELETE FROM Orders WHERE OrderDate IS NULL OR OrderDate = '';         -- remove rows we can't fix honestly

-- Step 5: Fix the impossible value -- quantity can't be negative
SELECT * FROM Orders WHERE Quantity < 0;                              -- find any order with a negative quantity (entry error)
UPDATE Orders SET Quantity = ABS(Quantity) WHERE Quantity < 0;        -- flip negative numbers to positive using ABS()

-- Step 6: Find "orphan" rows -- an Order that points to a Customer or
-- Product that doesn't actually exist (a referential integrity issue)
SELECT * FROM Orders WHERE CustomerID NOT IN (SELECT CustomerID FROM Customers); -- orders linked to a customer that isn't real
SELECT * FROM Orders WHERE ProductID  NOT IN (SELECT ProductID  FROM Products);  -- orders linked to a product that isn't real

-- These orders can never be matched to a real customer/product, so we
-- remove them -- keeping them would break every JOIN we write later.
DELETE FROM Orders WHERE CustomerID NOT IN (SELECT CustomerID FROM Customers); -- delete the orphaned customer references
DELETE FROM Orders WHERE ProductID  NOT IN (SELECT ProductID  FROM Products);  -- delete the orphaned product references

-- Step 7: Standardize PaymentMethod casing
select distinct paymentmethod from orders;
UPDATE Orders SET PaymentMethod = 'Card'     WHERE UPPER(PaymentMethod) = 'CARD';     -- catch every casing variant of "Card"
UPDATE Orders SET PaymentMethod = 'Cash'     WHERE UPPER(PaymentMethod) = 'CASH';     -- catch every casing variant of "Cash"
UPDATE Orders SET PaymentMethod = 'Transfer' WHERE UPPER(PaymentMethod) = 'TRANSFER'; -- catch every casing variant of "Transfer"

-- Step 8: Convert OrderDate from messy text into a real DATE
ALTER TABLE Orders ADD COLUMN OrderDateClean DATE;                    -- create a new empty DATE column to hold the converted values

UPDATE Orders
SET OrderDateClean = STR_TO_DATE(OrderDate, '%Y-%m-%d')               -- parse ISO-style dates (e.g. 2024-06-09)
WHERE OrderDate LIKE '_--_';       

                             -- only touch rows shaped like YYYY-MM-DD

UPDATE Orders
SET OrderDateClean = STR_TO_DATE(OrderDate, '%d/%m/%Y')               -- parse slash-style dates (e.g. 09/06/2024)
WHERE OrderDate LIKE '_//_';                                    -- only touch rows shaped like DD/MM/YYYY

set sql_safe_updates = 0;
UPDATE Orders
SET OrderDateClean = STR_TO_DATE(OrderDate, '%d.%m.%Y')               -- parse dot-style dates (e.g. 09.06.2024)
WHERE OrderDate LIKE '_.._';                                    -- only touch rows shaped like DD.MM.YYYY

ALTER TABLE Orders DROP COLUMN OrderDate;                             -- remove the old messy text column
ALTER TABLE Orders CHANGE COLUMN OrderDateClean OrderDate DATE;       -- rename the clean column back to OrderDate

-- Step 9: Now that every CustomerID/ProductID is valid, connect the
-- tables with keys -- the foundation that makes JOINs reliable
-- (DDL: ALTER TABLE ... ADD PRIMARY KEY / FOREIGN KEY)
ALTER TABLE Orders ADD PRIMARY KEY (OrderID);                                          -- enforce OrderID uniqueness
ALTER TABLE Orders ADD FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);      -- link every order to a real customer
ALTER TABLE Orders ADD FOREIGN KEY (ProductID)  REFERENCES Products(ProductID);        -- link every order to a real product

SELECT * FROM Orders ORDER BY OrderDate;                              -- sanity check: eyeball the fully cleaned table


-- ---------------------------------------------------------------------
-- A NOTE ON TCL AND DCL (from the "SQL Command Categories" slide)
-- ---------------------------------------------------------------------
# TCL (Transaction Control): wraps a set of changes so they either ALL
# succeed or ALL undo -- useful when cleaning production data. Example
# (illustrative only -- the cleaning above is already applied):
--
-- START TRANSACTION;                                    -- mark the start of a group of changes
-- UPDATE Products SET Price = 2500 WHERE ProductID = 3;  -- make a change (not saved permanently yet)
-- COMMIT;      -- saves the change permanently            -- lock in every change since START TRANSACTION
-- -- or --
-- ROLLBACK;    -- undoes everything since START TRANSACTION -- cancel every change since START TRANSACTION
--
# DCL (Data Control): manages WHO can access the database -- relevant
# once multiple analysts share one server. Example syntax only:
--
-- GRANT SELECT ON DeltaMart.* TO 'junior_analyst'@'localhost';    -- give a user permission to read the database
-- REVOKE SELECT ON DeltaMart.* FROM 'junior_analyst'@'localhost'; -- take that read permission away


-- (DQL): ANALYSIS -- ANSWERING DELTAMART'S BUSINESS QUESTIONS

# The data is clean. Now we answer the questions DeltaMart management
# actually cares about -- this is the payoff of everything above.

--  WHERE -- simple filtering
-- "Show me every customer based in Lagos."
SELECT * FROM Customers WHERE City = 'Lagos';                        -- filter rows down to just Lagos customers

-- "Show me every order paid for by card, with quantity of 3 or more."
SELECT * FROM Orders WHERE PaymentMethod = 'Card' AND Quantity >= 3; -- filter with two conditions combined by AND

--  ORDER BY -- sorting results
-- "List products from most expensive to least expensive."
SELECT ProductName, Price FROM Products ORDER BY Price DESC;         -- sort highest price first (DESC = descending)

-- "List customers alphabetically by first name."
SELECT FirstName, LastName, City FROM Customers ORDER BY FirstName ASC; -- sort A-to-Z (ASC = ascending, the default)

--  Aggregate functions -- turning rows into a single business number
SELECT COUNT(*)              AS TotalCustomers   FROM Customers;     -- count how many customer rows exist
SELECT COUNT(*)              AS TotalOrders      FROM Orders;        -- count how many order rows exist
SELECT ROUND(AVG(Price), 2)  AS AvgProductPrice  FROM Products;      -- average price, rounded to 2 decimal places
SELECT MAX(Price)            AS MostExpensive    FROM Products;      -- find the single highest price
SELECT MIN(Price)            AS CheapestProduct  FROM Products;      -- find the single lowest price

--  GROUP BY + aggregates -- DeltaMart's real reporting questions
-- "How many customers do we have in each city?"
SELECT City, COUNT(*) AS NumberOfCustomers
FROM Customers
GROUP BY City                                                         -- bucket rows by City before counting
ORDER BY NumberOfCustomers DESC;                                      -- show the biggest city first

-- "How many products are in each category, and what's their average price?"
SELECT Category, COUNT(*) AS NumberOfProducts, ROUND(AVG(Price), 2) AS AvgPrice
FROM Products
GROUP BY Category                                                     -- bucket rows by Category
ORDER BY AvgPrice DESC;                                               -- show the priciest category first

-- "How many orders came through each payment method?"
SELECT PaymentMethod, COUNT(*) AS NumberOfOrders
FROM Orders
GROUP BY PaymentMethod                                                -- bucket rows by PaymentMethod
ORDER BY NumberOfOrders DESC;                                         -- show the most-used method first

--   JOIN -- connecting Customers + Orders + Products into one report
# A JOIN combines related information so you can build a complete
# picture -- exactly what the slide deck's "Connecting Multiple Tables"
# section covers.

-- Full order report: who bought what, and how much they paid.
SELECT
    o.OrderID,
    c.FirstName,
    c.LastName,
    c.City,
    p.ProductName,
    p.Category,
    o.Quantity,
    p.Price,
    (o.Quantity * p.Price) AS OrderTotal,   -- calculate revenue per order on the fly
    o.OrderDate,
    o.PaymentMethod
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID   -- pull in the matching customer's details
INNER JOIN Products  p ON o.ProductID  = p.ProductID    -- pull in the matching product's details
ORDER BY o.OrderDate;                                   -- show orders in date order

-- JOIN + GROUP BY -- the question every retailer wants answered:
-- "Which city generates the most revenue?"
SELECT
    c.City,
    SUM(o.Quantity * p.Price) AS TotalRevenue                         -- add up revenue across every order per city
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID                 -- join to know which city each order belongs to
INNER JOIN Products  p ON o.ProductID  = p.ProductID                  -- join to know each order's price
GROUP BY c.City                                                       -- bucket the totals by city
ORDER BY TotalRevenue DESC;                                           -- show the top-earning city first

-- "Which product category sells the most units?"
SELECT
    p.Category,
    SUM(o.Quantity) AS UnitsSold,                                     -- total items sold per category
    SUM(o.Quantity * p.Price) AS TotalRevenue                         -- total revenue per category
FROM Orders o
INNER JOIN Products p ON o.ProductID = p.ProductID                    -- join to know each order's category and price
GROUP BY p.Category                                                   -- bucket by category
ORDER BY TotalRevenue DESC;                                           -- show the highest-earning category first

-- "Who are our top 5 customers by total amount spent?"
SELECT
    c.FirstName,
    c.LastName,
    SUM(o.Quantity * p.Price) AS TotalSpent                           -- add up everything each customer has spent
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID                 -- join to know which customer placed each order
INNER JOIN Products  p ON o.ProductID  = p.ProductID                  -- join to know each order's price
GROUP BY c.CustomerID, c.FirstName, c.LastName                        -- bucket by individual customer
ORDER BY TotalSpent DESC                                              -- show the biggest spenders first
LIMIT 5;                                                              -- only keep the top 5 rows

-- =====================================================================
-- END OF SCRIPT
-- Next step: connect Power BI (or Excel/Tableau) to this DeltaMart
-- database and turn these queries into a dashboard -- see the
-- accompanying Business Brief for exactly what to build

  
  -- How to swap columns
  alter table customers drop column SignupDate;    
  alter table customers change SignupDateclean Dates date;  -- note the first time we used rename because it was for a table but in this swapping of column we used altar because its a table
  
  
  -- ADD primary key
  alter table customers add primary key(CustomerID);
  describe customers;
  
  -- sanity Check 
select * from customers order by CustomerID;



-- remove duplicate 
-- find the missing order of date 
-- remove the null in the order of date 
-- fix the impossible value in quantity because quantity cannot be negative 
-- check both product and payment method and see they are corectly spelt

-- removing duplicate for table orders

-- 1. Find duplicate rows 
select OrderID,
count(*) as Occurences 
from orders 
group by OrderID
having count(*)> 1;  -- 2 duplicate;

-- removing duplicate 

create table orders_clean as select distinct * from orders;
drop table orders;
rename table orders_clean to orders;

-- find the missing order of date 

 select * from orders where OrderDate is null or OrderDate = '';  -- 2 blanks 
 select * from orders where Quantity is null or Quantity =  '';  -- 0 blanks 
 select * from orders where PaymentMethod is null or PaymentMethod = '';  -- 0 blanks
 select * from orders where ProductID is null or ProductID = ''; -- 0 blanks 

-- remove the null in the order of date 
-- handle Midding Values.
 update orders set OrderDate = 'Not provided' where OrderDate is null or OrderDate = '';
  
-- check both product and payment method and see they are corectly spelt
-- handling the spelling problem 

select distinct PaymentMethod from orders order by PaymentMethod;
select distinct ProductID from orders order by ProductID;

  
 


 
 








  

  
  
  
  
  


