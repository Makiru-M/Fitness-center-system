-- ------------------------------------------------------------------------------
-- 8. ПРЕДСТАВЛЕННЯ (VIEWS) ДЛЯ ЗВІТІВ ТА АНАЛІТИКИ
-- ------------------------------------------------------------------------------

-- 8.1. Звіт відвідуваності та завантаженості залів (D2: getAttendanceReport)
CREATE OR REPLACE VIEW v_AttendanceReport AS
SELECT 
    h.HallName,
    h.MaxCapacity,
    COUNT(v.ID_Visit) AS TotalVisits,
    COUNT(DISTINCT s.ID_Client) AS UniqueClients,
    COALESCE(
        LPAD(MODE() WITHIN GROUP (ORDER BY EXTRACT(HOUR FROM v.CheckInTime)::INT)::TEXT, 2, '0') || ':00 - ' || 
        LPAD((MODE() WITHIN GROUP (ORDER BY EXTRACT(HOUR FROM v.CheckInTime)::INT) + 1)::TEXT, 2, '0') || ':00',
        '—'
    ) AS PeakHours,
    ROUND(LEAST(100.0, (COUNT(v.ID_Visit)::NUMERIC / NULLIF(h.MaxCapacity, 0)) * 100), 1) AS OccupancyPercent
FROM Halls h
LEFT JOIN Visits v ON h.ID_Hall = v.ID_Hall
LEFT JOIN Sales s ON v.ID_Sale = s.ID_Sale
WHERE (h.IsActive IS NULL OR h.IsActive = TRUE)
GROUP BY h.ID_Hall, h.HallName, h.MaxCapacity
ORDER BY TotalVisits DESC, h.HallName ASC;

-- 8.2. Рейтинг ефективності та популярності тренерів (D3: getCoachPopularity)
CREATE OR REPLACE VIEW v_CoachPerformance AS
WITH GroupStats AS (
    SELECT 
        gst.ID_Coach,
        COUNT(gci.ID_Instance) AS GroupClassesCount,
        ROUND(COALESCE(AVG(gci.ActualAttendance), 0), 2) AS AvgGroupSize
    FROM GroupScheduleTemplates gst
    JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template
    WHERE gci.ClassStatus IN ('Completed', 'Attended')
    GROUP BY gst.ID_Coach
),
PersonalStats AS (
    SELECT 
        pt.ID_Coach,
        COUNT(DISTINCT sl.ID_Client) AS IndividualClientsCount,
        COUNT(pt.ID_Personal) AS CompletedPersonalClassesCount
    FROM PersonalTrainings pt
    JOIN Sales sl ON pt.ID_Sale = sl.ID_Sale
    WHERE pt.TrainingStatus IN ('Completed', 'Attended')
    GROUP BY pt.ID_Coach
),
CoachStats AS (
    SELECT 
        c.ID_Coach AS CoachId,
        s.FullName,
        sp.SpecName,
        COALESCE(gs.GroupClassesCount, 0) AS GroupClassesCount,
        COALESCE(gs.AvgGroupSize, 0) AS AvgGroupSize,
        COALESCE(ps.IndividualClientsCount, 0) AS IndividualClientsCount,
        COALESCE(ps.CompletedPersonalClassesCount, 0) AS PersonalCount
    FROM Coaches c
    JOIN Staff s ON c.ID_Staff = s.ID_Staff
    JOIN Specializations sp ON c.ID_Spec = sp.ID_Spec
    LEFT JOIN GroupStats gs ON c.ID_Coach = gs.ID_Coach
    LEFT JOIN PersonalStats ps ON c.ID_Coach = ps.ID_Coach
    WHERE s.FireDate IS NULL
)
SELECT 
    CoachId,
    FullName,
    SpecName,
    PersonalCount,
    IndividualClientsCount,
    GroupClassesCount AS GroupCount,
    (PersonalCount + GroupClassesCount) AS TotalClasses,
    AvgGroupSize,
    DENSE_RANK() OVER (ORDER BY GroupClassesCount DESC) AS RankByGroupClasses,
    DENSE_RANK() OVER (ORDER BY AvgGroupSize DESC) AS RankByAvgGroupSize,
    DENSE_RANK() OVER (ORDER BY IndividualClientsCount DESC) AS RankByIndividualClients,
    DENSE_RANK() OVER (ORDER BY (PersonalCount * 1.5 + GroupClassesCount * AvgGroupSize) DESC) AS KpiRank,
    ROUND((PersonalCount * 1.5 + GroupClassesCount * AvgGroupSize)::NUMERIC, 1) AS Kpi
