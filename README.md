# **ETL proces datasetu Northwind**

Tento repozitár obsahuje implementáciu ETL procesu v Snowflake na analýzu dát z datasetu Northwind. Cieľom projektu je preskúmať obchodné procesy, vzťahy medzi zákazníkmi a dodávateľmi, ako aj analýzu predaja a objednávok. Tým sa vytvorí robustný model, ktorý umožní multidimenzionálnu analýzu a vizualizáciu kľúčových metrík.

---
## **1. Úvod a popis zdrojových dát**
Projekt sa zaoberá analýzou obchodných vzťahov medzi zákazníkmi, dodávateľmi a produktmi. Na základe týchto informácií sa identifikujú trendy v predaji, najpredávanejšie produkty a efektivita dodávateľov. Tento ETL proces štrukturalizuje surové dáta a pripraví ich pre analytické nástroje, aby mohli poskytnúť hodnotné poznatky.

Zdrojové dáta pochádzajú z datasetu Northwind, ktorý obsahuje nasledujúce hlavné tabuľky:
- Customers
- Orders
- Products
- Suppliers
- Order Details
- Categories
- Employees
- Shippers

Účelom ETL procesu bolo tieto dáta pripraviť, transformovať a sprístupniť pre viacdimenzionálnu analýzu.

---
### **1.1 Dátová architektúra**

### **ERD diagram**
Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na **entitno-relačnom diagrame (ERD)**:

<p align="center">
  <img src="https://github.com/Marcusio1/GATOR/blob/main/edr_schema.png" alt="ERD Schema">
  <br>
  <em>Obrázok 1 Entitno-relačná schéma Northwind</em>
</p>

---
## **2 Dimenzionálny model**

Navrhnutý bol **hviezdicový model (star schema)**, pre efektívnu analýzu kde centrálny bod predstavuje faktová tabuľka **`fact_ratings`**, ktorá je prepojená s nasledujúcimi dimenziami:
- **`dim_date`**: Obsahuje informácie o dátumoch a časových údajoch spojených s objednávkami.
- **`dim_customers`**: Obsahuje podrobné informácie o zákazníkoch, ktorí zadali objednávky.
- **`dim_employees`**: Obsahuje údaje o zamestnancoch, ktorí spracovávajú objednávky.
- **`dim_shippers`**:  Obsahuje údaje o prepravných spoločnostiach, ktoré doručujú objednávky.
- **`dim_products`**:  Obsahuje podrobné informácie o produktoch dostupných v ponuke.
- **`dim_categories`**: Obsahuje informácie o kategóriách produktov.
- **`dim_suppliers`**: Obsahuje údaje o dodávateľoch produktov.


Štruktúra hviezdicového modelu je znázornená na diagrame nižšie. Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami, čo zjednodušuje pochopenie a implementáciu modelu.

<p align="center">
  <img src="https://github.com/Marcusio1/GATOR/blob/main/star_schema.png" alt="Star Schema">
  <br>
  <em>Obrázok 2 Schéma hviezdy pre Northwind</em>
</p>

---
## **3. ETL proces v Snowflake**
Proces ETL zahŕňa tri hlavné kroky: `extrahovanie` '(Extract)', `transformácia` (Transform) a `načítanie` (Load). V prostredí Snowflake bol tento proces navrhnutý na spracovanie zdrojových dát zo staging vrstvy a ich prípravu do viacdimenzionálneho modelu vhodného na analytické účely a vizualizáciu.

---
### **3.1 Extract (Extrahovanie dát)**
Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do Snowflake prostredníctvom interného stage úložiska s názvom `my_stage`. V prvom kroku som nahral pôvodné dáta vo formáte csv. do interného stage úložiska, ktoré som vytvoril príkazom:

#### Príklad kódu:
```sql
CREATE STAGE my_stage;
```

Následne som vytvoril jednotlivé tabuľky ,zatiaľ neobsahujú žiadne dáta.
Príklad príkazu, ktorý som použil na tvorbu tabuľky Track:
```sql
CREATE TABLE Track (
TrackId INT PRIMARY KEY,
Name STRING,
AlbumId INT,
MediaTypeId INT,
GenreId INT,
Composer STRING,
Milliseconds INT,
Bytes INT,
UnitPrice DECIMAL(10, 2)
);
```
Týmto spôsobom som vytvoril aj zvyšné tabuľky.

