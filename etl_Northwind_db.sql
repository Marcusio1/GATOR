-- Vytvorenie stage pre nahrávanie .csv súborov
CREATE STAGE my_stage;

-- Vytvorenie tabuľky categories
CREATE TABLE categories (
    CategoryID INT NOT NULL,         -- Primárny kľúč kategórie
    CategoryName STRING NOT NULL,   -- Názov kategórie
    Description STRING,             -- Popis kategórie
    PRIMARY KEY (CategoryID)        -- Definovanie primárneho kľúča
);

-- Vytvorenie tabuľky customers
CREATE TABLE customers (
    CustomerID INT NOT NULL,         -- Primárny kľúč zákazníka
    CustomerName STRING NOT NULL,   -- Názov zákazníka
    ContactName STRING,             -- Kontaktné meno
    Address STRING,                 -- Adresa
    City STRING,                    -- Mesto
    PostalCode STRING,              -- PSČ
    Country STRING,                 -- Krajina
    PRIMARY KEY (CustomerID)        -- Definovanie primárneho kľúča
);

-- Vytvorenie tabuľky shippers
CREATE TABLE shippers (
    ShipperID INT NOT NULL,          -- Primárny kľúč dopravcu
    ShipperName STRING NOT NULL,    -- Názov dopravcu
    Phone STRING,                   -- Telefónne číslo
    PRIMARY KEY (ShipperID)         -- Definovanie primárneho kľúča
);

-- Vytvorenie tabuľky suppliers
CREATE TABLE suppliers (
    SupplierID INT NOT NULL,         -- Primárny kľúč dodávateľa
    SupplierName STRING NOT NULL,   -- Názov dodávateľa
    ContactName STRING,             -- Kontaktné meno
    Address STRING,                 -- Adresa
    City STRING,                    -- Mesto
    PostalCode STRING,              -- PSČ
    Country STRING,                 -- Krajina
    Phone STRING,                   -- Telefónne číslo
    PRIMARY KEY (SupplierID)        -- Definovanie primárneho kľúča
);

-- Vytvorenie tabuľky products
CREATE TABLE products (
    ProductID INT NOT NULL,          -- Primárny kľúč produktu
    ProductName STRING NOT NULL,    -- Názov produktu
    SupplierID INT,                 -- ID dodávateľa (FK)
    CategoryID INT,                 -- ID kategórie (FK)
    Unit STRING,                    -- Jednotka
    Price DECIMAL(10, 2),           -- Cena produktu
    PRIMARY KEY (ProductID)         -- Definovanie primárneho kľúča
);

-- Vytvorenie tabuľky orderdetails
CREATE TABLE orderdetails (
    OrderDetailID INT NOT NULL,     -- Primárny kľúč detailov objednávky
    OrderID INT NOT NULL,           -- ID objednávky (FK)
    ProductID INT NOT NULL,         -- ID produktu (FK)
    Quantity INT NOT NULL,          -- Množstvo produktu
    PRIMARY KEY (OrderDetailID)     -- Definovanie primárneho kľúča
);

-- Vytvorenie tabuľky orders
CREATE TABLE orders (
    OrderID INT NOT NULL,           -- Primárny kľúč objednávky
    CustomerID INT NOT NULL,        -- ID zákazníka (FK)
    EmployeeID INT,                 -- ID zamestnanca (FK)
    OrderDate DATE,                 -- Dátum objednávky
    ShipperID INT,                  -- ID dopravcu (FK)
    PRIMARY KEY (OrderID),          -- Definovanie primárneho kľúča
);

-- Vytvorenie tabuľky employees
CREATE TABLE employees (
    EmployeeID INT NOT NULL,        -- Primárny kľúč zamestnanca
    LastName STRING NOT NULL,       -- Priezvisko
    FirstName STRING NOT NULL,      -- Meno
    BirthDate DATE,                 -- Dátum narodenia
    Photo STRING,                   -- Odkaz na fotografiu
    Notes STRING,                   -- Poznámky
    PRIMARY KEY (EmployeeID)        -- Definovanie primárneho kľúča
);

-- Vytvorenie formátu súborov
CREATE FILE FORMAT my_file_format
    TYPE = 'CSV'                    -- Typ súboru: CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"' -- Možné ohraničenie polí
    SKIP_HEADER = 1                 -- Preskočenie hlavičky
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE; -- Povoliť rozdiely v počte stĺpcov