FROM CoachStats
ORDER BY KpiRank ASC, TotalClasses DESC;

-- 8.3. Аналіз проблемних ситуацій та операційних ризиків (D5: getIssuesAnalysis)
CREATE OR REPLACE VIEW v_ProblemSituations AS
SELECT 
    c.FullName AS ClientName,
    COALESCE(c.Phone, '—') AS Phone,
    'Прострочений абонемент' AS ProblemType,
    'Закінчився ' || cs.EndDate::TEXT || ' (' || (CURRENT_DATE - cs.EndDate)::TEXT || ' дн. тому)' AS Details
FROM ClientSubscriptions cs
JOIN Sales s ON cs.ID_Sale = s.ID_Sale
JOIN Clients c ON s.ID_Client = c.ID_Client
WHERE cs.EndDate < CURRENT_DATE AND cs.CurrentStatus <> 'Expired'

UNION ALL

SELECT 
    c.FullName AS ClientName,
    COALESCE(c.Phone, '—') AS Phone,
    'Часті неявки (No-show)' AS ProblemType,
    'Кількість неявок: ' || COUNT(pt.ID_Personal)::TEXT AS Details
FROM Clients c
JOIN Sales s ON c.ID_Client = s.ID_Client
JOIN PersonalTrainings pt ON s.ID_Sale = pt.ID_Sale
WHERE pt.TrainingStatus = 'No-show'
GROUP BY c.ID_Client, c.FullName, c.Phone
HAVING COUNT(pt.ID_Personal) >= 1

UNION ALL

SELECT 
    cl.FullName AS ClientName,
    COALESCE(cl.Phone, '—') AS Phone,
    'Скасоване тренування' AS ProblemType,
    'Тренер: ' || st.FullName || ', причина: ' || COALESCE(pcl.Reason, 'Не вказано') AS Details
FROM PersonalTrainings pt
JOIN Coaches co ON pt.ID_Coach = co.ID_Coach
JOIN Staff st ON co.ID_Staff = st.ID_Staff
JOIN Sales sl ON pt.ID_Sale = sl.ID_Sale
JOIN Clients cl ON sl.ID_Client = cl.ID_Client
LEFT JOIN PT_Changelog pcl ON pt.ID_Personal = pcl.ID_Personal
WHERE pt.TrainingStatus = 'Cancelled'

ORDER BY ProblemType, ClientName;

-- 8.4. Журнал аудиту персональних тренувань та змін розкладу (D6: getAuditLog)
CREATE OR REPLACE VIEW v_PersonalTrainingsAudit AS
SELECT 
    cl.ChangeTimestamp,
    cl.ID_Personal AS PersonalId,
    cl.RequestType,
    cl.ChangeInitiator,
    cl.Reason,
    CASE 
        WHEN cl.RequestType = 'Cancel' THEN 'Скасовано'
        WHEN tcd.NewDateTime IS NOT NULL THEN TO_CHAR(tcd.NewDateTime, 'YYYY-MM-DD HH24:MI')
        ELSE 'Не вказано'
    END AS NewTime,
    ROW_NUMBER() OVER (PARTITION BY cl.ID_Personal ORDER BY cl.ChangeTimestamp ASC) AS ChangeSeqNum,
    LAG(cl.ChangeTimestamp) OVER (PARTITION BY cl.ID_Personal ORDER BY cl.ChangeTimestamp ASC) AS PreviousChangeTime
FROM PT_Changelog cl
LEFT JOIN PT_TimeChangeDetails tcd ON cl.ID_PTLog = tcd.ID_PTLog
ORDER BY cl.ChangeTimestamp DESC;

