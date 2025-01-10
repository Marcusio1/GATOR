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
Dáta zo zdrojového datasetu (formát `.csv`) boli najprv nahraté do Snowflake prostredníctvom interného stage úložiska s názvom `my_stage`. Stage v Snowflake slúži ako dočasné úložisko na import alebo export dát. Vytvorenie stage bolo zabezpečené príkazom:

#### Príklad kódu:
```sql
CREATE STAGE my_stage;
```
Do stage boli následne nahraté súbory obsahujúce údaje o knihách, používateľoch, hodnoteniach, zamestnaniach a úrovniach vzdelania. Dáta boli importované do staging tabuliek pomocou príkazu `COPY INTO`. Pre každú tabuľku sa použil podobný príkaz:

```sql
CREATE FILE FORMAT my_file_format
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;
```

V prípade nekonzistentných záznamov bol použitý parameter `ON_ERROR = 'CONTINUE'`, ktorý zabezpečil pokračovanie procesu bez prerušenia pri chybách.

---
### **3.2 Transfor (Transformácia dát)**

V tejto fáze boli dáta zo staging tabuliek vyčistené, transformované a obohatené. Hlavným cieľom bolo pripraviť dimenzie a faktovú tabuľku, ktoré umožnia jednoduchú a efektívnu analýzu.

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
  <img src="(https://github.com/Marcusio1/GATOR/blob/main/Northwind_dashboard.png.png" alt="ERD Schema">
  <br>
  <em>Obrázok 3 Dashboard Northwind datasetu</em>
</p>

---
### **Graf 1: Najviac hodnotené knihy (Top 10 kníh)**
Táto vizualizácia zobrazuje 10 kníh s najväčším počtom hodnotení. Umožňuje identifikovať najpopulárnejšie tituly medzi používateľmi. Zistíme napríklad, že kniha `Wild Animus` má výrazne viac hodnotení v porovnaní s ostatnými knihami. Tieto informácie môžu byť užitočné na odporúčanie kníh alebo marketingové kampane.

```sql
SELECT 
    b.title AS book_title,
    COUNT(f.fact_ratingID) AS total_ratings
FROM FACT_RATINGS f
JOIN DIM_BOOKS b ON f.bookID = b.dim_bookId
GROUP BY b.title
ORDER BY total_ratings DESC
LIMIT 10;
```
---
### **Graf 2: Rozdelenie hodnotení podľa pohlavia používateľov**
Graf znázorňuje rozdiely v počte hodnotení medzi mužmi a ženami. Z údajov je zrejmé, že ženy hodnotili knihy o niečo častejšie ako muži, no rozdiely sú minimálne a aktivita medzi pohlaviami je viac-menej vyrovnaná. Táto vizualizácia ukazuje, že obsah alebo kampane môžu byť efektívne zamerané na obe pohlavia bez potreby výrazného rozlišovania.

```sql
SELECT 
    u.gender,
    COUNT(f.fact_ratingID) AS total_ratings
FROM FACT_RATINGS f
JOIN DIM_USERS u ON f.userID = u.dim_userId
GROUP BY u.gender;
```
---
### **Graf 3: Trendy hodnotení kníh podľa rokov vydania (2000–2024)**
Graf ukazuje, ako sa priemerné hodnotenie kníh mení podľa roku ich vydania v období 2000–2024. Z vizualizácie je vidieť, že medzi rokmi 2000 a 2005 si knihy udržiavali stabilné priemerné hodnotenie. Po tomto období však nastal výrazný pokles priemerného hodnotenia. Od tohto bodu opäť postupne stúpajú a  po roku 2020, je tendencia, že knihy získavajú vyššie priemerné hodnotenia. Tento trend môže naznačovať zmenu kvality kníh, vývoj čitateľských preferencií alebo rozdiely v hodnotiacich kritériách používateľov.

```sql
SELECT 
    b.release_year AS year,
    AVG(f.rating) AS avg_rating
FROM FACT_RATINGS f
JOIN DIM_BOOKS b ON f.bookID = b.dim_bookId
WHERE b.release_year BETWEEN 2000 AND 2024
GROUP BY b.release_year
ORDER BY b.release_year;
```
---
### **Graf 4: Celková aktivita počas dní v týždni**
Tabuľka znázorňuje, ako sú hodnotenia rozdelené podľa jednotlivých dní v týždni. Z údajov vyplýva, že najväčšia aktivita je zaznamenaná cez víkendy (sobota a nedeľa) a počas dní na prelome pracovného týždňa a víkendu (piatok a pondelok). Tento trend naznačuje, že používatelia majú viac času na čítanie a hodnotenie kníh počas voľných dní.

```sql
SELECT 
    d.dayOfWeekAsString AS day,
    COUNT(f.fact_ratingID) AS total_ratings
FROM FACT_RATINGS f
JOIN DIM_DATE d ON f.dateID = d.dim_dateID
GROUP BY d.dayOfWeekAsString
ORDER BY total_ratings DESC;
```
---
### **Graf 5: Počet hodnotení podľa povolaní**
Tento graf  poskytuje informácie o počte hodnotení podľa povolaní používateľov. Umožňuje analyzovať, ktoré profesijné skupiny sú najviac aktívne pri hodnotení kníh a ako môžu byť tieto skupiny zacielené pri vytváraní personalizovaných odporúčaní. Z údajov je zrejmé, že najaktívnejšími profesijnými skupinami sú `Marketing Specialists` a `Librarians`, s viac ako 1 miliónom hodnotení. 

```sql
SELECT 
    u.occupation AS occupation,
    COUNT(f.fact_ratingID) AS total_ratings
FROM FACT_RATINGS f
JOIN DIM_USERS u ON f.userID = u.dim_userId
GROUP BY u.occupation
ORDER BY total_ratings DESC
LIMIT 10;
```
---
### **Graf 6: Aktivita používateľov počas dňa podľa vekových kategórií**
Tento stĺpcový graf ukazuje, ako sa aktivita používateľov mení počas dňa (dopoludnia vs. popoludnia) a ako sa líši medzi rôznymi vekovými skupinami. Z grafu vyplýva, že používatelia vo vekovej kategórii `55+` sú aktívni rovnomerne počas celého dňa, zatiaľ čo ostatné vekové skupiny vykazujú výrazne nižšiu aktivitu a majú obmedzený čas na hodnotenie, čo môže súvisieť s pracovnými povinnosťami. Tieto informácie môžu pomôcť lepšie zacieliť obsah a plánovať aktivity pre rôzne vekové kategórie.
```sql
SELECT 
    t.ampm AS time_period,
    u.age_group AS age_group,
    COUNT(f.fact_ratingID) AS total_ratings
FROM FACT_RATINGS f
JOIN DIM_TIME t ON f.timeID = t.dim_timeID
JOIN DIM_USERS u ON f.userID = u.dim_userId
GROUP BY t.ampm, u.age_group
ORDER BY time_period, total_ratings DESC;

```

Dashboard poskytuje komplexný pohľad na dáta, pričom zodpovedá dôležité otázky týkajúce sa čitateľských preferencií a správania používateľov. Vizualizácie umožňujú jednoduchú interpretáciu dát a môžu byť využité na optimalizáciu odporúčacích systémov, marketingových stratégií a knižničných služieb.

---

**Autor:** Marek Gendiar