-- Načítanie dát zo staging oblasti do staging tabuliek
COPY INTO categories
    FROM @my_stage/categories.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

COPY INTO customers
    FROM @my_stage/customers.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

COPY INTO employees
    FROM @my_stage/employees.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

COPY INTO orderdetails
    FROM @my_stage/orderdetails.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

COPY INTO orders
    FROM @my_stage/orders.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

COPY INTO products
    FROM @my_stage/products.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

COPY INTO shippers
    FROM @my_stage/shippers.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

COPY INTO suppliers
    FROM @my_stage/suppliers.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);

-- Transformácia a vytvorenie dimenzií
CREATE TABLE Dim_Categories AS
SELECT DISTINCT
    c.CategoryID AS CategoryID,
    c.CategoryName AS CategoryName,
    c.Description AS Description
FROM Categories c;

CREATE TABLE Dim_Customers AS
SELECT DISTINCT
    c.CustomerID AS CustomerID,
    c.CustomerName AS CustomerName,
    c.ContactName AS ContactName,
    c.Address AS Address,
    c.City AS City,
    c.PostalCode AS PostalCode,
    c.Country AS Country
FROM Customers c;

CREATE TABLE Dim_Shippers AS
SELECT DISTINCT
    s.ShipperID AS ShipperID,
    s.ShipperName AS ShipperName,
    s.Phone AS Phone
FROM Shippers s;

CREATE TABLE Dim_Suppliers AS
SELECT DISTINCT
    s.SupplierID AS SupplierID,
    s.SupplierName AS SupplierName,
    s.ContactName AS ContactName,
    s.Address AS Address,
    s.City AS City,
    s.PostalCode AS PostalCode,
    s.Country AS Country,
    s.Phone AS Phone
FROM Suppliers s;

CREATE TABLE Dim_Products AS
SELECT DISTINCT
    p.ProductID AS ProductID,
    p.ProductName AS ProductName,
    p.SupplierID AS SupplierID,
    p.CategoryID AS CategoryID,
    p.Unit AS Unit,
    p.Price AS Price
FROM Products p;

CREATE TABLE Dim_OrderDetails AS
SELECT DISTINCT
    od.OrderDetailID AS OrderDetailID,
    od.OrderID AS OrderID,
    od.ProductID AS ProductID,
    od.Quantity AS Quantity
FROM OrderDetails od;

CREATE TABLE Dim_Orders AS
SELECT DISTINCT
    o.OrderID AS OrderID,
    o.CustomerID AS CustomerID,
    o.EmployeeID AS EmployeeID,
    o.OrderDate AS OrderDate,
    o.ShipperID AS ShipperID
FROM Orders o;

CREATE TABLE Dim_Employees AS
SELECT DISTINCT
    e.EmployeeID AS EmployeeID,
    e.LastName AS LastName,
    e.FirstName AS FirstName,
    e.BirthDate AS BirthDate,
    e.Photo AS Photo,
    e.Notes AS Notes
FROM Employees e;

-- Vytvorenie faktovej tabuľky Fact_Sales
CREATE TABLE Fact_Sales AS
SELECT DISTINCT
    o.OrderID AS OrderID,
    o.CustomerID AS CustomerID,
    o.EmployeeID AS EmployeeID,
    o.OrderDate AS OrderDate,
    od.OrderDetailID AS OrderDetailID,
    od.ProductID AS ProductID,
    od.Quantity AS Quantity,
    p.Price AS Price,
    (od.Quantity * p.Price) AS TotalAmount,
    s.ShipperID AS ShipperID,
    c.CustomerID AS CustomerKey,
    e.EmployeeID AS EmployeeKey,
    ps.SupplierID AS SupplierID,
    cat.CategoryID AS CategoryID
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Shippers s ON o.ShipperID = s.ShipperID
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN Suppliers ps ON p.SupplierID = ps.SupplierID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
JOIN Customers c ON o.CustomerID = c.CustomerID;

-- Odstránenie staging tabuliek po ETL procese
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS orderdetails;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS shippers;
DROP TABLE IF EXISTS suppliers;
