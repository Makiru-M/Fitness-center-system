-- ==============================================================================
-- СКРИПТ ПЕРЕВІРКИ ЦІЛІСНОСТІ ТА ЛОГІКИ ДАНИХ (FitnessClub IS)
-- Сформовано відповідно до задач у "IS structure.md"
-- Дата формування: 26.05.2026
-- ==============================================================================

-- 1. ДІАГНОСТИКА КЛІЄНТІВ (Задачі: M1, M3, M7, Cl3)
-- Об'єднує дані про клієнтів, їх абонементи, заморозки та медичні застереження.
-- Перевіряє зв'язки: Clients -> MedicalNotes, Sales -> ClientSubscriptions -> FreezingLogs.
SELECT 
    c.ID_Client,
    c.FullName AS Client_Name,
    COALESCE(mn.NotesText, 'Немає обмежень') AS Medical_Alert,
    cs.CurrentStatus AS Sub_Status,
    cs.EndDate AS Valid_Until,
    cs.RemainingFreezingDays AS Freeze_Left,
    COALESCE(fl.Reason, '—') AS Last_Freeze_Reason,
    CASE 
        WHEN cs.CurrentStatus = 'Frozen' AND (CURRENT_DATE BETWEEN fl.FreezeStartDate AND fl.FreezeEndDate) THEN 'Активна заморозка'
        WHEN cs.EndDate < CURRENT_DATE THEN 'Прострочено'
        ELSE 'В нормі'
    END AS Internal_Check
FROM Clients c
LEFT JOIN MedicalNotes mn ON c.ID_Client = mn.ID_Client
LEFT JOIN Sales s ON c.ID_Client = s.ID_Client AND s.ID_Item IN (SELECT ID_Item FROM PriceList WHERE Category = 'Membership')
LEFT JOIN ClientSubscriptions cs ON s.ID_Sale = cs.ID_Sale
LEFT JOIN FreezingLogs fl ON cs.ID_ClientSub = fl.ID_ClientSub
ORDER BY cs.EndDate DESC;


-- 2. ФІНАНСОВИЙ АНАЛІЗ ТА ЕФЕКТИВНІСТЬ ПРОМО (Задачі: D1, D9, D10)
-- Перевіряє коректність розрахунку цін, знижок та використання промокодів.
-- Перевіряє зв'язки: Sales -> PriceList -> AppliedPromo -> PromoCodes.
SELECT 
    pl.Category,
    COUNT(s.ID_Sale) AS Sales_Count,
    SUM(pl.Price) AS Full_Price_Total,
    SUM(s.SalePrice) AS Actual_Revenue,
    SUM(pl.Price - s.SalePrice) AS Total_Discounts,
    COUNT(ap.ID_Promo) AS Promo_Code_Usage
FROM Sales s
JOIN PriceList pl ON s.ID_Item = pl.ID_Item
LEFT JOIN AppliedPromo ap ON s.ID_Sale = ap.ID_Sale
GROUP BY pl.Category
ORDER BY Actual_Revenue DESC;


-- 3. КОМБІНОВАНИЙ РОЗКЛАД ТРЕНЕРІВ (Задачі: C1, D3, D11, D12)
-- Об'єднує два різних типи активностей (групові та персональні) в один звіт.
-- Перевіряє цілісність розкладу та статусів занять.
SELECT 
    st.FullName AS Staff_Name,
    'Group Class' AS Activity_Type,
    ct.TypeName || ' (' || h.HallName || ')' AS Description,
    gci.ClassDate AS Scheduled_Date,
    gci.ClassStatus AS Status,
    gci.ActualAttendance AS KPI_Result
FROM GroupClassInstances gci
JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
JOIN Coaches co ON gst.ID_Coach = co.ID_Coach
JOIN Staff st ON co.ID_Staff = st.ID_Staff
JOIN Halls h ON gst.ID_Hall = h.ID_Hall

UNION ALL

SELECT 
    st.FullName,
    'Personal Training',
    'Client: ' || c.FullName,
    pt.TrainingDateTime::DATE,
    pt.TrainingStatus,
    CASE WHEN pt.TrainingStatus = 'Completed' THEN 1 ELSE 0 END
FROM PersonalTrainings pt
JOIN Coaches co ON pt.ID_Coach = co.ID_Coach
JOIN Staff st ON co.ID_Staff = st.ID_Staff
JOIN Sales s ON pt.ID_Sale = s.ID_Sale
JOIN Clients c ON s.ID_Client = c.ID_Client
ORDER BY Scheduled_Date DESC;


-- 4. АУДИТ ЗМІН ТА СКАСУВАНЬ (Задачі: M8, C5, D6)
-- Перевіряє лог змін персональних тренувань.
-- Перевіряє зв'язки: PT_Changelog -> PT_TimeChangeDetails.
SELECT 
    pt.TrainingDateTime AS Original_Slot,
    cl.RequestType,
    cl.ChangeInitiator AS Responsible_Party,
    cl.Reason,
    COALESCE(tcd.NewDateTime::TEXT, 'Скасовано') AS Final_Resolution,
    cl.ChangeTimestamp AS Logged_At
FROM PT_Changelog cl
JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal
LEFT JOIN PT_TimeChangeDetails tcd ON cl.ID_PTLog = tcd.ID_PTLog
ORDER BY cl.ChangeTimestamp DESC;


-- 5. ЖУРНАЛ ВІДВІДУВАНОСТІ ТА ВАЛІДАЦІЯ ЧЕКІВ (Задачі: M4, D2, D4)
-- Показує, на основі якого саме продажу клієнт зайшов у зал.
-- Перевіряє зв'язок: Visits -> Sales -> PriceList.
SELECT 
    v.CheckInTime,
    c.FullName AS Client,
    h.HallName AS Hall_Accessed,
    pl.ItemName AS Service_Used,
    s.SaleDate AS Purchased_At
FROM Visits v
JOIN Sales s ON v.ID_Sale = s.ID_Sale
JOIN Clients c ON s.ID_Client = c.ID_Client
JOIN Halls h ON v.ID_Hall = h.ID_Hall
JOIN PriceList pl ON s.ID_Item = pl.ID_Item
ORDER BY v.CheckInTime DESC;
