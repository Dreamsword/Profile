-- CREATE A DATABASE
CREATE DATABASE Sales ON ( NAME = Sales_dat,
FILENAME = 'C:\SQL\SqLData\sales.mdf', 
SIZE =  10, MAXSIZE = 50, FILEGROWTH = 5 )
LOG ON ( NAME = Sales_log,
FILENAME = 'C:\SQL\SQLLogs\saleslog.lds',
SIZE = 5MB, MAXSIZE = 25MB, FILEGROWTH = 5MB ) ;

USE Sales
GO

-- CREATE NEW TABLE
CREATE TABLE dbo.Products1
(
	ProductID int NULL,
	ProductName varchar(20) NULL,
	UnitPrice money NULL,
	ProductDescription varchar(50) NULL
);

-- CHANGE THE NAME OF A DATABASE
ALTER DATABASE Sales
MODIFY NAME = SalesForcast ;

-- DELETE A DATABASE (Disconnect from DATABASE first)
USE master			-- Add to disconnect from DATABASE
GO
DROP DATABASE SalesForcast
GO

USE AdventureWorks2012
GO

--ALL COLUMNS AND ROWS (TABLE DUMP)
SELECT * FROM HumanResources.Employee

--SPECIFIC COLUMNS IDENTIFIED. 'WHERE' DETERMINES WHAT ROWS RETURNED
SELECT BusinessEntityID, JobTitle, Gender
	FROM HumanResources.Employee
	WHERE BusinessEntityID <= 50

--USING MULTIPLE 'WHERE' PARAMETERS WITH THE 'AND'
SELECT BusinessEntityID, JobTitle, Gender, HireDate, VacationHours
	FROM HumanResources.Employee
	WHERE JobTitle = 'Design Engineer' AND Gender = 'F' AND HireDate >= '2000-JAN-01'
	
--USING MULTIPLE 'WHERE' PARAMETERS WITH THE 'OR'
SELECT BusinessEntityID, JobTitle, VacationHours
	FROM HumanResources.Employee
	WHERE VacationHours > 80 OR BusinessEntityID <= 50

--USING THE 'BETWEEN' CLAUSE TO SPECIFY WHAT ROWS ARE RETURNED
SELECT BusinessEntityID, JobTitle, VacationHours
	FROM HumanResources.Employee
	WHERE VacationHours BETWEEN 75 AND 100

--SORTING YOUR RESULTS USING THE 'ORDER BY'
SELECT BusinessEntityID, JobTitle, VacationHours
	FROM HumanResources.Employee
	WHERE VacationHours BETWEEN 75 AND 100
	ORDER BY VacationHours

--SORTING RESULTS USING THE 'ORDER BY' AND THE 'DESC' CLAUSE
SELECT BusinessEntityID, JobTitle, VacationHours
	FROM HumanResources.Employee
	WHERE VacationHours BETWEEN 75 AND 100
	ORDER BY VacationHours DESC

--USING THE 'NOT' CLAUSE TO PREVENT ITEMS FROM BEING RETURNED
SELECT BusinessEntityID, JobTitle, Gender
	FROM HumanResources.Employee
	WHERE NOT Gender = 'M'

--COMBINING DATA FROM MULTIPLE TABLES
SELECT BusinessEntityID, JobTitle, HireDate
	FROM HumanResources.Employee
	WHERE JobTitle = 'Design Engineer'
	UNION
	SELECT BusinessEntityID, JobTitle, HireDate
	FROM HumanResources.Employee
	WHERE HireDate BETWEEN '2005-01-01' AND '2005-12-31'

--RETURNING DISTINCT VALUES FROM THE LEFT QUERY THAT ARE NOT FOUND IN THE RIGHT QUERY
SELECT ProductID
	FROM Production.Product
	EXCEPT
	SELECT ProductID
	FROM Production.WorkOrder ;

--RETURNING DISTINCT VALUES RETURNED BY BOTH QUERIES
SELECT ProductID
	FROM Production.Product
	INTERSECT
	SELECT ProductID
	FROM Production.WorkOrder ;

--AGGREGATE FUNCTION SAMPLE QUERY
SELECT COUNT (DISTINCT SalesOrderID) AS UniqueOrders,
	AVG(UnitPrice) AS Avg_UnitPrice,
	MIN(OrderQty) AS Min_OrderQty,
	MAX(LineTotal) AS Max_LineTotal
	FROM Sales.SalesOrderDetail ;

--VIEW WHAT IS CURRENTLY IN THE UNITMEASURE TABLE
SELECT * FROM Production.UnitMeasure

