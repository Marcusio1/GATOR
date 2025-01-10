--Graf 1: Rozdelenie tržieb podľa kategórií produktov
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

-- Graf 2: Rozdelenie tržieb podľa zamestnancov
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

-- Graf 3: Rozdelenie tržieb podľa prepravcov
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

--Graf 4: Rozdelenie tržieb podľa produktov
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

-- Graf 5: Rozdelenie tržieb podľa zamestnancov a zákazníkov
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


