-- ------------------------------------------------------------------------------
-- 5. НАДАННЯ ПРАВ ДОСТУПУ (GRANT / REVOKE)
-- ------------------------------------------------------------------------------

-- Доступ до схеми public
GRANT USAGE ON SCHEMA public TO guest, client_role, manager_role, hr_role, coach_role, director_role;

-- 5.1. ДИРЕКТОР (director_role): повний контроль
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO director_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO director_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO director_role;

-- 5.2. МЕНЕДЖЕР КЛІЄНТІВ (manager_role): операційна діяльність
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    Clients, MedicalNotes, Sales, AppliedPromo, ClientSubscriptions, 
    FreezingLogs, Visits, PersonalTrainings, PT_Changelog, 
    PT_TimeChangeDetails, GroupClassBookings, GroupClassInstances, 
    PromoCodes 
TO manager_role;

GRANT SELECT ON 
    Staff, Positions, Coaches, Specializations, PriceList, 
    PriceListSubs, Halls, ClassTypes, GroupScheduleTemplates 
TO manager_role;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO manager_role;

-- 5.3. HR МЕНЕДЖЕР (hr_role): управління персоналом
GRANT SELECT, INSERT, UPDATE ON Staff, Coaches, Positions, Specializations TO hr_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hr_role;

-- 5.4. ТРЕНЕР (coach_role): власний розклад та відмітки
GRANT SELECT ON 
    Clients, MedicalNotes, Staff, Coaches, Specializations, 
    Halls, ClassTypes, GroupScheduleTemplates, GroupClassInstances, 
    PersonalTrainings, GroupClassBookings, Sales, PT_Changelog, PT_TimeChangeDetails 
TO coach_role;

GRANT UPDATE (TrainingStatus) ON PersonalTrainings TO coach_role;
GRANT UPDATE (ClassStatus, ActualAttendance) ON GroupClassInstances TO coach_role;
GRANT INSERT ON PT_Changelog, PT_TimeChangeDetails TO coach_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO coach_role;

-- 5.5. КЛІЄНТ (client_role): самообслуговування
GRANT SELECT ON 
    PriceList, PriceListSubs, PromoCodes, Coaches, Halls, 
    Specializations, ClassTypes, GroupScheduleTemplates, 
    GroupClassInstances, Staff
TO client_role;

GRANT SELECT, UPDATE (Phone, FullName) ON Clients TO client_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON MedicalNotes TO client_role;
GRANT SELECT, INSERT ON Sales TO client_role;
GRANT SELECT, INSERT ON AppliedPromo TO client_role;
GRANT SELECT, INSERT, UPDATE ON ClientSubscriptions TO client_role;
GRANT SELECT, INSERT ON FreezingLogs TO client_role;
GRANT SELECT ON Visits TO client_role;
GRANT SELECT, INSERT, UPDATE (TrainingStatus) ON PersonalTrainings TO client_role;
GRANT SELECT, INSERT ON PT_Changelog TO client_role;
GRANT SELECT, INSERT ON PT_TimeChangeDetails TO client_role;
GRANT SELECT, INSERT, UPDATE (BookingStatus) ON GroupClassBookings TO client_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO client_role;

-- 5.6. ГІСТЬ (guest): вітрина клубу
GRANT SELECT ON 
    PriceList, PriceListSubs, Halls, Coaches, Staff, 
    Specializations, ClassTypes, GroupScheduleTemplates, 
    GroupClassInstances, PersonalTrainings 
TO guest;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO guest;

DROP POLICY IF EXISTS guest_pt_view ON PersonalTrainings;
CREATE POLICY guest_pt_view ON PersonalTrainings FOR SELECT TO guest 
    USING (TrainingStatus IN ('Completed', 'Attended'));