V ďaľšom kroku som pomocou príkazu uvedeného nižšie vytvoril súborový formát s názvom my_file_format, ktorý slúži na importovanie dát vo forme CSV.

```sql
CREATE FILE FORMAT my_file_format
TYPE = 'CSV'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;
```

Následne som importoval dáta do staging tabuliek pomocou nasledujúceho príkazu:

```sql
COPY INTO categories
    FROM @my_stage/categories.csv
    FILE_FORMAT = (FORMAT_NAME = my_file_format);
```

V prípade nekonzistentných záznamov bol použitý parameter `ON_ERROR = 'CONTINUE'`, ktorý zabezpečil pokračovanie procesu bez prerušenia pri chybách.

---
### **3.2 Transfor (Transformácia dát)**

V tejto fáze boli dáta zo staging tabuliek očistené, transformované a doplnené o potrebné informácie. Cieľom bolo vytvoriť dimenzionálne tabuľky a faktovú tabuľku, ktoré umožnia efektívnu a prehľadnú analýzu.

Dimenzie boli navrhnuté na poskytovanie kontextu pre faktovú tabuľku. `Dim_Categories` obsahuje jedinečné záznamy kategórií z tabuľky categories, ktoré sú dimenziou v hviezdicovom modeli. Táto dimenzia poskytuje popisné informácie o kategóriách, ktoré môžu byť použité na analýzu faktov, napríklad v predajoch.
```sql
CREATE TABLE Dim_Categories AS
SELECT DISTINCT
    c.CategoryID AS CategoryID,
    c.CategoryName AS CategoryName,
    c.Description AS Description
FROM Categories c;
```

Dimenzia Dim_Customers je navrhnutá tak, aby uchovávala detailné informácie o zákazníkoch. Obsahuje údaje, ako sú jedinečný identifikátor zákazníka, jeho meno, kontaktné údaje (napr. kontakt, adresa, mesto, PSČ a krajina). Táto dimenzia umožňuje analýzu údajov na základe zákazníckych atribútov, ako sú geografická poloha, kontaktné osoby alebo segmenty zákazníkov.

Dimenzia Dim_Customers je klasifikovaná ako SCD Typ 0, čo znamená, že existujúce záznamy sú nemenné. Uchováva statické informácie o zákazníkoch, pričom sa nepripúšťa ich úprava.

Možné zmeny v SCD:
SCD Typ 1: Ak by bolo potrebné aktualizovať existujúce údaje (napríklad aktualizáciu adresy alebo kontaktného mena), klasifikácia by sa mohla zmeniť na SCD Typ 1, kde staré hodnoty budú prepísané novými.
SCD Typ 2: Pre prípad sledovania histórie zmien zákazníckych údajov by bolo možné prejsť na SCD Typ 2. V takom prípade by boli historické záznamy uchované s časovou pečiatkou alebo dodatočným indikátorom verzie.

```sql
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
```

Faktová tabuľka `Fact_Sales` je navrhnutá tak, aby uchovávala detailné údaje o predajoch vrátane objednávok, produktov, zákazníkov, zamestnancov, dodávateľov a kategórií. Obsahuje metriky, ako je počet predaných kusov, cena produktu a celková suma objednávky. Táto tabuľka je optimalizovaná na analýzu predajov a sledovanie výkonnosti obchodných procesov.

```sql
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

```

---
### **3.3 Load (Načítanie dát)**

Po úspešnom vytvorení dimenzií a faktovej tabuľky boli dáta nahraté do finálnej štruktúry. Na záver boli staging tabuľky odstránené, aby sa optimalizovalo využitie úložiska:

```sql
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS orderdetails;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS shippers;
DROP TABLE IF EXISTS suppliers;
```
ETL proces v Snowflake umožnil spracovanie pôvodných dát z `.csv` formátu do viacdimenzionálneho modelu typu hviezda. Tento proces zahŕňal čistenie, obohacovanie a reorganizáciu údajov. Výsledný model umožňuje analýzu čitateľských preferencií a správania používateľov, pričom poskytuje základ pre vizualizácie a reporty.