-- 8.5. Публічна вітрина тренерів клубу з показниками активності
CREATE OR REPLACE VIEW v_PublicCoaches AS
WITH CoachGroupAgg AS (
    SELECT 
        gst.ID_Coach,
        COUNT(DISTINCT gci.ID_Instance) AS GroupClassesCount,
        ROUND(COALESCE(AVG(gci.ActualAttendance), 0), 2) AS AvgGroupSize
    FROM GroupScheduleTemplates gst
    JOIN GroupClassInstances gci ON gst.ID_Template = gci.ID_Template 
         AND gci.ClassStatus IN ('Completed', 'Attended')
    GROUP BY gst.ID_Coach
),
CoachPersonalAgg AS (
    SELECT 
        pt.ID_Coach,
        COUNT(DISTINCT pt.ID_Personal) AS IndividualClientsCount
    FROM PersonalTrainings pt
    WHERE pt.TrainingStatus IN ('Completed', 'Attended')
    GROUP BY pt.ID_Coach
)
SELECT 
    c.ID_Coach,
    s.FullName,
    sp.ID_Spec,
    sp.SpecName,
    c.Biography,
    COALESCE(ga.GroupClassesCount, 0) AS GroupClassesCount,
    COALESCE(ga.AvgGroupSize, 0) AS AvgGroupSize,
    COALESCE(pa.IndividualClientsCount, 0) AS IndividualClientsCount
FROM Coaches c
JOIN Staff s ON c.ID_Staff = s.ID_Staff
JOIN Specializations sp ON c.ID_Spec = sp.ID_Spec
LEFT JOIN CoachGroupAgg ga ON c.ID_Coach = ga.ID_Coach
LEFT JOIN CoachPersonalAgg pa ON c.ID_Coach = pa.ID_Coach
WHERE s.FireDate IS NULL;

-- 8.6. Журнал заявок на зміну розкладу персональних тренувань
CREATE OR REPLACE VIEW v_ScheduleChangeRequests AS
SELECT 
    cl.ID_PTLog, 
    cl.ID_Personal, 
    s_coach.FullName AS CoachName, 
    c.FullName AS ClientName,
    cl.RequestType, 
    cl.Reason, 
    cl.ChangeTimestamp, 
    pt.TrainingDateTime AS CurrentDateTime,
    tcd.NewDateTime AS ProposedDateTime, 
    cl.Status
FROM PT_Changelog cl
JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal
JOIN Coaches co ON pt.ID_Coach = co.ID_Coach
JOIN Staff s_coach ON co.ID_Staff = s_coach.ID_Staff
JOIN Sales s ON pt.ID_Sale = s.ID_Sale
JOIN Clients c ON s.ID_Client = c.ID_Client
LEFT JOIN PT_TimeChangeDetails tcd ON cl.ID_PTLog = tcd.ID_PTLog;

-- Права доступу до аналітичних представлень для директора
GRANT SELECT ON v_AttendanceReport TO director_role;
GRANT SELECT ON v_CoachPerformance TO director_role;
GRANT SELECT ON v_ProblemSituations TO director_role;
GRANT SELECT ON v_PersonalTrainingsAudit TO director_role;
GRANT SELECT ON v_PublicCoaches TO guest, client_role, manager_role, director_role;
GRANT SELECT ON v_ScheduleChangeRequests TO manager_role, director_role;

-- 8.7. Доступні групові заняття клубу з розрахунком вільних місць
CREATE OR REPLACE VIEW v_AvailableGroupClasses AS
SELECT 
    gci.ID_Instance,
    gst.ID_Template,
    ct.TypeName AS Title,
    st.FullName AS CoachName,
    h.HallName,
    gci.ClassDate,
    gci.ClassStartTime AS StartTime,
    gst.DurationMinutes,
    gci.ClassStatus::TEXT AS Status,
    gci.ActualAttendance,
    h.MaxCapacity,
    GREATEST(h.MaxCapacity - gci.ActualAttendance, 0) AS AvailableSpots,
    pl.Price AS Price
