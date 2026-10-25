-- ------------------------------------------------------------------------------
-- 7. БЕЗПЕКА НА РІВНІ РЯДКІВ (ROW LEVEL SECURITY - RLS)
-- ------------------------------------------------------------------------------

ALTER TABLE Clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE MedicalNotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE Sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE AppliedPromo ENABLE ROW LEVEL SECURITY;
ALTER TABLE ClientSubscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE FreezingLogs ENABLE ROW LEVEL SECURITY;
ALTER TABLE Visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE PersonalTrainings ENABLE ROW LEVEL SECURITY;
ALTER TABLE PT_Changelog ENABLE ROW LEVEL SECURITY;
ALTER TABLE PT_TimeChangeDetails ENABLE ROW LEVEL SECURITY;
ALTER TABLE GroupClassBookings ENABLE ROW LEVEL SECURITY;

-- 7.1. Політики повного доступу для керівника (director_role) та менеджера (manager_role)
DROP POLICY IF EXISTS staff_clients_access ON Clients;
CREATE POLICY staff_clients_access ON Clients TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_med_access ON MedicalNotes;
CREATE POLICY staff_med_access ON MedicalNotes TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_sales_access ON Sales;
CREATE POLICY staff_sales_access ON Sales TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_promo_access ON AppliedPromo;
CREATE POLICY staff_promo_access ON AppliedPromo TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_subs_access ON ClientSubscriptions;
CREATE POLICY staff_subs_access ON ClientSubscriptions TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_freeze_access ON FreezingLogs;
CREATE POLICY staff_freeze_access ON FreezingLogs TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_visits_access ON Visits;
CREATE POLICY staff_visits_access ON Visits TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_pt_access ON PersonalTrainings;
CREATE POLICY staff_pt_access ON PersonalTrainings TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_ptlog_access ON PT_Changelog;
CREATE POLICY staff_ptlog_access ON PT_Changelog TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_pttime_access ON PT_TimeChangeDetails;
CREATE POLICY staff_pttime_access ON PT_TimeChangeDetails TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
DROP POLICY IF EXISTS staff_bookings_access ON GroupClassBookings;
CREATE POLICY staff_bookings_access ON GroupClassBookings TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);

-- 7.2. Політики для Клієнта (client_role) - бачить і змінює виключно власні записи
DROP POLICY IF EXISTS client_self_view ON Clients;
CREATE POLICY client_self_view ON Clients FOR SELECT TO client_role USING (DB_User = SESSION_USER);
DROP POLICY IF EXISTS client_self_update ON Clients;
CREATE POLICY client_self_update ON Clients FOR UPDATE TO client_role USING (DB_User = SESSION_USER) WITH CHECK (DB_User = SESSION_USER);

