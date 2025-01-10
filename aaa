-- Vytvorenie staging úložiska pre nahrávanie dátových súborov
CREATE STAGE my_stage;

-- Vytvorenie tabuľky kategórií
CREATE TABLE categories (
    CategoryID INT NOT NULL,         -- Primárny kľúč kategórie
    CategoryName STRING NOT NULL,    -- Názov kategórie
    Description STRING,              -- Popis kategórie
    PRIMARY KEY (CategoryID)         -- Definícia primárneho kľúča
);

-- Vytvorenie tabuľky zákazníkov
CREATE TABLE customers (
    CustomerID INT NOT NULL,         -- Primárny kľúč zákazníka
    CustomerName STRING NOT NULL,    -- Meno zákazníka
    ContactName STRING,              -- Kontaktná osoba
    Address STRING,                  -- Adresa
    City STRING,                     -- Mesto
    PostalCode STRING,               -- PSČ
    Country STRING,                  -- Krajina
    PRIMARY KEY (CustomerID)         -- Definícia primárneho kľúča
);

-- Vytvorenie tabuľky prepravcov
CREATE TABLE shippers (
    ShipperID INT NOT NULL,          -- Primárny kľúč prepravcu
    ShipperName STRING NOT NULL,     -- Názov prepravcu
    Phone STRING,                    -- Telefónne číslo prepravcu
    PRIMARY KEY (ShipperID)          -- Definícia primárneho kľúča
);

-- Vytvorenie tabuľky dodávateľov
CREATE TABLE suppliers (
    SupplierID INT NOT NULL,         -- Primárny kľúč dodávateľa
    SupplierName STRING NOT NULL,    -- Názov dodávateľa
    ContactName STRING,              -- Kontaktná osoba
    Address STRING,                  -- Adresa
    City STRING,                     -- Mesto
    PostalCode STRING,               -- PSČ
    Country STRING,                  -- Krajina
    Phone STRING,                    -- Telefónne číslo
    PRIMARY KEY (SupplierID)         -- Definícia primárneho kľúča
);

-- Vytvorenie tabuľky produktov
CREATE TABLE products (
    ProductID INT NOT NULL,          -- Primárny kľúč produktu
    ProductName STRING NOT NULL,     -- Názov produktu
    SupplierID INT,                  -- ID dodávateľa
    CategoryID INT,                  -- ID kategórie
    Unit STRING,                     -- Jednotka
    Price DECIMAL(10, 2),            -- Cena produktu
    PRIMARY KEY (ProductID)          -- Definícia primárneho kľúča
);

-- Vytvorenie tabuľky detailov objednávok
CREATE TABLE orderdetails (
    OrderDetailID INT NOT NULL,      -- Primárny kľúč detailu objednávky
    OrderID INT NOT NULL,            -- ID objednávky
    ProductID INT NOT NULL,          -- ID produktu
    Quantity INT NOT NULL,           -- Množstvo objednaného produktu
    PRIMARY KEY (OrderDetailID)      -- Definícia primárneho kľúča
);

-- Vytvorenie tabuľky objednávok
CREATE TABLE orders (
    OrderID INT NOT NULL,            -- Primárny kľúč objednávky
    CustomerID INT NOT NULL,         -- ID zákazníka
    EmployeeID INT,                  -- ID zamestnanca, ktorý objednávku spracoval
    OrderDate DATE,                  -- Dátum objednávky
    ShipperID INT,                   -- ID prepravcu
    PRIMARY KEY (OrderID),           -- Definícia primárneho kľúča
    FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),  -- Väzba na zákazníkov
    FOREIGN KEY (ShipperID) REFERENCES shippers(ShipperID)      -- Väzba na prepravcov
);

-- Vytvorenie tabuľky zamestnancov
CREATE TABLE employees (
    EmployeeID INT NOT NULL,         -- Primárny kľúč zamestnanca
    LastName STRING NOT NULL,        -- Priezvisko
    FirstName STRING NOT NULL,       -- Krstné meno
    BirthDate DATE,                  -- Dátum narodenia
    Photo STRING,                    -- URL k fotke zamestnanca
    Notes STRING,                    -- Poznámky o zamestnancovi
    PRIMARY KEY (EmployeeID)         -- Definícia primárneho kľúča
);

-- Definovanie formátu pre nahrávanie CSV súborov
CREATE FILE FORMAT my_file_format
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'   -- Pole uzavreté v úvodzovkách
    SKIP_HEADER = 1                      -- Preskočiť hlavičku v súbore
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;  -- Povoliť chyby pri nezhodách v počte stĺpcov

-- Nahrávanie údajov do staging tabuliek
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

-- Dimenzionálne a faktové tabuľky nasledujú...