FROM GroupClassInstances gci
JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
LEFT JOIN PriceList pl ON ct.ID_Item = pl.ID_Item
JOIN Halls h ON gst.ID_Hall = h.ID_Hall
JOIN Coaches co ON gst.ID_Coach = co.ID_Coach
JOIN Staff st ON co.ID_Staff = st.ID_Staff
WHERE gci.ClassStatus = 'Scheduled'
  AND gci.ClassDate >= CURRENT_DATE;

GRANT SELECT ON v_AvailableGroupClasses TO guest, client_role, manager_role, coach_role, director_role;

-- 8.8. Повний консолідований розклад тренерів (групові та індивідуальні заняття)
CREATE OR REPLACE VIEW v_CoachWeeklySchedule AS
SELECT
    gci.ID_Instance AS activity_id,
    'Group'::TEXT AS activity_type,
    ct.TypeName::TEXT AS title,
    h.HallName AS hall_name,
    gci.ClassDate AS schedule_date,
    gci.ClassStartTime AS start_time,
    (gci.ClassDate + gci.ClassStartTime)::TIMESTAMP AS start_date_time,
    gst.DurationMinutes AS duration_minutes,
    gci.ClassStatus::TEXT AS status,
    gci.ActualAttendance AS attendance_or_capacity,
    c.ID_Coach AS id_coach,
    st.FullName AS coach_name,
    st.DB_User AS db_user,
    CASE EXTRACT(ISODOW FROM gci.ClassDate)
        WHEN 1 THEN 'Понеділок'
        WHEN 2 THEN 'Вівторок'
        WHEN 3 THEN 'Середа'
        WHEN 4 THEN 'Четвер'
        WHEN 5 THEN 'П''ятниця'
        WHEN 6 THEN 'Субота'
        WHEN 7 THEN 'Неділя'
    END AS day_of_week,
    (COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))::TIME AS end_time,
    'Групове заняття'::TEXT AS training_type,
    FORMAT('Фактична відвідуваність: %s ос.', gci.ActualAttendance)::TEXT AS client_or_details
FROM GroupClassInstances gci
JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
JOIN Coaches c ON gst.ID_Coach = c.ID_Coach
JOIN Staff st ON c.ID_Staff = st.ID_Staff
JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
JOIN Halls h ON gst.ID_Hall = h.ID_Hall

UNION ALL

SELECT
    pt.ID_Personal AS activity_id,
    'Personal'::TEXT AS activity_type,
    ('Персональне: ' || cl.FullName)::TEXT AS title,
    h.HallName AS hall_name,
    pt.TrainingDateTime::DATE AS schedule_date,
    pt.TrainingDateTime::TIME AS start_time,
    pt.TrainingDateTime AS start_date_time,
    60 AS duration_minutes,
    pt.TrainingStatus::TEXT AS status,
    1 AS attendance_or_capacity,
    c.ID_Coach AS id_coach,
    st.FullName AS coach_name,
    st.DB_User AS db_user,
    CASE EXTRACT(ISODOW FROM pt.TrainingDateTime)
        WHEN 1 THEN 'Понеділок'
        WHEN 2 THEN 'Вівторок'
        WHEN 3 THEN 'Середа'
        WHEN 4 THEN 'Четвер'
        WHEN 5 THEN 'П''ятниця'
        WHEN 6 THEN 'Субота'
        WHEN 7 THEN 'Неділя'
    END AS day_of_week,
    (pt.TrainingDateTime + INTERVAL '60 minutes')::TIME AS end_time,
    'Індивідуальне тренування'::TEXT AS training_type,
    FORMAT('Клієнт: %s (тел: %s)', cl.FullName, cl.Phone)::TEXT AS client_or_details
FROM PersonalTrainings pt
JOIN Coaches c ON pt.ID_Coach = c.ID_Coach
JOIN Staff st ON c.ID_Staff = st.ID_Staff
JOIN Halls h ON pt.ID_Hall = h.ID_Hall
JOIN Sales s ON pt.ID_Sale = s.ID_Sale
JOIN Clients cl ON s.ID_Client = cl.ID_Client;

GRANT SELECT ON v_CoachWeeklySchedule TO director_role, manager_role, coach_role;