DROP POLICY IF EXISTS client_med_access ON MedicalNotes;
CREATE POLICY client_med_access ON MedicalNotes FOR ALL TO client_role 
    USING (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER))
    WITH CHECK (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_sales_access ON Sales;
CREATE POLICY client_sales_access ON Sales FOR ALL TO client_role 
    USING (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER))
    WITH CHECK (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_promo_access ON AppliedPromo;
CREATE POLICY client_promo_access ON AppliedPromo FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_subs_access ON ClientSubscriptions;
CREATE POLICY client_subs_access ON ClientSubscriptions FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_freeze_access ON FreezingLogs;
CREATE POLICY client_freeze_access ON FreezingLogs FOR ALL TO client_role 
    USING (ID_ClientSub IN (SELECT cs.ID_ClientSub FROM ClientSubscriptions cs JOIN Sales s ON cs.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_ClientSub IN (SELECT cs.ID_ClientSub FROM ClientSubscriptions cs JOIN Sales s ON cs.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_visits_select ON Visits;
CREATE POLICY client_visits_select ON Visits FOR SELECT TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_pt_access ON PersonalTrainings;
CREATE POLICY client_pt_access ON PersonalTrainings FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_ptlog_access ON PT_Changelog;
CREATE POLICY client_ptlog_access ON PT_Changelog FOR ALL TO client_role 
    USING (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_pttime_access ON PT_TimeChangeDetails;
CREATE POLICY client_pttime_access ON PT_TimeChangeDetails FOR ALL TO client_role 
    USING (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

DROP POLICY IF EXISTS client_bookings_access ON GroupClassBookings;
CREATE POLICY client_bookings_access ON GroupClassBookings FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

-- 7.3. Політики для Тренера (coach_role) - бачить закріплені за ним заняття, запити та клієнтів
DROP POLICY IF EXISTS coach_pt_access ON PersonalTrainings;
CREATE POLICY coach_pt_access ON PersonalTrainings TO coach_role
    USING (ID_Coach IN (SELECT c.ID_Coach FROM Coaches c JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER))
    WITH CHECK (ID_Coach IN (SELECT c.ID_Coach FROM Coaches c JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

DROP POLICY IF EXISTS coach_group_bookings_view ON GroupClassBookings;
CREATE POLICY coach_group_bookings_view ON GroupClassBookings FOR SELECT TO coach_role
    USING (ID_Instance IN (SELECT gci.ID_Instance FROM GroupClassInstances gci JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template JOIN Coaches c ON gst.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

DROP POLICY IF EXISTS coach_clients_view ON Clients;
CREATE POLICY coach_clients_view ON Clients FOR SELECT TO coach_role
    USING (
        ID_Client IN (
            SELECT s.ID_Client FROM Sales s 
            JOIN PersonalTrainings pt ON s.ID_Sale = pt.ID_Sale 
            JOIN Coaches c ON pt.ID_Coach = c.ID_Coach 
            JOIN Staff st ON c.ID_Staff = st.ID_Staff 
            WHERE st.DB_User = SESSION_USER
        )
        OR 
        ID_Client IN (
            SELECT sl.ID_Client FROM Sales sl
            JOIN GroupClassBookings gcb ON sl.ID_Sale = gcb.ID_Sale
            JOIN GroupClassInstances gci ON gcb.ID_Instance = gci.ID_Instance
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            JOIN Coaches co ON gst.ID_Coach = co.ID_Coach
            JOIN Staff sta ON co.ID_Staff = sta.ID_Staff
            WHERE sta.DB_User = SESSION_USER
        )
    );

DROP POLICY IF EXISTS coach_medical_view ON MedicalNotes;
CREATE POLICY coach_medical_view ON MedicalNotes FOR SELECT TO coach_role
    USING (
        ID_Client IN (
            SELECT s.ID_Client FROM Sales s 
            JOIN PersonalTrainings pt ON s.ID_Sale = pt.ID_Sale 
            JOIN Coaches c ON pt.ID_Coach = c.ID_Coach
            JOIN Staff st ON c.ID_Staff = st.ID_Staff
            WHERE st.DB_User = SESSION_USER
        )
        OR 
        ID_Client IN (
            SELECT sl.ID_Client FROM Sales sl
            JOIN GroupClassBookings gcb ON sl.ID_Sale = gcb.ID_Sale
            JOIN GroupClassInstances gci ON gcb.ID_Instance = gci.ID_Instance
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
            JOIN Coaches co ON gst.ID_Coach = co.ID_Coach
            JOIN Staff sta ON co.ID_Staff = sta.ID_Staff
            WHERE sta.DB_User = SESSION_USER
        )
    );

DROP POLICY IF EXISTS coach_sales_view ON Sales;
CREATE POLICY coach_sales_view ON Sales FOR SELECT TO coach_role
    USING (
        ID_Sale IN (
            SELECT pt.ID_Sale FROM PersonalTrainings pt 
            JOIN Coaches c ON pt.ID_Coach = c.ID_Coach 
            JOIN Staff st ON c.ID_Staff = st.ID_Staff 
            WHERE st.DB_User = SESSION_USER
        )
        OR 
        ID_Sale IN (
            SELECT gcb.ID_Sale FROM GroupClassBookings gcb 
            JOIN GroupClassInstances gci ON gcb.ID_Instance = gci.ID_Instance 
            JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template 
            JOIN Coaches co ON gst.ID_Coach = co.ID_Coach 
            JOIN Staff sta ON co.ID_Staff = sta.ID_Staff 
            WHERE sta.DB_User = SESSION_USER
        )
    );

DROP POLICY IF EXISTS coach_ptlog_access ON PT_Changelog;
CREATE POLICY coach_ptlog_access ON PT_Changelog FOR ALL TO coach_role
    USING (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER))
    WITH CHECK (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

DROP POLICY IF EXISTS coach_pttime_access ON PT_TimeChangeDetails;
CREATE POLICY coach_pttime_access ON PT_TimeChangeDetails FOR ALL TO coach_role
    USING (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER))
    WITH CHECK (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

