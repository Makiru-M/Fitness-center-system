-- ------------------------------------------------------------------------------
-- 8. ПРЕДСТАВЛЕННЯ (VIEWS) ДЛЯ ЗВІТІВ ТА АНАЛІТИКИ
-- ------------------------------------------------------------------------------

-- 8.1. Статистика тренерів та їхньої активності (Lab_4 / Analytical)
CREATE OR REPLACE VIEW v_CoachStats AS
SELECT 
    c.ID_Coach,
    s.FullName AS CoachName,
    (
        SELECT COUNT(gci.ID_Instance)
        FROM GroupScheduleTemplates gst
        JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template
        WHERE gst.ID_Coach = c.ID_Coach 
          AND gci.ClassStatus IN ('Completed', 'Attended')
    ) AS GroupClassesCount,
    (
        SELECT ROUND(COALESCE(AVG(gci.ActualAttendance), 0), 2)
        FROM GroupScheduleTemplates gst
        JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template
        WHERE gst.ID_Coach = c.ID_Coach 
          AND gci.ClassStatus IN ('Completed', 'Attended')
    ) AS AvgGroupSize,
    (
        SELECT COUNT(DISTINCT sl.ID_Client)
        FROM PersonalTrainings pt
        JOIN Sales sl ON pt.ID_Sale = sl.ID_Sale
        WHERE pt.ID_Coach = c.ID_Coach 
          AND pt.TrainingStatus IN ('Completed', 'Attended')
    ) AS IndividualClientsCount
FROM Coaches c
JOIN Staff s ON c.ID_Staff = s.ID_Staff;

-- 8.2. Статистика завантаження залів клубу (Lab_3 / Analytical)
CREATE OR REPLACE VIEW v_HallLoadStats AS
SELECT 
    h.ID_Hall,
    h.HallName,
    h.MaxCapacity,
    h.IsActive,
    COALESCE(COUNT(v.ID_Visit), 0) AS TotalVisitsCount,
    (
        SELECT COUNT(pt.ID_Personal)
        FROM PersonalTrainings pt
        WHERE pt.ID_Hall = h.ID_Hall
    ) AS PersonalTrainingsCount,
    (
        SELECT COUNT(gci.ID_Instance)
        FROM GroupScheduleTemplates gst
        JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template
        WHERE gst.ID_Hall = h.ID_Hall
    ) AS GroupClassesCount
FROM Halls h
LEFT JOIN Visits v ON h.ID_Hall = v.ID_Hall
GROUP BY h.ID_Hall, h.HallName, h.MaxCapacity, h.IsActive;

-- 8.3. Популярність послуг та тарифів (Analytical Query 2)
CREATE OR REPLACE VIEW v_PopularServices AS
SELECT 
    pl.ID_Item,
    pl.ItemName,
    pl.Category,
    pl.Price,
    COUNT(s.ID_Sale) AS SalesCount,
    COALESCE(SUM(s.SalePrice), 0.00) AS TotalRevenue,
    COALESCE(SUM(CASE WHEN s.ID_Sale IS NOT NULL THEN pl.Price - s.SalePrice ELSE 0 END), 0.00) AS TotalDiscountGiven,
    COUNT(ap.ID_Promo) AS PromoUsagesCount
FROM PriceList pl
LEFT JOIN Sales s ON pl.ID_Item = s.ID_Item
LEFT JOIN AppliedPromo ap ON s.ID_Sale = ap.ID_Sale
GROUP BY pl.ID_Item, pl.ItemName, pl.Category, pl.Price;

-- 8.4. Фінансовий помісячний звіт / виручка (Lab_4 / Analytical)
CREATE OR REPLACE VIEW v_FinancialSummary AS
WITH ExtractedSalesDates AS (
    SELECT 
        EXTRACT(YEAR FROM SaleDate)::INT AS SalesYear,
        EXTRACT(MONTH FROM SaleDate)::INT AS SalesMonth,
        SalePrice
    FROM Sales
),
Years AS (
    SELECT DISTINCT SalesYear 
    FROM ExtractedSalesDates
),
AllMonths AS (
    SELECT 
        y.SalesYear,
        m.SalesMonth
    FROM Years y
    CROSS JOIN generate_series(1, 12) AS m(SalesMonth)
),
MonthlyRevenue AS (
    SELECT 
        am.SalesYear,
        am.SalesMonth,
        COALESCE(SUM(esd.SalePrice), 0.00) AS TotalRevenue
    FROM AllMonths am
    LEFT JOIN ExtractedSalesDates esd 
        ON am.SalesYear = esd.SalesYear AND am.SalesMonth = esd.SalesMonth
    GROUP BY am.SalesYear, am.SalesMonth
)
SELECT 
    SalesYear,
    SalesMonth,
    TotalRevenue,
    COALESCE(TotalRevenue - LAG(TotalRevenue) OVER (ORDER BY SalesYear, SalesMonth), 0.00) AS MonthOverMonthDiff
FROM MonthlyRevenue
ORDER BY SalesYear, SalesMonth;

-- 8.5. Частка групових клієнтів, які також беруть індивідуальні тренування (з Lab_4.sql)
CREATE OR REPLACE VIEW v_GroupIndividualClientsShare AS
WITH GroupClients AS (
    SELECT DISTINCT
        gst.ID_Template,
        ct.TypeName,
        gst.DayOfWeek,
        gst.StartTime,
        sl.ID_Client
    FROM GroupScheduleTemplates gst
    JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
    JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template
    JOIN GroupClassBookings gcb ON gci.ID_Instance = gcb.ID_Instance
    JOIN Sales sl ON gcb.ID_Sale = sl.ID_Sale
),
PersonalClients AS (
    SELECT DISTINCT sl.ID_Client
    FROM PersonalTrainings pt
    JOIN Sales sl ON pt.ID_Sale = sl.ID_Sale
)
SELECT 
    gc.ID_Template,
    gc.TypeName AS GroupType,
    gc.DayOfWeek,
    gc.StartTime,
    COUNT(gc.ID_Client) AS TotalGroupClients,
    COUNT(pc.ID_Client) AS ClientsWithPersonalTrainings,
    CASE 
        WHEN COUNT(gc.ID_Client) = 0 THEN 0
        ELSE ROUND((COUNT(pc.ID_Client)::NUMERIC / COUNT(gc.ID_Client)) * 100, 2)
    END AS PersonalTrainingSharePercent
FROM GroupClients gc
LEFT JOIN PersonalClients pc ON gc.ID_Client = pc.ID_Client
GROUP BY gc.ID_Template, gc.TypeName, gc.DayOfWeek, gc.StartTime;

-- Права доступу до аналітичних представлень
GRANT SELECT ON v_CoachStats TO director_role, manager_role;
GRANT SELECT ON v_HallLoadStats TO director_role, manager_role;
GRANT SELECT ON v_PopularServices TO director_role, manager_role;
GRANT SELECT ON v_FinancialSummary TO director_role, manager_role;
GRANT SELECT ON v_GroupIndividualClientsShare TO director_role, manager_role;
