-- Create Database
Create Database MiniProject
-- Use Database
use MiniProject
-- Create Big table to insert all data in it and all columna are varchar to prevent errors from occuring
CREATE TABLE Big_Table(
    OrderID         VARCHAR(20),
    OrderDate       VARCHAR(20),
    ShipDate        VARCHAR(20),
    ShipMode        VARCHAR(50),
    CustomerID      VARCHAR(20),
    CustomerName    VARCHAR(100),
    Segment         VARCHAR(50),
    CountryRegion   VARCHAR(50),
    City            VARCHAR(50),
    State           VARCHAR(50),
    PostalCode      VARCHAR(10),
    Region          VARCHAR(20),
    ProductID       VARCHAR(20),
    Category        VARCHAR(50),
    SubCategory     VARCHAR(50),
    ProductName     VARCHAR(255),
    Sales           VARCHAR(30),
    Quantity        VARCHAR(20),
    Discount        VARCHAR(20),
    Profit          VARCHAR(30)
);

BULK INSERT Big_Table
FROM 'D:\Proffessional data analyst\SQL\mini project\MiniProject SQL Data.csv'
WITH (
    FORMAT   = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);

-- Create Tables (Fact & Dimention)

CREATE TABLE DimCustomers (
    CustomerID      INT           PRIMARY KEY,
    CustomerName    VARCHAR(100)  NOT NULL,
    Segment         VARCHAR(50)   NOT NULL
);

CREATE TABLE DimProducts (
    ProductID       INT           PRIMARY KEY,
    Category        VARCHAR(50)   NOT NULL,
    SubCategory     VARCHAR(50)   NOT NULL,
    ProductName     VARCHAR(255)  NOT NULL
);

CREATE TABLE DimLocation (
    LocationID      INT IDENTITY(1,1) PRIMARY KEY,
    CountryRegion   VARCHAR(50)   NOT NULL,
    City            VARCHAR(50)   NOT NULL,
    State           VARCHAR(50)   NOT NULL,
    PostalCode      Varchar(20)         NOT NULL,
    Region          VARCHAR(20)   NOT NULL
);

CREATE TABLE DimOrders (
    OrderID         INT           PRIMARY KEY,
    OrderDate       DATE          NOT NULL,
    ShipDate        DATE          NOT NULL,
    ShipMode        VARCHAR(50)   NOT NULL,
    CustomerID      INT           NOT NULL,
    LocationID      INT           NOT NULL
);

CREATE TABLE FactOrderItems (
    OrderID         INT           NOT NULL,
    ProductID       INT           NOT NULL,
    Sales           DECIMAL(18,4) NOT NULL,
    Quantity        INT           NOT NULL,
    Discount        DECIMAL(4,2)  NOT NULL,
    Profit          DECIMAL(18,4) NOT NULL
);


-- Fill Tables (Fact & Dimention)

INSERT INTO DimCustomers (CustomerID, CustomerName, Segment)
SELECT DISTINCT CAST(CustomerID AS INT), CustomerName, Segment
FROM Big_Table;

INSERT INTO DimProducts (ProductID, Category, SubCategory, ProductName)
SELECT DISTINCT CAST(ProductID AS INT), Category, SubCategory, ProductName
FROM Big_Table;

INSERT INTO DimLocation (CountryRegion, City, State, PostalCode, Region)
SELECT DISTINCT CountryRegion, City, State, PostalCode , Region
FROM Big_Table;

INSERT INTO DimOrders (OrderID, OrderDate, ShipDate, ShipMode, CustomerID, LocationID)
SELECT DISTINCT
        CAST(B.OrderID AS INT),
        CONVERT(DATE, B.OrderDate, 101),
        CONVERT(DATE, B.ShipDate,  101),
        B.ShipMode,
        CAST(B.CustomerID AS INT),
        l.LocationID
FROM Big_Table B
INNER JOIN DimLocation l
        ON l.CountryRegion = B.CountryRegion
       AND l.City          = B.City
       AND l.State         = B.State
       AND l.PostalCode    = CAST(B.PostalCode AS INT)
       AND l.Region        = B.Region;


INSERT INTO FactOrderItems (OrderID, ProductID, Sales, Quantity, Discount, Profit)
SELECT  CAST(OrderID   AS INT),
        CAST(ProductID AS INT),
        CAST(Sales     AS DECIMAL(18,4)),
        CAST(Quantity  AS INT),
        CAST(Discount  AS DECIMAL(4,2)),
        CAST(Profit    AS DECIMAL(18,4))
FROM Big_Table;


-- Foreign Keys
ALTER TABLE DimOrders
    ADD CONSTRAINT FK_Orders_Customer
    FOREIGN KEY (CustomerID) REFERENCES DimCustomers(CustomerID);

ALTER TABLE DimOrders
    ADD CONSTRAINT FK_Orders_Location
    FOREIGN KEY (LocationID) REFERENCES DimLocation(LocationID);