---
## **4 Vizualizácia dát**

Dashboard obsahuje `6 vizualizácií`, ktoré poskytujú základný prehľad o kľúčových metrikách a trendoch týkajúcich sa kníh, používateľov a hodnotení. Tieto vizualizácie odpovedajú na dôležité otázky a umožňujú lepšie pochopiť správanie používateľov a ich preferencie.

<p align="center">
  <img src="https://github.com/Marcusio1/GATOR/blob/main/Northwind_dashboard.png.png" alt="ERD Schema">
  <br>
  <em>Obrázok 3 Dashboard Northwind datasetu</em>
</p>

---
### **Graf 1: Rozdelenie tržieb podľa kategórií produktov**
Tento dotaz zobrazuje celkové tržby (TotalAmount) podľa kategórií produktov. Zoskupujeme tržby podľa názvu kategórie a zoradíme výsledky od najvyšších tržieb po najnižšie.

```sql
SELECT 
    c.CategoryName,
    SUM(fs.TotalAmount) AS TotalAmount
FROM 
    Fact_Sales fs
JOIN 
    Dim_Categories c ON fs.CategoryID = c.CategoryID
GROUP BY 
    c.CategoryName
ORDER BY 
    TotalAmount DESC;
```
---
### **Graf 2: Rozdelenie tržieb podľa zamestnancov**
Tento dotaz ukazuje, aké tržby (TotalAmount) generovali jednotliví zamestnanci. Zamestnanci sú zoradení podľa celkových tržieb, pričom najviac zarabajúci zamestnanci sú na začiatku.

```sql
SELECT 
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    SUM(fs.TotalAmount) AS TotalAmount
FROM 
    Fact_Sales fs
JOIN 
    Dim_Employees e ON fs.EmployeeID = e.EmployeeID
GROUP BY 
    EmployeeName
ORDER BY 
    TotalAmount DESC;
```
---
### **Graf 3: Rozdelenie tržieb podľa prepravcov**
Tento dotaz zobrazuje tržby (TotalAmount) podľa rôznych prepravcov, ktorí sa podieľajú na dodávkach. Výsledky sú zoradené podľa celkových tržieb od najvyšších po najnižšie.

```sql
SELECT 
    s.ShipperName,
    SUM(fs.TotalAmount) AS TotalAmount
FROM 
    Fact_Sales fs
JOIN 
    Dim_Shippers s ON fs.ShipperID = s.ShipperID
GROUP BY 
    s.ShipperName
ORDER BY 
    TotalAmount DESC;
```
---
### **Graf 4: Rozdelenie tržieb podľa produktov**
Tento dotaz zobrazuje celkové tržby (TotalAmount) generované jednotlivými produktmi. Produkty sú zoradené podľa tržieb v zostupnom poradí.

```sql
SELECT 
    p.ProductName,
    SUM(fs.TotalAmount) AS TotalAmount
FROM 
    Fact_Sales fs
JOIN 
    Dim_Products p ON fs.ProductID = p.ProductID
GROUP BY 
    p.ProductName
ORDER BY 
    TotalAmount DESC;
```
---
### **Graf 5: Rozdelenie tržieb podľa zamestnancov a zákazníkov**
Tento dotaz ukazuje celkové tržby (TotalAmount), ktoré vygenerovali rôzni zamestnanci pre rôznych zákazníkov. Výsledky sú zoradené podľa tržieb, pričom najväčšie tržby sú na vrchu.

```sql
SELECT 
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    cu.CustomerName,
    SUM(fs.TotalAmount) AS TotalAmount
FROM 
    Fact_Sales fs
JOIN 
    Dim_Employees e ON fs.EmployeeID = e.EmployeeID
JOIN 
    Dim_Customers cu ON fs.CustomerID = cu.CustomerID
GROUP BY 
    EmployeeName, cu.CustomerName
ORDER BY 
    TotalAmount DESC;
```

**Autor:** Marek Gendiar