--ADD A SINGLE ROW TO THE UNITMEASURE TABLE
INSERT INTO Production.UnitMeasure
 VALUES ('FT', 'Feet', GetDate()) ;

 --ADD MULTIPLE ROWS TO A TABLE USING AN 'INSERT' STATEMENT
 INSERT INTO Production.UnitMeasure
	VALUES ('FT2', 'Square Foot', GetDate()),
		   ('M2', 'Square Miles', GetDate()),
		   ('Y2', 'Square Yards', GetDate());

--CHECK FOR ROWS ADDED
SELECT * FROM Production.UnitMeasure

--UPDATE A ROW THAT HAS INCORRECT DATA
UPDATE Production.UnitMeasure
SET Name = 'Square Feet'
WHERE Production.UnitMeasure.UnitMeasureCode = 'FT2'

--REMOVE A ROW FROM THE TABLE
DELETE FROM Production.UnitMeasure
	WHERE Production.UnitMeasure.UnitMeasureCode = 'FT'

--EXAMPLE OF A TRIGGER
CREATE TRIGGER InsertSuccess
ON Production.UnitMeasure
AFTER UPDATE
AS RAISERROR ('UnitMeasure Successfully Added' , 16, 10);
GO

--MCSA SQL Query Exam 461

USE AdventureWorks2012
GO

--Display all distinct StoreID and their TerritoryID sorted by StoreID
SELECT DISTINCT StoreID, TerritoryID
FROM Sales.Customer
ORDER BY StoreID

--Specifying column aliases using AS
SELECT SalesOrderID, UnitPrice, OrderQty AS Quantity
FROM Sales.SalesOrderDetail;

--Example of the CASE expression
SELECT ProductID, Name, ProductSubCategoryID,
	CASE ProductSubCategoryID
		WHEN 1 THEN 'Beverages'
		ElSE 'Unknown Category'
	END
FROM Production.Product

--Sample INNER JOIN statement
SELECT SOH.SalesOrderID,
			SOH.OrderDate,
			SOD.ProductID,
			SOD.UnitPrice,
			SOD.OrderQty
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN Sales.SalesOrderDetail AS SOD
ON SOH.SalesOrderID = SOD.SalesOrderID;

--Sample LEFT OUTER JOIN to return all customers that havn't placed an order
SELECT CUST.CustomerID, CUST.StoreID, ORD.SalesOrderID, ORD.OrderDate
FROM Sales.Customer AS CUST
LEFT OUTER JOIN Sales.SalesOrderHeader AS ORD
ON CUST.CustomerID = ORD.CustomerID
WHERE ORD.SalesOrderID IS NULL;

--Uses several aggregate functions to return summary data
SELECT COUNT (DISTINCT SalesOrderID) AS UniqueOrders,
AVG(UnitPrice) AS Avg_UnitPrice,
MIN(OrderQty) AS Min_OrderQty,
MAX(LineTotal) AS Max_LineTotal
FROM Sales.SalesOrderDetail;

--Returns all customers and unique customers for a sales person per year
SELECT SalesPersonID, YEAR(OrderDate) AS OrderYear,
COUNT(CustomerID) AS All_Custs,
COUNT(DISTINCT CustomerID) AS Unique_Custs
FROM Sales.SalesOrderHeader
GROUP BY SalesPersonID, YEAR(OrderDate)
ORDER BY SalesPersonID;

--Returns a count of all customers and sorts results by sales person
SELECT SalesPersonID, COUNT(*) AS Cnt
FROM Sales.SalesOrderHeader
GROUP BY SalesPersonID
ORDER BY SalesPersonID;

--Using the GROUP BY and HAVING clause to display number of orders by customer
SELECT CustomerID, COUNT(*) AS Count_Orders
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 10
ORDER BY Count_Orders DESC;

--Returns information about the last order submitted
SELECT SalesOrderID, ProductID, UnitPrice, OrderQTY
FROM Sales.SalesOrderDetail
WHERE SalesOrderID =
	(SELECT MAX(SalesOrderID) AS LastOrder
	 FROM Sales.SalesOrderHeader);

--Returns all sales orders for each customer in territory 10
SELECT CustomerID, SalesOrderID, TerritoryID
FROM Sales.SalesOrderHeader
WHERE CustomerID IN
	(SELECT CustomerID
	 FROM Sales.Customer
	 WHERE TerritoryID = 10);

--Displays the Person ID for every customer who has placed an order
SELECT CustomerID, PersonID
FROM Sales.Customer AS Cust
WHERE EXISTS
	(SELECT *
	 FROM Sales.SalesOrderHeader AS Ord
	 WHERE Cust.CustomerID = Ord.CustomerID);