ALTER TABLE FactOrderItems
    ADD CONSTRAINT FK_Fact_Orders
    FOREIGN KEY (OrderID) REFERENCES DimOrders(OrderID);

ALTER TABLE FactOrderItems
    ADD CONSTRAINT FK_Fact_Product
    FOREIGN KEY (ProductID) REFERENCES DimProducts(ProductID);


-- Explore Tables

select *
from DimCustomers

select *
from FactOrderItems

select *
from DimLocation

select *
from  DimOrders

select *
from DimProducts


-- 1. Category By Profit
-- Insight : Office Supplies is the most profitable category.
select category, format(sum(OI.profit), 'N1') as Total_Profit
from DimProducts P
join FactOrderItems OI
on P.ProductID = OI.ProductID
group by Category

-- 2. Top 5 Sub-Category By Profit 
select Top 5 P.SubCategory, round(sum(OI.profit),2)  as Total_Profit
from DimProducts P
join FactOrderItems OI
on P.ProductID = OI.ProductID
group by SubCategory
order by Total_Profit desc

-- 3. Top 3 Least Profitable Sub-Categories 
-- Insight: Tables, bookcases, and supplies are generating negative profits.
select top 3 P.SubCategory, round(sum(OI.profit),2)  as Total_Profit
from DimProducts P
join FactOrderItems OI
on P.ProductID = OI.ProductID
group by SubCategory
order by Total_Profit asc

-- 4. Top 3 Products By Profit
select top 3 P.ProductName,  p.productID,  round(sum(OI.profit),2)  as Total_Profit
from DimProducts P
join FactOrderItems OI
on P.ProductID = OI.ProductID
group by P.ProductID, P.ProductName
order by Total_Profit desc

-- 5. Products that generate sales but no profit
-- Isight: out of 1,850 products generate sales but no profit 299 
select P.ProductID, P.ProductName, SUM(OI.Sales) AS TotalSales, SUM(OI.Profit) AS TotalProfit
from DimProducts P
join FactOrderItems OI
on P.ProductID = OI.ProductID
group by P.ProductID, P.ProductName
Having SUM(OI.Sales) > 0 and SUM(OI.Profit) < 0

-- 6. Segment By Profit
-- Insight : Consumer is the most profitable segment
select C.Segment , round(sum(OI.Profit), 2) as TotalProfit 
from DimCustomers C
join DimOrders O
on C.CustomerID = O.CustomerID
join FactOrderItems OI
on OI.orderID = O.OrderID 
group by C.Segment
ORDER BY TotalProfit DESC 

-- 7. Segment By Sales
-- Insight : The Consumer segment generated the highest sales and profit.
select C.Segment , round(sum(OI.Sales), 2) as TotalSales
from DimCustomers C
join DimOrders O
on C.CustomerID = O.CustomerID
join FactOrderItems OI
on OI.orderID = O.OrderID 
group by C.Segment
ORDER BY TotalSales DESC

-- 8. Top 2 customers by count of orders
select Top 2 with ties C.CustomerName ,COUNT(o.OrderID) AS TotalOrders 
from DimCustomers c
join DimOrders O
on C.CustomerID = O.CustomerID
group by C.CustomerID , C.CustomerName
order by TotalOrders desc

select distinct ShipMode from DimOrders

-- 9. Repeat Rate Purchase 
-- Insight: Repeat Rate Purchase = 98.49% --> High Customer Loyalty & Satisfaction
with orders_count as (
select COUNT(O.OrderID) as TotalOrders,
       C.CustomerID
from DimOrders O
JOIN DimCustomers C
ON O.CustomerID = C.CustomerID
group by C.CustomerID)

select 
 format(count (case when TotalOrders > 1 then 1 End) * 100.0/ count (*), 'N2') as  Repeat_Rate_Purchase 
from orders_count

-- 10. RFM (Recency - Frequency - Monetary)
SELECT 
    C.CustomerID,
    DATEDIFF(month, MAX(O.OrderDate), GETDATE()) AS Recency,
    COUNT(distinct O.OrderID) AS Frequency,
    SUM(OI.Sales) AS Monetary
FROM DimCustomers C
JOIN DimOrders O ON C.CustomerID = O.CustomerID
JOIN FactOrderItems OI ON O.OrderID = OI.OrderID
GROUP BY C.CustomerID

-- 9. Shipping Delay 
-- Insight: First Class has the highest delay rate among all shipping modes.
with OrderShipping as 
(select OrderID, shipmode, datediff(day,orderDate, shipdate) DaysToShip,
        (case
        when shipmode = 'Same Day' and datediff(day,orderDate, shipdate) > 0 then 1
        when shipmode = 'First Class' and datediff(day,orderDate, shipdate) > 2 then 1
        when shipmode = 'Second Class' and datediff(day,orderDate, shipdate) > 4 then 1
        when shipmode = 'Standard Class' and datediff(day,orderDate, shipdate) > 6 then 1
        ELSE 0
        end ) as IsDelayed
from DimOrders )

select
    ShipMode,
    COUNT(*) AS TotalOrders,
    SUM(IsDelayed) AS DelayedOrdersCount,
    AVG(DaysToShip) AS AvgDaysToShip,
    CAST(SUM(IsDelayed) * 100 / COUNT(*) as DECIMAL(5,0)) AS DelayPercentage
from OrderShipping
group by ShipMode
ORDER BY DelayPercentage desc;



-- 10. Sales & Profit By Years
-- Insight: 2019 generated the highest overall sales and profit.
select year(OrderDate) as Years ,
       sum(OI.Sales) AS TotalSales,
       sum(OI.Profit) AS TotalProfit
from dimorders O
join FactOrderItems OI
on OI.orderID = O.OrderID
group by year(OrderDate)
order by TotalSales desc, TotalProfit desc




-- 11. Monthly Sales Trend
create procedure Monthly_Sales_Trends
                 @year int = NUll,
                 @month int = NUll
as begin
select year(OrderDate) as Years , 
       month(OrderDate) as Months , 
       sum(OI.Sales) AS TotalSales,
       sum(OI.Profit) AS TotalProfit
from dimorders O
join FactOrderItems OI
on OI.orderID = O.OrderID
where (@year IS NULL OR YEAR(O.OrderDate) = @year) and
      (@month IS NULL OR MONTH(O.OrderDate) = @month) 
group by  year(OrderDate), month(OrderDate)
order by years , Months
End

-- All Years & Months
Exec Monthly_Sales_Trends
-- You Choose Year (Optional) --> Show All months in a specific year
Exec Monthly_Sales_Trends @year = 2016
-- You Choose Month (Optional) --> Show a specific Month in all years
Exec Monthly_Sales_Trends @month = 3
-- You Choose Year & Month (Optional) --> Show a Specific month in a specific year
Exec Monthly_Sales_Trends @year = 2019 , @month = 2



-- 12. Profit By Month Across All Years
-- Insight: December generated the highest profit.
select
       format (O.OrderDate, 'MMMM') as Months , 
       sum(OI.Profit) AS TotalProfit
from dimorders O
join FactOrderItems OI
on OI.orderID = O.OrderID
group by month(O.OrderDate), format (O.OrderDate, 'MMMM')
order by TotalProfit desc

-- 13. Quartiel Sales Trend
with SalesByQuartile as
(select   year(OrderDate) as Years,
         datepart(QUARTER, OrderDate) AS Quarters,
         sum(OI.sales) as TotalSales 
from FactOrderItems OI
JOIN Dimorders O
on OI.orderid = O.orderid 
group by  DATEPART(QUARTER, OrderDate), year(OrderDate)
)
select * from SalesByQuartile order by Years, Quarters
 

-- 14. High Value Orders (Orders Above Average Sales)
SELECT O.OrderID,
       ROUND(SUM(OI.Sales), 2) AS OrderTotalSales
FROM DimOrders O
JOIN FactOrderItems OI
ON O.OrderID = OI.OrderID
GROUP BY O.OrderID
HAVING SUM(OI.Sales) > (SELECT AVG(Sales) 
                        FROM FactOrderItems)
ORDER BY OrderTotalSales DESC;

-- KPI: Total Sales
CREATE PROCEDURE TotalSales
AS BEGIN
SELECT sum(OI.Sales) as TotalSales
FROM factorderitems OI
END
EXEC TotalSales

-- KPI: Total Profit
create PROCEDURE TotalProfit
AS BEGIN
SELECT sum(OI.Profit) 
FROM factorderitems OI
END

Alter PROCEDURE TotalProfit
AS BEGIN
SELECT sum(OI.Profit) as TotalProfit
FROM factorderitems OI
END
EXEC TotalProfit

-- KPI: Net Revenue
create PROCEDURE NetRevenue
AS BEGIN
SELECT sum(OI.sales * (1 - OI.Discount)) as NetRevenue
FROM factorderitems OI
END
EXEC NetRevenue

-- View
CREATE VIEW vw_Sales_Performance_Summary AS
SELECT 
    O.OrderID,
    O.OrderDate,
    C.CustomerName,
    P.ProductName,
    P.Category,
    P.SubCategory,
    L.Region,
    L.City,
    OI.Sales,
    OI.Profit,
    OI.Discount,
    OI.Quantity
FROM FactOrderItems OI
JOIN DimOrders O ON OI.OrderID = O.OrderID
JOIN DimCustomers C ON O.CustomerID = C.CustomerID
JOIN DimProducts P ON OI.ProductID = P.ProductID
JOIN DimLocation L ON O.LocationID = L.LocationID;

SELECT * from vw_Sales_Performance_Summary


