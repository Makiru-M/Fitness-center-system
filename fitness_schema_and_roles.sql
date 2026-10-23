-- ==============================================================================
-- ІНФОРМАЦІЙНА СИСТЕМА ФІТНЕС-КЛУБУ «FitnessClub IS»
-- ПОВНИЙ КОМПЛЕКСНИЙ СКРИПТ НАЛАШТУВАННЯ СХЕМИ БД ТА РОЛЬОВОЇ МОДЕЛІ
-- Версія: v17.0 (Comprehensive Architecture & RBAC / RLS)
-- Розроблено за лекційним курсом: Малахов Є.В. «Бази даних» (ДУІТЗ)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. СТВОРЕННЯ КОРИСТУВАЛЬНИЦЬКИХ ТИПІВ (ENUM)
-- ------------------------------------------------------------------------------
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activity_status') THEN
        CREATE TYPE activity_status AS ENUM ('Scheduled', 'Completed', 'Cancelled', 'No-show', 'Attended');
    END IF;
END
$$;

-- ------------------------------------------------------------------------------
-- 2. СТВОРЕННЯ РЕЛЯЦІЙНИХ ТАБЛИЦЬ (DDL)
-- ------------------------------------------------------------------------------

-- Довідник посад працівників
CREATE TABLE IF NOT EXISTS Positions (
    ID_Position SERIAL PRIMARY KEY,
    PositionName VARCHAR(50) NOT NULL UNIQUE
);

-- Довідник спортивних спеціалізацій
CREATE TABLE IF NOT EXISTS Specializations (
    ID_Spec SERIAL PRIMARY KEY,
    SpecName VARCHAR(50) NOT NULL UNIQUE
);

-- Спортивні зали клубу
CREATE TABLE IF NOT EXISTS Halls (
    ID_Hall SERIAL PRIMARY KEY,
    HallName VARCHAR(50) NOT NULL UNIQUE,
    MaxCapacity INTEGER NOT NULL CHECK (MaxCapacity > 0),
    IsActive BOOLEAN DEFAULT TRUE
);

-- Види групових занять
CREATE TABLE IF NOT EXISTS ClassTypes (
    ID_ClassType SERIAL PRIMARY KEY,
    TypeName VARCHAR(50) NOT NULL UNIQUE
);

-- Співробітники фітнес-клубу
CREATE TABLE IF NOT EXISTS Staff (
    ID_Staff SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    Phone VARCHAR(15) NOT NULL UNIQUE,
    ID_Position INTEGER NOT NULL REFERENCES Positions(ID_Position),
    DB_User VARCHAR(32) NOT NULL UNIQUE,
    HireDate DATE NOT NULL DEFAULT CURRENT_DATE,
    FireDate DATE,
    CHECK (HireDate > BirthDate),
    CHECK (FireDate IS NULL OR FireDate >= HireDate)
);

-- Тренери (розширення сутності Staff)
CREATE TABLE IF NOT EXISTS Coaches (
    ID_Coach SERIAL PRIMARY KEY,
    ID_Staff INTEGER NOT NULL UNIQUE REFERENCES Staff(ID_Staff) ON DELETE CASCADE,
    ID_Spec INTEGER NOT NULL REFERENCES Specializations(ID_Spec),
    Biography TEXT
);

-- Клієнти клубу
CREATE TABLE IF NOT EXISTS Clients (
    ID_Client SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    Phone VARCHAR(15) NOT NULL UNIQUE,
    Gender VARCHAR(10) NOT NULL CHECK (Gender IN ('Male', 'Female', 'Other')),
    DB_User VARCHAR(32) NOT NULL UNIQUE
);

-- Медичні застереження та протипоказання клієнтів (1:1у)
CREATE TABLE IF NOT EXISTS MedicalNotes (
    ID_Client INTEGER PRIMARY KEY REFERENCES Clients(ID_Client) ON DELETE CASCADE,
    NotesText TEXT NOT NULL
);

-- Прайс-лист послуг та абонементів клубу
CREATE TABLE IF NOT EXISTS PriceList (
    ID_Item SERIAL PRIMARY KEY,
    ItemName VARCHAR(100) NOT NULL UNIQUE,
    Category VARCHAR(30) NOT NULL CHECK (Category IN ('Membership', 'Personal training', 'Group training', 'Extra')),
    Price DECIMAL(10, 2) NOT NULL CHECK (Price >= 0),
    PriceStartDate DATE NOT NULL DEFAULT CURRENT_DATE,
    Description TEXT
);

-- Специфікація абонементів (тривалість, заморозка)
CREATE TABLE IF NOT EXISTS PriceListSubs (
    ID_Item INTEGER PRIMARY KEY REFERENCES PriceList(ID_Item) ON DELETE CASCADE,
    DurationDays INTEGER NOT NULL CHECK (DurationDays > 0),
    MaxFreezingDays INTEGER NOT NULL DEFAULT 0 CHECK (MaxFreezingDays >= 0)
);

-- Довідник промокодів для знижок
CREATE TABLE IF NOT EXISTS PromoCodes (
    ID_Promo SERIAL PRIMARY KEY,
    CodeText VARCHAR(20) NOT NULL UNIQUE,
    DiscountPercent INTEGER NOT NULL CHECK (DiscountPercent BETWEEN 1 AND 100),
    ExpiryDate DATE NOT NULL
);

-- Фінансові транзакції / продажі
CREATE TABLE IF NOT EXISTS Sales (
    ID_Sale SERIAL PRIMARY KEY,
    ID_Client INTEGER NOT NULL REFERENCES Clients(ID_Client),
    ID_Item INTEGER NOT NULL REFERENCES PriceList(ID_Item),
    SaleDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ID_Manager INTEGER NOT NULL REFERENCES Staff(ID_Staff),
    SalePrice DECIMAL(10, 2) NOT NULL CHECK (SalePrice >= 0)
);

-- Факт застосування промокоду до продажу (1:1у)
CREATE TABLE IF NOT EXISTS AppliedPromo (
    ID_Sale INTEGER PRIMARY KEY REFERENCES Sales(ID_Sale) ON DELETE CASCADE,
    ID_Promo INTEGER NOT NULL REFERENCES PromoCodes(ID_Promo)
);

-- Активовані клієнтські абонементи
CREATE TABLE IF NOT EXISTS ClientSubscriptions (
    ID_ClientSub SERIAL PRIMARY KEY,
    ID_Sale INTEGER NOT NULL UNIQUE REFERENCES Sales(ID_Sale) ON DELETE CASCADE,
    StartDate DATE NOT NULL DEFAULT CURRENT_DATE,
    EndDate DATE NOT NULL,
    CurrentStatus VARCHAR(15) NOT NULL DEFAULT 'Active' CHECK (CurrentStatus IN ('Active', 'Frozen', 'Expired')),
    RemainingFreezingDays INTEGER NOT NULL CHECK (RemainingFreezingDays >= 0),
    CHECK (EndDate >= StartDate)
);

-- Журнал періодів заморозки абонементів
CREATE TABLE IF NOT EXISTS FreezingLogs (
    ID_Freezing SERIAL PRIMARY KEY,
    ID_ClientSub INTEGER NOT NULL REFERENCES ClientSubscriptions(ID_ClientSub) ON DELETE CASCADE,
    FreezeStartDate DATE NOT NULL DEFAULT CURRENT_DATE,
    FreezeEndDate DATE NOT NULL,
    Reason TEXT NOT NULL,
    CHECK (FreezeEndDate > FreezeStartDate)
);

-- Персональні тренування
CREATE TABLE IF NOT EXISTS PersonalTrainings (
    ID_Personal SERIAL PRIMARY KEY,
    ID_Coach INTEGER NOT NULL REFERENCES Coaches(ID_Coach),
    ID_Hall INTEGER NOT NULL REFERENCES Halls(ID_Hall),
    ID_Sale INTEGER NOT NULL UNIQUE REFERENCES Sales(ID_Sale),
    TrainingDateTime TIMESTAMP NOT NULL,
    TrainingStatus activity_status NOT NULL DEFAULT 'Scheduled'
);

-- Журнал запитів на перенесення та скасування персональних тренувань
CREATE TABLE IF NOT EXISTS PT_Changelog (
    ID_PTLog SERIAL PRIMARY KEY,
    ID_Personal INTEGER NOT NULL REFERENCES PersonalTrainings(ID_Personal) ON DELETE CASCADE,
    RequestType VARCHAR(15) NOT NULL CHECK (RequestType IN ('Reschedule', 'Cancel')),
    Reason TEXT NOT NULL,
    ChangeInitiator VARCHAR(10) NOT NULL CHECK (ChangeInitiator IN ('Client', 'Coach', 'Manager')),
    ChangeTimestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Деталізація часових змін при перенесенні персонального тренування
CREATE TABLE IF NOT EXISTS PT_TimeChangeDetails (
    ID_PTLog INTEGER PRIMARY KEY REFERENCES PT_Changelog(ID_PTLog) ON DELETE CASCADE,
    OldDateTime TIMESTAMP NOT NULL,
    NewDateTime TIMESTAMP NOT NULL,
    CHECK (NewDateTime <> OldDateTime)
);

-- Шаблони щотижневого розкладу групових занять
CREATE TABLE IF NOT EXISTS GroupScheduleTemplates (
    ID_Template SERIAL PRIMARY KEY,
    ID_ClassType INTEGER NOT NULL REFERENCES ClassTypes(ID_ClassType),
    DayOfWeek INTEGER NOT NULL CHECK (DayOfWeek BETWEEN 1 AND 7),
    StartTime TIME NOT NULL,
    DurationMinutes INTEGER NOT NULL CHECK (DurationMinutes > 0),
    ID_Hall INTEGER NOT NULL REFERENCES Halls(ID_Hall),
    ID_Coach INTEGER NOT NULL REFERENCES Coaches(ID_Coach),
    CONSTRAINT uq_gst_hall_time UNIQUE (ID_Hall, DayOfWeek, StartTime),
    CONSTRAINT uq_gst_coach_time UNIQUE (ID_Coach, DayOfWeek, StartTime)
);

-- Екземпляри конкретних групових занять за календарем
CREATE TABLE IF NOT EXISTS GroupClassInstances (
    ID_Instance SERIAL PRIMARY KEY,
    ID_Template INTEGER NOT NULL REFERENCES GroupScheduleTemplates(ID_Template),
    ClassDate DATE NOT NULL,
    ClassStatus activity_status NOT NULL DEFAULT 'Scheduled',
    ActualAttendance INTEGER NOT NULL DEFAULT 0 CHECK (ActualAttendance >= 0),
    ClassStartTime TIME,
    CONSTRAINT uq_gci_template_date UNIQUE (ID_Template, ClassDate)
);

-- Записи клієнтів на групові заняття
CREATE TABLE IF NOT EXISTS GroupClassBookings (
    ID_Booking SERIAL PRIMARY KEY,
    ID_Instance INTEGER NOT NULL REFERENCES GroupClassInstances(ID_Instance) ON DELETE CASCADE,
    ID_Sale INTEGER NOT NULL REFERENCES Sales(ID_Sale),
    BookingStatus activity_status NOT NULL DEFAULT 'Scheduled'
);

-- Відвідування залів (Check-in турнікета)
CREATE TABLE IF NOT EXISTS Visits (
    ID_Visit SERIAL PRIMARY KEY,
    ID_Hall INTEGER NOT NULL REFERENCES Halls(ID_Hall),
    ID_Sale INTEGER NOT NULL REFERENCES Sales(ID_Sale),
    CheckInTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 3. СТВОРЕННЯ ІНДЕКСІВ ДЛЯ ОПТИМІЗАЦІЇ ЗАПИТІВ
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_clients_phone ON Clients(Phone);
CREATE INDEX IF NOT EXISTS idx_clients_fullname ON Clients(FullName);
CREATE INDEX IF NOT EXISTS idx_clients_dbuser ON Clients(DB_User);
CREATE INDEX IF NOT EXISTS idx_staff_phone ON Staff(Phone);
CREATE INDEX IF NOT EXISTS idx_staff_dbuser ON Staff(DB_User);
CREATE INDEX IF NOT EXISTS idx_sales_date ON Sales(SaleDate);
CREATE INDEX IF NOT EXISTS idx_sales_client ON Sales(ID_Client);
CREATE INDEX IF NOT EXISTS idx_visits_time ON Visits(CheckInTime);
CREATE INDEX IF NOT EXISTS idx_personal_trainings_time ON PersonalTrainings(TrainingDateTime);
CREATE INDEX IF NOT EXISTS idx_personal_trainings_coach ON PersonalTrainings(ID_Coach);
CREATE UNIQUE INDEX IF NOT EXISTS uq_coach_active_slot ON PersonalTrainings (ID_Coach, TrainingDateTime) WHERE TrainingStatus = 'Scheduled';
CREATE INDEX IF NOT EXISTS idx_group_instances_date ON GroupClassInstances(ClassDate);
CREATE INDEX IF NOT EXISTS idx_group_instances_template ON GroupClassInstances(ID_Template);
CREATE UNIQUE INDEX IF NOT EXISTS uq_group_booking_active ON GroupClassBookings (ID_Instance, ID_Sale) WHERE BookingStatus = 'Scheduled';

-- ------------------------------------------------------------------------------
-- 4. РОЛЬОВА МОДЕЛЬ (RBAC) ТА ОБЛІКОВІ ЗАПИСИ
-- ------------------------------------------------------------------------------

DO $$ 
BEGIN
    -- 1. Системні групові ролі (NOLOGIN)
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'guest') THEN
        CREATE ROLE guest;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'client_role') THEN
        CREATE ROLE client_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'manager_role') THEN
        CREATE ROLE manager_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hr_role') THEN
        CREATE ROLE hr_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'coach_role') THEN
        CREATE ROLE coach_role;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'director_role') THEN
        CREATE ROLE director_role;
    END IF;

    -- 2. Публічний гість (guest_user) для неавторизованого перегляду та реєстрації
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'guest_user') THEN
        CREATE USER guest_user WITH PASSWORD 'guest_pass_2026' IN ROLE guest;
    ELSE
        ALTER USER guest_user WITH PASSWORD 'guest_pass_2026';
        GRANT guest TO guest_user;
    END IF;
END
$$;

-- Створення облікових записів персоналу клубу (демо-пароль: pass_123)
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Керівник
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'boss_ivan') THEN
        CREATE USER boss_ivan WITH PASSWORD 'boss123' IN ROLE director_role;
    ELSE
        ALTER USER boss_ivan WITH PASSWORD 'boss123';
    END IF;

    -- Менеджер клієнтів
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'manager_petro') THEN
        CREATE USER manager_petro WITH PASSWORD 'mgr123' IN ROLE manager_role;
    ELSE
        ALTER USER manager_petro WITH PASSWORD 'mgr123';
    END IF;

    -- HR Менеджер
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'admin_olena') THEN
        CREATE USER admin_olena WITH PASSWORD 'hr123' IN ROLE hr_role;
    ELSE
        ALTER USER admin_olena WITH PASSWORD 'hr123';
    END IF;

    -- Тренери
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'coach_maksym') THEN
        CREATE USER coach_maksym WITH PASSWORD 'coach123' IN ROLE coach_role;
    ELSE
        ALTER USER coach_maksym WITH PASSWORD 'coach123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'coach_andriy') THEN
        CREATE USER coach_andriy WITH PASSWORD 'coach123' IN ROLE coach_role;
    ELSE
        ALTER USER coach_andriy WITH PASSWORD 'coach123';
    END IF;

    FOR r IN SELECT unnest(ARRAY['coach_mariya', 'coach_dima', 'coach_yulia', 'coach_serg', 'coach_oleg', 'coach_anna']) AS usr
    LOOP
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = r.usr) THEN
            EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE coach_role', r.usr, 'pass_123');
        END IF;
    END LOOP;

    -- Демо-клієнти
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'user_oleksandr') THEN
        CREATE USER user_oleksandr WITH PASSWORD 'client123' IN ROLE client_role;
    ELSE
        ALTER USER user_oleksandr WITH PASSWORD 'client123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'client_vitaliy') THEN
        CREATE USER client_vitaliy WITH PASSWORD 'client123' IN ROLE client_role;
    ELSE
        ALTER USER client_vitaliy WITH PASSWORD 'client123';
    END IF;

    FOR r IN SELECT unnest(ARRAY['client_hanna', 'client_maksym', 'client_olga', 'client_igor', 'client_svitlana', 'client_denis', 'client_kateryna', 'client_artem', 'client_nataliya']) AS usr
    LOOP
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = r.usr) THEN
            EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE client_role', r.usr, 'pass_123');
        END IF;
    END LOOP;
END
$$;

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

CREATE POLICY guest_pt_view ON PersonalTrainings FOR SELECT TO guest 
    USING (TrainingStatus IN ('Completed', 'Attended'));

-- ------------------------------------------------------------------------------
-- 6. ЗБЕРЕЖЕНІ ПРОЦЕДУРИ ТА ФУНКЦІЇ (SECURITY DEFINER)
-- ------------------------------------------------------------------------------

-- 6.0. Допоміжна функція оформлення чека продажу з промокодом (DRY / Database-First)
CREATE OR REPLACE FUNCTION fn_process_sale_with_promo(
    p_client_id INT,
    p_item_category VARCHAR,
    p_item_id INT,
    p_promo_code VARCHAR,
    p_manager_id INT DEFAULT NULL
)
RETURNS TABLE (
    out_sale_id INT,
    out_item_id INT,
    out_final_price NUMERIC(10,2),
    out_discount INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_item_id INT := p_item_id;
    v_base_price NUMERIC(10,2);
    v_discount INT := 0;
    v_promo_id INT := NULL;
    v_final_price NUMERIC(10,2);
    v_manager_id INT := p_manager_id;
    v_sale_id INT;
BEGIN
    IF v_item_id IS NULL THEN
        IF p_item_category IS NULL OR length(trim(p_item_category)) = 0 THEN
            RAISE EXCEPTION 'Не вказано ані послугу/товар (item_id), ані категорію тарифу!';
        END IF;

        SELECT ID_Item, Price INTO v_item_id, v_base_price
        FROM PriceList
        WHERE Category = p_item_category
        ORDER BY PriceStartDate DESC, ID_Item ASC
        LIMIT 1;

        IF v_item_id IS NULL THEN
            RAISE EXCEPTION 'У прайс-листі не знайдено діючого тарифу для категорії "%"!', p_item_category;
        END IF;
    ELSE
        SELECT Price INTO v_base_price
        FROM PriceList
        WHERE ID_Item = v_item_id;

        IF v_base_price IS NULL THEN
            RAISE EXCEPTION 'Позицію з ID % не знайдено в прайс-листі!', v_item_id;
        END IF;
    END IF;

    IF p_promo_code IS NOT NULL AND length(trim(p_promo_code)) > 0 THEN
        SELECT ID_Promo, DiscountPercent INTO v_promo_id, v_discount
        FROM PromoCodes
        WHERE CodeText = trim(p_promo_code) AND ExpiryDate >= CURRENT_DATE;
    END IF;

    IF v_discount > 0 THEN
        v_final_price := ROUND(v_base_price * (100 - v_discount)::NUMERIC / 100.0, 2);
    ELSE
        v_final_price := v_base_price;
    END IF;

    IF v_manager_id IS NULL THEN
        SELECT s.ID_Staff INTO v_manager_id
        FROM Staff s
        JOIN Positions p ON s.ID_Position = p.ID_Position
        WHERE s.FireDate IS NULL
          AND (
            p.PositionName ILIKE '%менеджер клієнтів%' 
            OR p.PositionName ILIKE '%менеджер по роботі з клієнтами%'
            OR (p.PositionName ILIKE '%менеджер%' AND p.PositionName NOT ILIKE '%hr%')
            OR p.PositionName ILIKE '%адміністратор%'
          )
        ORDER BY s.ID_Staff ASC
        LIMIT 1;

        IF v_manager_id IS NULL THEN
            SELECT ID_Staff INTO v_manager_id
            FROM Staff
            WHERE FireDate IS NULL
            ORDER BY ID_Staff ASC
            LIMIT 1;
        END IF;
    END IF;

    IF v_manager_id IS NULL THEN
        RAISE EXCEPTION 'Неможливо провести чек продажу: в системі немає активних співробітників!';
    END IF;

    INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate)
    VALUES (p_client_id, v_item_id, v_final_price, v_manager_id, CURRENT_TIMESTAMP)
    RETURNING ID_Sale INTO v_sale_id;

    IF v_promo_id IS NOT NULL THEN
        INSERT INTO AppliedPromo (ID_Sale, ID_Promo)
        VALUES (v_sale_id, v_promo_id);
    END IF;

    RETURN QUERY SELECT v_sale_id, v_item_id, v_final_price, v_discount;
END;
$$;

-- 6.1-A. Придбання / продовження абонемента (Задача Cl2 / M3, SECURITY DEFINER)
CREATE OR REPLACE FUNCTION sp_purchase_subscription(
    p_client_id INT,
    p_item_id INT,
    p_promo_code VARCHAR DEFAULT NULL,
    p_manager_id INT DEFAULT NULL,
    p_start_date DATE DEFAULT NULL
)
RETURNS TABLE (
    sub_id INT,
    sale_id INT,
    item_name VARCHAR,
    start_date DATE,
    end_date DATE,
    status VARCHAR,
    remaining_freezing_days INT,
    final_price NUMERIC(10,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_client_id INT := p_client_id;
    v_item_name VARCHAR;
    v_duration INT;
    v_max_freeze INT;
    v_active_end_date DATE;
    v_start_date DATE := p_start_date;
    v_end_date DATE;
    v_sale_id INT;
    v_final_price NUMERIC(10,2);
    v_client_sub_id INT;
    v_is_client_user BOOLEAN;
BEGIN
    SELECT pg_has_role(SESSION_USER, 'client_role', 'MEMBER') INTO v_is_client_user;

    IF v_is_client_user THEN
        SELECT ID_Client INTO v_client_id
        FROM Clients
        WHERE DB_User = SESSION_USER;

        IF v_client_id IS NULL THEN
            RAISE EXCEPTION 'Профіль клієнта не знайдено для поточного користувача.';
        END IF;
    ELSE
        IF v_client_id IS NULL THEN
            RAISE EXCEPTION 'Не вказано ID клієнта для оформлення абонемента.';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM Clients WHERE ID_Client = v_client_id) THEN
            RAISE EXCEPTION 'Клієнта з ID % не знайдено.', v_client_id;
        END IF;
    END IF;

    -- Перевірка чи є позиція абонементом
    SELECT pl.ItemName, pls.DurationDays, pls.MaxFreezingDays
    INTO v_item_name, v_duration, v_max_freeze
    FROM PriceList pl
    JOIN PriceListSubs pls ON pl.ID_Item = pls.ID_Item
    WHERE pl.ID_Item = p_item_id;

    IF v_duration IS NULL THEN
        RAISE EXCEPTION 'Обраний пункт прайсу (ID: %) не є абонементом.', p_item_id;
    END IF;

    -- Перевірка діючого абонемента
    SELECT cs.EndDate INTO v_active_end_date
    FROM ClientSubscriptions cs
    JOIN Sales s ON cs.ID_Sale = s.ID_Sale
    WHERE s.ID_Client = v_client_id
      AND cs.CurrentStatus IN ('Active', 'Frozen')
      AND cs.EndDate >= CURRENT_DATE
    ORDER BY cs.EndDate DESC
    LIMIT 1;

    IF v_is_client_user THEN
        IF v_active_end_date IS NOT NULL THEN
            IF (v_active_end_date - CURRENT_DATE) > 7 THEN
                RAISE EXCEPTION 'Продовжити абонемент можна не раніше ніж за 7 днів до закінчення поточного (доступно з %).', (v_active_end_date - INTERVAL '7 days')::DATE;
            END IF;
            v_start_date := v_active_end_date + INTERVAL '1 day';
        ELSE
            v_start_date := CURRENT_DATE;
        END IF;
    ELSE
        IF v_start_date IS NULL THEN
            IF v_active_end_date IS NOT NULL THEN
                v_start_date := v_active_end_date + INTERVAL '1 day';
            ELSE
                v_start_date := CURRENT_DATE;
            END IF;
        END IF;
    END IF;

    v_end_date := v_start_date + (v_duration * INTERVAL '1 day');

    -- Створення чека через єдину функцію продажу
    SELECT res.out_sale_id, res.out_final_price
    INTO v_sale_id, v_final_price
    FROM fn_process_sale_with_promo(v_client_id, NULL, p_item_id, p_promo_code, p_manager_id) res;

    -- Вставка в ClientSubscriptions
    INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays)
    VALUES (v_sale_id, v_start_date, v_end_date, 'Active', v_max_freeze)
    RETURNING ID_ClientSub INTO v_client_sub_id;

    RETURN QUERY SELECT
        v_client_sub_id,
        v_sale_id,
        v_item_name,
        v_start_date,
        v_end_date,
        'Active'::VARCHAR,
        v_max_freeze,
        v_final_price;
END;
$$;

-- 6.1-B. Бронювання персонального тренування (Задача Cl5 / M6, SECURITY DEFINER)
CREATE OR REPLACE FUNCTION sp_book_personal_training(
    p_client_id INT,
    p_coach_id INT,
    p_hall_id INT,
    p_training_datetime TIMESTAMP,
    p_promo_code VARCHAR DEFAULT NULL,
    p_manager_id INT DEFAULT NULL
)
RETURNS TABLE (
    personal_id INT,
    sale_id INT,
    final_price NUMERIC(10,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_client_id INT := p_client_id;
    v_is_client_user BOOLEAN;
    v_sale_id INT;
    v_final_price NUMERIC(10,2);
    v_personal_id INT;
BEGIN
    SELECT pg_has_role(SESSION_USER, 'client_role', 'MEMBER') INTO v_is_client_user;

    IF v_is_client_user THEN
        SELECT ID_Client INTO v_client_id
        FROM Clients
        WHERE DB_User = SESSION_USER;

        IF v_client_id IS NULL THEN
            RAISE EXCEPTION 'Профіль клієнта не знайдено для поточного користувача.';
        END IF;
    ELSE
        IF v_client_id IS NULL THEN
            RAISE EXCEPTION 'Не вказано ID клієнта для запису на персональне тренування.';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM Clients WHERE ID_Client = v_client_id) THEN
            RAISE EXCEPTION 'Клієнта з ID % не знайдено.', v_client_id;
        END IF;
    END IF;

    -- Перевірка наявності активного абонемента
    IF NOT EXISTS (
        SELECT 1
        FROM ClientSubscriptions cs
        JOIN Sales s ON cs.ID_Sale = s.ID_Sale
        WHERE s.ID_Client = v_client_id
          AND cs.CurrentStatus = 'Active'
          AND cs.EndDate >= CURRENT_DATE
    ) THEN
        RAISE EXCEPTION 'Запис та купівля персональних тренувань доступні лише клієнтам з активним абонементом клубу.';
    END IF;

    -- Валідація зали (наявність та активний статус)
    IF NOT EXISTS (
        SELECT 1 FROM Halls WHERE ID_Hall = p_hall_id AND IsActive = TRUE
    ) THEN
        RAISE EXCEPTION 'Обраний зал не існує або закритий на обслуговування.';
    END IF;

    -- Валідація тренера
    IF NOT EXISTS (
        SELECT 1 FROM Coaches WHERE ID_Coach = p_coach_id
    ) THEN
        RAISE EXCEPTION 'Тренера не знайдено.';
    END IF;

    -- Валідація конфлікту розкладу для клієнта на цей час (інтервал 60 хвилин)
    DECLARE
        v_conflict_info TEXT;
    BEGIN
        -- 1. Перевірка на перетин з іншими персональними тренуваннями клієнта
        SELECT FORMAT('Персональне тренування (ID: %s, дата та час: %s - %s)',
                      pt.ID_Personal,
                      pt.TrainingDateTime,
                      (pt.TrainingDateTime + INTERVAL '60 minutes')::time)
        INTO v_conflict_info
        FROM PersonalTrainings pt
        JOIN Sales s ON pt.ID_Sale = s.ID_Sale
        WHERE s.ID_Client = v_client_id
          AND pt.TrainingStatus <> 'Cancelled'
          AND p_training_datetime < (pt.TrainingDateTime + INTERVAL '60 minutes')
          AND (p_training_datetime + INTERVAL '60 minutes') > pt.TrainingDateTime
        LIMIT 1;

        IF v_conflict_info IS NOT NULL THEN
            RAISE EXCEPTION 'У вас вже заплановано інше тренування на цей час (конфлікт із %)', v_conflict_info;
        END IF;

        -- 2. Перевірка на перетин з груповими заняттями клієнта
        SELECT FORMAT('Групове заняття (ID бронювання: %s, ID екземпляра: %s, дата: %s, час: %s - %s)',
                      gcb.ID_Booking,
                      gci.ID_Instance,
                      gci.ClassDate,
                      (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime))::time,
                      (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))::time)
        INTO v_conflict_info
        FROM GroupClassBookings gcb
        JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
        JOIN GroupClassInstances gci ON gcb.ID_Instance = gci.ID_Instance
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        WHERE s.ID_Client = v_client_id
          AND gcb.BookingStatus <> 'Cancelled'
          AND gci.ClassStatus <> 'Cancelled'
          AND p_training_datetime < (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))
          AND (p_training_datetime + INTERVAL '60 minutes') > (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime))
        LIMIT 1;

        IF v_conflict_info IS NOT NULL THEN
            RAISE EXCEPTION 'У вас вже заплановано інше тренування на цей час (конфлікт із %)', v_conflict_info;
        END IF;
    END;

    -- Створення чека продажу послуги персонального тренування
    SELECT res.out_sale_id, res.out_final_price
    INTO v_sale_id, v_final_price
    FROM fn_process_sale_with_promo(v_client_id, 'Personal training', NULL, p_promo_code, p_manager_id) res;

    -- Вставка в PersonalTrainings (тригер trg_check_personal_training_coach_conflict здійснить перевірку зайнятості тренера)
    INSERT INTO PersonalTrainings (ID_Coach, ID_Hall, ID_Sale, TrainingDateTime, TrainingStatus)
    VALUES (p_coach_id, p_hall_id, v_sale_id, p_training_datetime, 'Scheduled')
    RETURNING ID_Personal INTO v_personal_id;

    RETURN QUERY SELECT v_personal_id, v_sale_id, v_final_price;
END;
$$;

-- 6.1. Реєстрація нового клієнта (Задача G1 / M1)
CREATE OR REPLACE FUNCTION sp_register_client(
    p_fullname VARCHAR,
    p_birthdate DATE,
    p_phone VARCHAR,
    p_gender VARCHAR,
    p_db_user VARCHAR,
    p_password VARCHAR,
    p_item_id INT,
    p_promo_code VARCHAR DEFAULT NULL,
    p_medical_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
    client_id INT,
    db_username VARCHAR,
    sale_id INT,
    subscription_id INT,
    final_price DECIMAL(10,2),
    end_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_client_id INT;
    v_sale_id INT;
    v_sub_id INT;
    v_base_price DECIMAL(10,2);
    v_discount INT := 0;
    v_promo_id INT := NULL;
    v_final_price DECIMAL(10,2);
    v_duration INT;
    v_max_freeze INT;
    v_end_date DATE;
    v_manager_id INT;
BEGIN
    -- Перевірка унікальності DB_User у системі PostgreSQL
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN
        RAISE EXCEPTION 'Користувач % вже зареєстрований у системі!', p_db_user;
    END IF;

    -- Створення користувача PostgreSQL з роллю client_role
    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE client_role', p_db_user, p_password);

    -- Додавання профілю клієнта
    INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User)
    VALUES (p_fullname, p_birthdate, p_phone, p_gender, p_db_user)
    RETURNING ID_Client INTO v_client_id;

    -- Додавання медичних застережень, якщо вказано
    IF p_medical_notes IS NOT NULL AND length(trim(p_medical_notes)) > 0 THEN
        INSERT INTO MedicalNotes (ID_Client, NotesText)
        VALUES (v_client_id, p_medical_notes);
    END IF;

    -- Перевірка товару/абонемента у прайсі
    SELECT Price INTO v_base_price FROM PriceList WHERE ID_Item = p_item_id;
    IF v_base_price IS NULL THEN
        RAISE EXCEPTION 'Позицію з ID % не знайдено в PriceList!', p_item_id;
    END IF;

    -- Перевірка промокоду
    IF p_promo_code IS NOT NULL AND length(trim(p_promo_code)) > 0 THEN
        SELECT ID_Promo, DiscountPercent INTO v_promo_id, v_discount
        FROM PromoCodes
        WHERE CodeText = p_promo_code AND ExpiryDate >= CURRENT_DATE;
    END IF;

    -- Розрахунок фінальної ціни
    IF v_discount > 0 THEN
        v_final_price := ROUND(v_base_price * (1.0 - (v_discount::NUMERIC / 100.0)), 2);
    ELSE
        v_final_price := v_base_price;
    END IF;

    -- Визначення відповідального менеджера (дефолтний менеджер із персоналу)
    SELECT ID_Staff INTO v_manager_id 
    FROM Staff 
    WHERE ID_Position IN (SELECT ID_Position FROM Positions WHERE PositionName IN ('Менеджер клієнтів', 'Менеджер по роботі з клієнтами', 'Адміністратор', 'HR Менеджер'))
    ORDER BY ID_Staff
    LIMIT 1;

    IF v_manager_id IS NULL THEN
        SELECT ID_Staff INTO v_manager_id FROM Staff LIMIT 1;
    END IF;

    -- Фіксація факту продажу
    INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate)
    VALUES (v_client_id, p_item_id, v_final_price, v_manager_id, CURRENT_TIMESTAMP)
    RETURNING ID_Sale INTO v_sale_id;

    -- Фіксація застосованого промокоду
    IF v_promo_id IS NOT NULL THEN
        INSERT INTO AppliedPromo (ID_Sale, ID_Promo)
        VALUES (v_sale_id, v_promo_id);
    END IF;

    -- Якщо це абонемент (наявний у PriceListSubs), активуємо підписку
    SELECT DurationDays, MaxFreezingDays INTO v_duration, v_max_freeze
    FROM PriceListSubs WHERE ID_Item = p_item_id;

    IF FOUND THEN
        v_end_date := CURRENT_DATE + v_duration;
        INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays)
        VALUES (v_sale_id, CURRENT_DATE, v_end_date, 'Active', v_max_freeze)
        RETURNING ID_ClientSub INTO v_sub_id;
    ELSE
        v_end_date := NULL;
        v_sub_id := NULL;
    END IF;

    RETURN QUERY SELECT v_client_id, p_db_user, v_sale_id, v_sub_id, v_final_price, v_end_date;
END;
$$;

-- 6.2. Прийом тренера на роботу (Задача HR1)
CREATE OR REPLACE FUNCTION sp_hire_coach(
    p_fullname VARCHAR,
    p_birthdate DATE,
    p_phone VARCHAR,
    p_spec_id INT,
    p_db_user VARCHAR,
    p_password VARCHAR,
    p_bio TEXT DEFAULT NULL
)
RETURNS TABLE (
    staff_id INT,
    coach_id INT,
    db_username VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_staff_id INT;
    v_coach_id INT;
    v_pos_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN
        RAISE EXCEPTION 'Користувач % вже існує!', p_db_user;
    END IF;

    -- Створення акаунту тренера
    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE coach_role', p_db_user, p_password);

    -- Посада тренера
    SELECT ID_Position INTO v_pos_id FROM Positions WHERE PositionName ILIKE '%тренер%' ORDER BY ID_Position LIMIT 1;
    IF v_pos_id IS NULL THEN
        RAISE EXCEPTION 'Посаду тренера не знайдено в Positions!';
    END IF;

    -- Вставка у Staff
    INSERT INTO Staff (FullName, BirthDate, Phone, ID_Position, DB_User, HireDate)
    VALUES (p_fullname, p_birthdate, p_phone, v_pos_id, p_db_user, CURRENT_DATE)
    RETURNING ID_Staff INTO v_staff_id;

    -- Вставка у Coaches
    INSERT INTO Coaches (ID_Staff, ID_Spec, Biography)
    VALUES (v_staff_id, p_spec_id, p_bio)
    RETURNING ID_Coach INTO v_coach_id;

    RETURN QUERY SELECT v_staff_id, v_coach_id, p_db_user;
END;
$$;

-- 6.3. Прийом менеджера клієнтів на роботу (Задача HR4)
CREATE OR REPLACE FUNCTION sp_hire_manager(
    p_fullname VARCHAR,
    p_birthdate DATE,
    p_phone VARCHAR,
    p_db_user VARCHAR,
    p_password VARCHAR,
    p_position_name VARCHAR DEFAULT 'Адміністратор',
    p_hire_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    staff_id INT,
    db_username VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_staff_id INT;
    v_pos_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN
        RAISE EXCEPTION 'Користувач % вже існує!', p_db_user;
    END IF;

    -- Створення акаунту менеджера
    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE manager_role', p_db_user, p_password);

    SELECT ID_Position INTO v_pos_id FROM Positions WHERE PositionName ILIKE '%' || p_position_name || '%' LIMIT 1;
    IF v_pos_id IS NULL THEN
        SELECT ID_Position INTO v_pos_id FROM Positions LIMIT 1;
    END IF;

    INSERT INTO Staff (FullName, BirthDate, Phone, ID_Position, DB_User, HireDate)
    VALUES (p_fullname, p_birthdate, p_phone, v_pos_id, p_db_user, p_hire_date)
    RETURNING ID_Staff INTO v_staff_id;

    RETURN QUERY SELECT v_staff_id, p_db_user;
END;
$$;

-- 6.4. Звільнення працівника та блокування доступу до БД (Задачі HR3, HR6)
CREATE OR REPLACE FUNCTION sp_fire_employee(
    p_staff_id INT,
    p_fire_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_db_user VARCHAR;
BEGIN
    SELECT DB_User INTO v_db_user FROM Staff WHERE ID_Staff = p_staff_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Працівника з ID % не знайдено!', p_staff_id;
    END IF;

    UPDATE Staff SET FireDate = p_fire_date WHERE ID_Staff = p_staff_id;

    -- Блокування входу до PostgreSQL
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_db_user) THEN
        EXECUTE format('ALTER ROLE %I NOLOGIN', v_db_user);
    END IF;
END;
$$;

-- 6.5. Створення облікового запису клієнта (безпечно через SECURITY DEFINER для Менеджера)
CREATE OR REPLACE FUNCTION sp_create_client_user(
    p_db_user VARCHAR,
    p_password VARCHAR
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = p_db_user) THEN
        RAISE EXCEPTION 'Користувач з логіном "%" вже існує в системі.', p_db_user;
    END IF;

    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE client_role', p_db_user, p_password);
END;
$$;

-- 6.6. Заморозка абонемента клієнтом (Задача Cl3, SECURITY DEFINER)
CREATE OR REPLACE PROCEDURE sp_freeze_client_subscription(
    p_client_sub_id    INTEGER,
    p_freeze_start_date DATE,
    p_freeze_end_date   DATE,
    p_reason            VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_freeze_days      INTEGER;
    v_remaining_days   INTEGER;
    v_old_end_date     DATE;
    v_current_status   VARCHAR(20);
    v_sub_exists       BOOLEAN := FALSE;
BEGIN
    v_freeze_days := p_freeze_end_date - p_freeze_start_date;
    IF v_freeze_days <= 0 THEN
        RAISE EXCEPTION 'Дата закінчення заморозки повинна бути пізнішою за дату початку.';
    END IF;

    -- Перевіряємо, що абонемент існує і належить поточному користувачу сесії (SESSION_USER)
    SELECT cs.RemainingFreezingDays, cs.EndDate, cs.CurrentStatus
    INTO v_remaining_days, v_old_end_date, v_current_status
    FROM ClientSubscriptions cs
    JOIN Sales s ON cs.ID_Sale = s.ID_Sale
    JOIN Clients c ON s.ID_Client = c.ID_Client
    WHERE cs.ID_ClientSub = p_client_sub_id 
      AND c.DB_User = SESSION_USER
    FOR UPDATE OF cs;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Активний абонемент не знайдено або він не належить поточному користувачу.';
    END IF;

    IF v_current_status <> 'Active' THEN
        RAISE EXCEPTION 'Заморозити можна лише активний абонемент. Поточний статус: %', v_current_status;
    END IF;

    IF v_remaining_days < v_freeze_days THEN
        RAISE EXCEPTION 'Недостатньо доступних днів заморозки. Залишок: %, запитано: %', v_remaining_days, v_freeze_days;
    END IF;

    -- 1. Фіксуємо запис у журналі заморозок
    INSERT INTO FreezingLogs (ID_ClientSub, FreezeStartDate, FreezeEndDate, Reason)
    VALUES (p_client_sub_id, p_freeze_start_date, p_freeze_end_date, p_reason);

    -- 2. Оновлюємо статус, залишок днів та зсуваємо дату закінчення абонемента
    UPDATE ClientSubscriptions
    SET EndDate = v_old_end_date + (v_freeze_days * INTERVAL '1 day'),
        RemainingFreezingDays = v_remaining_days - v_freeze_days,
        CurrentStatus = 'Frozen'
    WHERE ID_ClientSub = p_client_sub_id;
END;
$$;

-- 6.7. Дострокове розморожування абонемента клієнтом (Задача Cl3, SECURITY DEFINER)
CREATE OR REPLACE PROCEDURE sp_unfreeze_client_subscription(
    p_client_sub_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_freezing_id       INTEGER;
    v_freeze_start_date DATE;
    v_freeze_end_date   DATE;
    v_current_status    VARCHAR(20);
    v_used_days         INTEGER;
    v_unused_days       INTEGER;
BEGIN
    -- 1. Перевірка: абонемент існує, належить поточному клієнту (SESSION_USER) і його статус 'Frozen'
    SELECT cs.CurrentStatus
    INTO v_current_status
    FROM ClientSubscriptions cs
    JOIN Sales s ON cs.ID_Sale = s.ID_Sale
    JOIN Clients c ON s.ID_Client = c.ID_Client
    WHERE cs.ID_ClientSub = p_client_sub_id 
      AND c.DB_User = SESSION_USER
    FOR UPDATE OF cs;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Абонемент не знайдено або він не належить поточному клієнту.';
    END IF;

    IF v_current_status <> 'Frozen' THEN
        RAISE EXCEPTION 'Скасувати заморозку можна лише для замороженого абонемента. Поточний статус: %', v_current_status;
    END IF;

    -- 2. Знаходження останнього запису в FreezingLogs для цього ID_ClientSub
    SELECT ID_Freezing, FreezeStartDate, FreezeEndDate
    INTO v_freezing_id, v_freeze_start_date, v_freeze_end_date
    FROM FreezingLogs
    WHERE ID_ClientSub = p_client_sub_id
    ORDER BY ID_Freezing DESC
    LIMIT 1
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Запис про заморозку для даного абонемента не знайдено.';
    END IF;

    -- 3. Математика перерахунку
    IF CURRENT_DATE > v_freeze_start_date THEN
        v_used_days := CURRENT_DATE - v_freeze_start_date;
        v_unused_days := (v_freeze_end_date - v_freeze_start_date) - v_used_days;
        IF v_unused_days < 0 THEN
            v_unused_days := 0;
        END IF;

        UPDATE FreezingLogs
        SET FreezeEndDate = CURRENT_DATE
        WHERE ID_Freezing = v_freezing_id;
    ELSE
        -- CURRENT_DATE <= FreezeStartDate
        v_unused_days := v_freeze_end_date - v_freeze_start_date;

        DELETE FROM FreezingLogs
        WHERE ID_Freezing = v_freezing_id;
    END IF;

    -- 4. Оновлення абонемента: повернення днів, коригування EndDate та зміна статусу на Active
    UPDATE ClientSubscriptions
    SET RemainingFreezingDays = RemainingFreezingDays + v_unused_days,
        EndDate = EndDate - (v_unused_days * INTERVAL '1 day'),
        CurrentStatus = 'Active'
    WHERE ID_ClientSub = p_client_sub_id;
END;
$$;

-- 6.8. Запис на групове заняття (Задача Cl4 / M5, SECURITY DEFINER)
CREATE OR REPLACE PROCEDURE sp_book_group_class(
    p_instance_id INTEGER,
    p_sale_id     INTEGER DEFAULT NULL,
    p_client_id   INTEGER DEFAULT NULL,
    p_promo_code  VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_actual_attendance INTEGER;
    v_max_capacity      INTEGER;
    v_class_status      VARCHAR(20);
    v_sale_id           INTEGER := p_sale_id;
    v_client_id         INTEGER := p_client_id;
    v_is_client_user    BOOLEAN;
    v_target_start      TIMESTAMP;
    v_target_end        TIMESTAMP;
    v_conflict_info     TEXT;
BEGIN
    SELECT pg_has_role(SESSION_USER, 'client_role', 'MEMBER') INTO v_is_client_user;

    IF v_is_client_user THEN
        SELECT ID_Client INTO v_client_id
        FROM Clients
        WHERE DB_User = SESSION_USER;

        IF v_client_id IS NULL THEN
            RAISE EXCEPTION 'Профіль клієнта не знайдено для поточного користувача.';
        END IF;
    ELSE
        IF v_client_id IS NULL AND v_sale_id IS NOT NULL THEN
            SELECT ID_Client INTO v_client_id FROM Sales WHERE ID_Sale = v_sale_id;
        END IF;

        IF v_client_id IS NULL THEN
            RAISE EXCEPTION 'Не вказано клієнта для запису на групове заняття.';
        END IF;
    END IF;

    -- Централізована перевірка активного абонемента в ядрі БД
    IF NOT EXISTS (
        SELECT 1
        FROM ClientSubscriptions cs
        JOIN Sales s ON cs.ID_Sale = s.ID_Sale
        WHERE s.ID_Client = v_client_id
          AND cs.CurrentStatus = 'Active'
          AND cs.EndDate >= CURRENT_DATE
    ) THEN
        RAISE EXCEPTION 'Запис та купівля групових занять доступні лише клієнтам з активним абонементом клубу.';
    END IF;

    -- Отримання та валідація часу цільового групового заняття
    SELECT
        gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime),
        gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')
    INTO v_target_start, v_target_end
    FROM GroupClassInstances gci
    JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
    WHERE gci.ID_Instance = p_instance_id;

    IF v_target_start IS NULL THEN
        RAISE EXCEPTION 'Екземпляр групового заняття (ID: %) не знайдено.', p_instance_id;
    END IF;

    -- Валідація конфлікту розкладу клієнта ДО створення чека продажу
    -- 1. Перевірка на перетин з іншими груповими заняттями клієнта
    SELECT FORMAT('Групове заняття (ID бронювання: %s, ID екземпляра: %s, дата: %s, час: %s - %s)',
                  gcb.ID_Booking,
                  other_gci.ID_Instance,
                  other_gci.ClassDate,
                  (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime))::time,
                  (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime) + (other_gst.DurationMinutes * INTERVAL '1 minute'))::time)
    INTO v_conflict_info
    FROM GroupClassBookings gcb
    JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
    JOIN GroupClassInstances other_gci ON gcb.ID_Instance = other_gci.ID_Instance
    JOIN GroupScheduleTemplates other_gst ON other_gci.ID_Template = other_gst.ID_Template
    WHERE s.ID_Client = v_client_id
      AND gcb.BookingStatus <> 'Cancelled'
      AND other_gci.ClassStatus <> 'Cancelled'
      AND other_gci.ID_Instance <> p_instance_id
      AND v_target_start < (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime) + (other_gst.DurationMinutes * INTERVAL '1 minute'))
      AND v_target_end > (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime))
    LIMIT 1;

    IF v_conflict_info IS NOT NULL THEN
        RAISE EXCEPTION 'У вас вже заплановано інше тренування на цей час (конфлікт із %)', v_conflict_info;
    END IF;

    -- 2. Перевірка на перетин з персональними тренуваннями клієнта
    SELECT FORMAT('Персональне тренування (ID: %s, дата та час: %s - %s)',
                  pt.ID_Personal,
                  pt.TrainingDateTime,
                  (pt.TrainingDateTime + INTERVAL '60 minutes')::time)
    INTO v_conflict_info
    FROM PersonalTrainings pt
    JOIN Sales s ON pt.ID_Sale = s.ID_Sale
    WHERE s.ID_Client = v_client_id
      AND pt.TrainingStatus <> 'Cancelled'
      AND v_target_start < (pt.TrainingDateTime + INTERVAL '60 minutes')
      AND v_target_end > pt.TrainingDateTime
    LIMIT 1;

    IF v_conflict_info IS NOT NULL THEN
        RAISE EXCEPTION 'У вас вже заплановано інше тренування на цей час (конфлікт із %)', v_conflict_info;
    END IF;

    -- Перевірка дублікату запису на той самий екземпляр
    IF EXISTS (
        SELECT 1 FROM GroupClassBookings gcb
        JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
        WHERE gcb.ID_Instance = p_instance_id 
          AND s.ID_Client = v_client_id 
          AND gcb.BookingStatus = 'Scheduled'
    ) THEN
        RAISE EXCEPTION 'Ви вже записані на це групове заняття.';
    END IF;

    -- Якщо чек продажу не було передано, генеруємо його через fn_process_sale_with_promo
    IF v_sale_id IS NULL THEN
        SELECT res.out_sale_id INTO v_sale_id
        FROM fn_process_sale_with_promo(v_client_id, 'Group training', NULL, p_promo_code, NULL) res;
    ELSE
        -- Перевіряємо належність переданого чека клієнту
        IF NOT EXISTS (SELECT 1 FROM Sales WHERE ID_Sale = v_sale_id AND ID_Client = v_client_id) THEN
            RAISE EXCEPTION 'Чек або абонемент не знайдено або він не належить вказаному клієнту.';
        END IF;
    END IF;

    -- Точне блокування екземпляра заняття та перевірка місткості
    SELECT gci.ActualAttendance, h.MaxCapacity, gci.ClassStatus
    INTO v_actual_attendance, v_max_capacity, v_class_status
    FROM GroupClassInstances gci
    JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
    JOIN Halls h ON gst.ID_Hall = h.ID_Hall
    WHERE gci.ID_Instance = p_instance_id
    FOR UPDATE OF gci;

    IF v_actual_attendance IS NULL THEN
        RAISE EXCEPTION 'Екземпляр групового заняття (ID: %) не знайдено.', p_instance_id;
    END IF;

    IF v_class_status <> 'Scheduled' THEN
        RAISE EXCEPTION 'Запис неможливий: статус заняття "%".', v_class_status;
    END IF;

    IF v_actual_attendance >= v_max_capacity THEN
        RAISE EXCEPTION 'Вільних місць у залі немає (місткість: % ос., записано: % ос.).', v_max_capacity, v_actual_attendance;
    END IF;

    -- Створення запису бронювання
    INSERT INTO GroupClassBookings (ID_Instance, ID_Sale, BookingStatus)
    VALUES (p_instance_id, v_sale_id, 'Scheduled');

    -- Інкремент лічильника відвідувачів
    UPDATE GroupClassInstances
    SET ActualAttendance = ActualAttendance + 1
    WHERE ID_Instance = p_instance_id;
END;
$$;

-- 6.8. Скасування запису на групове заняття (Задача Cl6, SECURITY DEFINER)
CREATE OR REPLACE PROCEDURE sp_cancel_group_booking(
    p_booking_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_instance_id    INTEGER;
    v_is_client_user BOOLEAN;
BEGIN
    SELECT pg_has_role(SESSION_USER, 'client_role', 'MEMBER') INTO v_is_client_user;
    IF v_is_client_user THEN
        SELECT gcb.ID_Instance INTO v_instance_id
        FROM GroupClassBookings gcb
        JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
        JOIN Clients c ON s.ID_Client = c.ID_Client
        WHERE gcb.ID_Booking = p_booking_id 
          AND gcb.BookingStatus = 'Scheduled'
          AND c.DB_User = SESSION_USER;

        IF v_instance_id IS NULL THEN
            RAISE EXCEPTION 'Активний запис на групове заняття не знайдено або він не належить поточному клієнту.';
        END IF;
    ELSE
        SELECT gcb.ID_Instance INTO v_instance_id
        FROM GroupClassBookings gcb
        WHERE gcb.ID_Booking = p_booking_id 
          AND gcb.BookingStatus = 'Scheduled';

        IF v_instance_id IS NULL THEN
            RAISE EXCEPTION 'Активний запис на групове заняття не знайдено.';
        END IF;
    END IF;

    UPDATE GroupClassBookings 
    SET BookingStatus = 'Cancelled' 
    WHERE ID_Booking = p_booking_id;

    UPDATE GroupClassInstances 
    SET ActualAttendance = GREATEST(ActualAttendance - 1, 0) 
    WHERE ID_Instance = v_instance_id;
END;
$$;

-- 6.9. Щотижнева автогенерація екземплярів групових занять (SECURITY DEFINER)
CREATE OR REPLACE PROCEDURE sp_generate_weekly_group_instances(
    p_weeks_ahead INTEGER DEFAULT 1
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_monday DATE;
    v_target_date DATE;
    v_weeks INTEGER := COALESCE(p_weeks_ahead, 1);
    gst RECORD;
BEGIN
    IF v_weeks < 0 THEN
        v_weeks := 0;
    END IF;

    -- Визначити понеділок поточного тижня
    v_monday := date_trunc('week', CURRENT_DATE)::DATE;

    -- Для зміщення тижнів w IN 0..v_weeks
    FOR w IN 0..v_weeks LOOP
        FOR gst IN 
            SELECT ID_Template, DayOfWeek, StartTime 
            FROM GroupScheduleTemplates 
            ORDER BY ID_Template 
        LOOP
            v_target_date := v_monday + (w * 7) + (gst.DayOfWeek - 1);
            IF v_target_date >= CURRENT_DATE THEN
                IF NOT EXISTS (
                    SELECT 1 FROM GroupClassInstances 
                    WHERE ID_Template = gst.ID_Template AND ClassDate = v_target_date
                ) THEN
                    INSERT INTO GroupClassInstances (ID_Template, ClassDate, ClassStartTime, ClassStatus, ActualAttendance)
                    VALUES (gst.ID_Template, v_target_date, gst.StartTime, 'Scheduled', 0);
                END IF;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;

-- Права на виклик збережених функцій
GRANT EXECUTE ON FUNCTION fn_process_sale_with_promo(INT, VARCHAR, INT, VARCHAR, INT) TO client_role, manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_purchase_subscription(INT, INT, VARCHAR, INT, DATE) TO client_role, manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_book_personal_training(INT, INT, INT, TIMESTAMP, VARCHAR, INT) TO client_role, manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_register_client TO guest, manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_create_client_user(VARCHAR, VARCHAR) TO manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_hire_coach TO hr_role, director_role;
GRANT EXECUTE ON FUNCTION sp_hire_manager TO hr_role, director_role;
GRANT EXECUTE ON FUNCTION sp_fire_employee TO hr_role, director_role;
GRANT EXECUTE ON PROCEDURE sp_freeze_client_subscription(INTEGER, DATE, DATE, VARCHAR) TO client_role;
GRANT EXECUTE ON PROCEDURE sp_unfreeze_client_subscription(INTEGER) TO client_role;
GRANT EXECUTE ON PROCEDURE sp_book_group_class(INTEGER, INTEGER, INTEGER, VARCHAR) TO client_role, manager_role, director_role;
GRANT EXECUTE ON PROCEDURE sp_cancel_group_booking(INTEGER) TO client_role, manager_role;
GRANT EXECUTE ON PROCEDURE sp_generate_weekly_group_instances(INTEGER) TO director_role, manager_role, client_role, coach_role;

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
CREATE POLICY staff_clients_access ON Clients TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_med_access ON MedicalNotes TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_sales_access ON Sales TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_promo_access ON AppliedPromo TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_subs_access ON ClientSubscriptions TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_freeze_access ON FreezingLogs TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_visits_access ON Visits TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_pt_access ON PersonalTrainings TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_ptlog_access ON PT_Changelog TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_pttime_access ON PT_TimeChangeDetails TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY staff_bookings_access ON GroupClassBookings TO manager_role, director_role USING (TRUE) WITH CHECK (TRUE);

-- 7.2. Політики для Клієнта (client_role) - бачить і змінює виключно власні записи
CREATE POLICY client_self_view ON Clients FOR SELECT TO client_role USING (DB_User = SESSION_USER);
CREATE POLICY client_self_update ON Clients FOR UPDATE TO client_role USING (DB_User = SESSION_USER) WITH CHECK (DB_User = SESSION_USER);

CREATE POLICY client_med_access ON MedicalNotes FOR ALL TO client_role 
    USING (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER))
    WITH CHECK (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER));

CREATE POLICY client_sales_access ON Sales FOR ALL TO client_role 
    USING (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER))
    WITH CHECK (ID_Client IN (SELECT ID_Client FROM Clients WHERE DB_User = SESSION_USER));

CREATE POLICY client_promo_access ON AppliedPromo FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

CREATE POLICY client_subs_access ON ClientSubscriptions FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

CREATE POLICY client_freeze_access ON FreezingLogs FOR ALL TO client_role 
    USING (ID_ClientSub IN (SELECT cs.ID_ClientSub FROM ClientSubscriptions cs JOIN Sales s ON cs.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_ClientSub IN (SELECT cs.ID_ClientSub FROM ClientSubscriptions cs JOIN Sales s ON cs.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

CREATE POLICY client_visits_select ON Visits FOR SELECT TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

CREATE POLICY client_pt_access ON PersonalTrainings FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

CREATE POLICY client_ptlog_access ON PT_Changelog FOR ALL TO client_role 
    USING (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

CREATE POLICY client_pttime_access ON PT_TimeChangeDetails FOR ALL TO client_role 
    USING (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Sales s ON pt.ID_Sale = s.ID_Sale JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

CREATE POLICY client_bookings_access ON GroupClassBookings FOR ALL TO client_role 
    USING (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER))
    WITH CHECK (ID_Sale IN (SELECT s.ID_Sale FROM Sales s JOIN Clients c ON s.ID_Client = c.ID_Client WHERE c.DB_User = SESSION_USER));

-- 7.3. Політики для Тренера (coach_role) - бачить закріплені за ним заняття, запити та клієнтів
CREATE POLICY coach_pt_access ON PersonalTrainings TO coach_role
    USING (ID_Coach IN (SELECT c.ID_Coach FROM Coaches c JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER))
    WITH CHECK (ID_Coach IN (SELECT c.ID_Coach FROM Coaches c JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

CREATE POLICY coach_group_bookings_view ON GroupClassBookings FOR SELECT TO coach_role
    USING (ID_Instance IN (SELECT gci.ID_Instance FROM GroupClassInstances gci JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template JOIN Coaches c ON gst.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

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

CREATE POLICY coach_ptlog_access ON PT_Changelog FOR ALL TO coach_role
    USING (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER))
    WITH CHECK (ID_Personal IN (SELECT pt.ID_Personal FROM PersonalTrainings pt JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

CREATE POLICY coach_pttime_access ON PT_TimeChangeDetails FOR ALL TO coach_role
    USING (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER))
    WITH CHECK (ID_PTLog IN (SELECT cl.ID_PTLog FROM PT_Changelog cl JOIN PersonalTrainings pt ON cl.ID_Personal = pt.ID_Personal JOIN Coaches c ON pt.ID_Coach = c.ID_Coach JOIN Staff s ON c.ID_Staff = s.ID_Staff WHERE s.DB_User = SESSION_USER));

-- ------------------------------------------------------------------------------
-- 8. ПРЕДСТАВЛЕННЯ (VIEWS) ЗА ЛАБОРАТОРНИМИ РОБОТАМИ
-- ------------------------------------------------------------------------------

-- Представлення для визначення частки групових клієнтів, які також беруть індивідуальні тренування (з Lab_4.sql)
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

GRANT SELECT ON v_GroupIndividualClientsShare TO director_role, manager_role;

-- ------------------------------------------------------------------------------
-- 9. ПОЧАТКОВІ ДАНІ (SEED DATA)
-- ------------------------------------------------------------------------------

INSERT INTO Positions (PositionName) VALUES 
('Менеджер клієнтів'), 
('Старший тренер'), 
('Тренер'), 
('HR Менеджер'), 
('Директор'),
('Адміністратор')
ON CONFLICT (PositionName) DO NOTHING;

INSERT INTO Specializations (SpecName) VALUES 
('Тренажерний зал'), 
('Йога'), 
('Пілатес'), 
('Кроссфіт'), 
('Бокс'), 
('Плавання'), 
('Стретчинг'), 
('Дитячий фітнес')
ON CONFLICT (SpecName) DO NOTHING;

INSERT INTO Halls (HallName, MaxCapacity) VALUES 
('Main Gym', 50), 
('Yoga Studio', 15), 
('Fight Zone', 20), 
('Crossfit Box', 25), 
('Pool', 30), 
('Pilates Room', 10), 
('Kids Zone', 15)
ON CONFLICT (HallName) DO NOTHING;

INSERT INTO ClassTypes (TypeName) VALUES 
('Hatha Yoga'), 
('Power Crossfit'), 
('Zumba'), 
('Morning Stretch'), 
('Box Training'), 
('Aqua Aerobics'), 
('Pilates Basics'), 
('Body Pump'), 
('Total Abs'), 
('Tai Chi')
ON CONFLICT (TypeName) DO NOTHING;

INSERT INTO Staff (FullName, BirthDate, Phone, ID_Position, DB_User, HireDate) VALUES 
('Іваненко Іван Іванович', '1985-05-15', '+380501111111', 5, 'boss_ivan', '2020-01-01'),
('Петренко Петро Петрович', '1990-08-20', '+380502222222', 1, 'manager_petro', '2021-03-10'),
('Сидоренко Олена Сергіївна', '1992-12-05', '+380503333333', 4, 'admin_olena', '2022-05-15'),
('Коваленко Андрій Вікторович', '1988-03-25', '+380504444444', 2, 'coach_maksym', '2021-01-20'),
('Бондаренко Марія Олександрівна', '1995-07-12', '+380505555555', 3, 'coach_mariya', '2023-02-01'),
('Мельник Дмитро Ігорович', '1991-11-30', '+380506666666', 3, 'coach_dima', '2022-09-15'),
('Шевченко Юлія Володимирівна', '1994-04-18', '+380507777777', 3, 'coach_yulia', '2023-05-10'),
('Ткаченко Сергій Михайлович', '1987-09-05', '+380508888888', 3, 'coach_serg', '2021-11-20'),
('Кузнецов Олег Петрович', '1993-06-10', '+380509999901', 3, 'coach_oleg', '2023-01-10'),
('Лебедєва Анна Сергіївна', '1995-09-22', '+380509999902', 3, 'coach_anna', '2023-05-15')
ON CONFLICT (Phone) DO NOTHING;

INSERT INTO Coaches (ID_Staff, ID_Spec, Biography) VALUES 
(4, 1, 'Майстер спорту. Учасник олімпіади 2024 та зайняв 4-е місце серед 32 учасників.'),
(5, 2, 'Сертифікований інструктор з Хатха-йоги. Проходила навчання в Індії.'),
(6, 4, 'Багаторазовий призер регіональних змагань з Crossfit.'),
(7, 7, 'Професійна артистка балету в минулому. Експерт зі стретчингу.'),
(8, 5, 'Кандидат у майстри спорту з боксу. Має глибокі знання техніки ударів.'),
(9, 1, 'Спеціаліст з функціонального тренінгу та корекції постави.'),
(10, 3, 'Дипломований реабілітолог та інструктор з пілатесу.')
ON CONFLICT (ID_Staff) DO NOTHING;

INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User) VALUES 
('Остапенко Віталій Сергійович', '1998-02-14', '+380671111111', 'Male', 'user_oleksandr'),
('Клименко Ганна Миколаївна', '2000-05-20', '+380672222222', 'Female', 'client_hanna'),
('Павленко Максим Андрійович', '1995-11-30', '+380673333333', 'Male', 'client_maksym'),
('Дмитренко Ольга Володимирівна', '1992-04-12', '+380674444444', 'Female', 'client_olga'),
('Савченко Ігор Олександрович', '1988-08-25', '+380675555555', 'Male', 'client_igor'),
('Руденко Світлана Петрівна', '1996-03-18', '+380676666666', 'Female', 'client_svitlana'),
('Кузьменко Денис Віталійович', '1991-09-05', '+380677777777', 'Male', 'client_denis'),
('Жук Катерина Іванівна', '1994-12-22', '+380678888888', 'Female', 'client_kateryna'),
('Поліщук Артем Дмитрович', '1997-07-12', '+380679999999', 'Male', 'client_artem'),
('Білоус Наталія Юріївна', '1993-01-05', '+380670000000', 'Female', 'client_nataliya')
ON CONFLICT (Phone) DO NOTHING;

INSERT INTO MedicalNotes (ID_Client, NotesText) VALUES 
(2, 'Грижа в поперековому відділі хребта. Заборонені осьові навантаження та стрибки.'),
(4, 'Астма. Потребує постійного доступу до інгалятора під час тренувань.'),
(6, 'Травма коліна (меніск). Рекомендовано уникати глибоких присідань та великих ваг.'),
(8, 'Гіпертонія 1 ступеня. Потрібно контролювати пульс та уникати тривалих нахилів головою вниз.'),
(10, 'Вагітність. Спеціалізована програма, виключення вправ на м''язи преса.')
ON CONFLICT (ID_Client) DO NOTHING;

INSERT INTO PriceList (ItemName, Category, Price, Description) VALUES 
('Базовий абонемент (1 місяць)', 'Membership', 1200.00, 'Доступ до тренажерного залу на 30 днів.'),
('Піврічний абонемент (Стандарт)', 'Membership', 6000.00, '6 місяців занять.'),
('Річний безліміт (Gold)', 'Membership', 10000.00, '12 місяців занять.'),
('Персональне тренування з експертом', 'Personal training', 400.00, 'Індивідуальне заняття 60 хв.'),
('Разове групове заняття', 'Group training', 200.00, 'Одне групове заняття.'),
('Дитяче тренування (Kids Fitness)', 'Group training', 150.00, 'Заняття для дітей.')
ON CONFLICT (ItemName) DO NOTHING;

INSERT INTO PriceListSubs (ID_Item, DurationDays, MaxFreezingDays) VALUES 
(1, 30, 7),
(2, 180, 30), 
(3, 365, 60)
ON CONFLICT (ID_Item) DO NOTHING;

INSERT INTO PromoCodes (CodeText, DiscountPercent, ExpiryDate) VALUES 
('OPEN10', 10, '2026-12-31'), 
('SALE30', 30, '2026-06-01')
ON CONFLICT (CodeText) DO NOTHING;

-- Продажі абонементів (ID 1-6)
INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) VALUES 
(1, 1, 1200, 2, '2026-05-01 10:00'),
(2, 2, 6000, 2, '2026-01-10 12:00'),
(3, 3, 10000, 2, '2026-01-01 09:00'),
(4, 1, 1080, 2, '2026-04-15 11:00'),
(7, 1, 1200, 2, '2026-05-10 15:00'),
(10, 1, 1200, 2, '2026-05-20 18:00');

-- Продажі персональних тренувань (ID 7-19)
INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) VALUES 
(5, 4, 400, 3, '2026-05-10 10:00'), 
(9, 4, 400, 3, '2026-05-12 11:00'), 
(1, 4, 360, 2, '2026-05-15 09:00'), 
(2, 4, 400, 3, '2026-05-18 14:00'), 
(5, 4, 400, 3, '2026-05-26 10:00'),
(6, 4, 400, 3, '2026-05-26 14:00'),
(7, 4, 400, 3, '2026-05-27 10:00'), 
(2, 4, 400, 3, '2026-05-27 11:00'), 
(9, 4, 400, 3, '2026-05-28 12:00'), 
(10, 4, 400, 3, '2026-05-28 13:00'),
(1, 4, 400, 3, '2026-05-29 09:00'), 
(2, 4, 400, 3, '2026-05-29 10:00'), 
(3, 4, 400, 3, '2026-05-29 11:00');

-- Продажі групових занять (ID 20-41)
INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) VALUES 
(6, 5, 200, 3, '2026-05-20 10:00'), 
(3, 5, 200, 3, '2026-05-21 11:00'), 
(4, 5, 140, 2, '2026-05-22 12:00'), 
(1, 5, 200, 3, '2026-05-23 09:00'), 
(2, 5, 200, 3, '2026-05-24 14:00'), 
(3, 5, 200, 3, '2026-05-24 15:00'), 
(4, 5, 200, 3, '2026-05-25 10:00'), 
(7, 5, 200, 3, '2026-05-26 11:00'), 
(8, 5, 200, 3, '2026-05-26 12:00'), 
(9, 5, 200, 3, '2026-05-27 13:00'), 
(10, 5, 200, 3, '2026-05-27 14:00'),
(1, 5, 200, 3, '2026-05-27 15:00'),
(8, 6, 150, 3, '2026-05-20 10:00'), 
(9, 6, 150, 3, '2026-05-21 11:00'), 
(10, 6, 150, 3, '2026-05-22 12:00'), 
(5, 6, 150, 3, '2026-05-23 13:00'), 
(6, 6, 150, 3, '2026-05-24 14:00'), 
(4, 6, 150, 3, '2026-05-25 15:00'), 
(5, 6, 150, 3, '2026-05-26 09:00'), 
(1, 6, 150, 3, '2026-05-26 10:00'), 
(2, 6, 150, 3, '2026-05-26 11:00'), 
(3, 6, 150, 3, '2026-05-26 12:00');

INSERT INTO AppliedPromo (ID_Sale, ID_Promo) VALUES 
(4, 1), 
(9, 1), 
(22, 2), 
(32, 1)
ON CONFLICT (ID_Sale) DO NOTHING;

INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays) VALUES 
(1, '2026-05-01', '2026-05-31', 'Active', 7),
(2, '2026-01-10', '2026-07-10', 'Active', 23),
(3, '2026-01-01', '2027-01-01', 'Active', 50),
(4, '2026-04-15', '2026-05-15', 'Expired', 0),
(5, '2026-05-10', '2026-06-09', 'Frozen', 0),
(6, '2026-05-20', '2026-06-19', 'Active', 7)
ON CONFLICT (ID_Sale) DO NOTHING;

INSERT INTO FreezingLogs (ID_ClientSub, FreezeStartDate, FreezeEndDate, Reason) VALUES 
(2, '2026-03-01', '2026-03-08', 'Відпустка'),
(3, '2026-02-10', '2026-02-20', 'Хвороба (ГРВІ)'),
(5, '2026-05-24', '2026-05-31', 'Відрядження');

INSERT INTO PersonalTrainings (ID_Coach, ID_Hall, ID_Sale, TrainingDateTime, TrainingStatus) VALUES 
(1, 1, 7,  '2026-05-12 10:00', 'Completed'),
(3, 4, 8,  '2026-05-14 18:30', 'Completed'),
(1, 1, 9,  '2026-05-18 11:00', 'Completed'),
(2, 2, 10, '2026-05-20 12:00', 'Completed'),
(4, 4, 11, '2026-05-26 10:00', 'Completed'),
(5, 1, 12, '2026-05-27 10:00', 'Scheduled'),
(6, 4, 13, '2026-05-27 19:00', 'Scheduled'),
(1, 1, 14, '2026-05-28 11:00', 'Scheduled'),
(2, 2, 15, '2026-05-28 14:00', 'Scheduled'),
(3, 4, 16, '2026-05-29 16:00', 'Scheduled'),
(1, 1, 17, '2026-05-25 10:00', 'Cancelled'), 
(2, 2, 18, '2026-05-26 09:00', 'Cancelled'), 
(3, 4, 19, '2026-05-30 18:00', 'Scheduled')
ON CONFLICT (ID_Sale) DO NOTHING;

INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp) VALUES 
(11, 'Cancel', 'Хвороба', 'Client', '2026-05-24 18:00'),
(12, 'Cancel', 'Термінова нарада', 'Client', '2026-05-26 08:15'),
(4, 'Reschedule', 'Участь у семінарі', 'Coach', '2026-05-19 14:00');

INSERT INTO PT_TimeChangeDetails (ID_PTLog, OldDateTime, NewDateTime) VALUES 
(3, '2026-05-20 10:00', '2026-05-20 12:00')
ON CONFLICT (ID_PTLog) DO NOTHING;

INSERT INTO GroupScheduleTemplates (ID_ClassType, DayOfWeek, StartTime, DurationMinutes, ID_Hall, ID_Coach) VALUES 
(1, 1, '09:00', 60, 2, 2), 
(2, 2, '18:00', 90, 4, 3), 
(4, 3, '08:00', 45, 2, 4), 
(3, 4, '19:00', 60, 3, 5), 
(5, 5, '17:00', 60, 1, 6), 
(7, 6, '11:00', 60, 6, 7),
(2, 4, '18:00', 60, 4, 1);

INSERT INTO GroupClassInstances (ID_Template, ClassDate, ClassStatus, ActualAttendance, ClassStartTime) VALUES 
(1, '2026-05-18', 'Scheduled', 3, '09:00'), 
(2, '2026-05-19', 'Scheduled', 1, '18:00'),
(3, '2026-05-20', 'Scheduled', 2, '08:00'), 
(4, '2026-05-25', 'Scheduled', 2, '19:00'),
(5, '2026-05-27', 'Scheduled', 0, '17:00'),
(6, '2026-05-28', 'Scheduled', 0, '11:00'),
(1, '2026-05-25', 'Cancelled', 0, '10:00'),
(7, '2026-05-28', 'Scheduled', 0, '18:00');

INSERT INTO GroupClassBookings (ID_Instance, ID_Sale, BookingStatus) VALUES 
(1, 20, 'Attended'), 
(2, 21, 'Attended'), 
(3, 22, 'Attended'), 
(4, 23, 'Attended'), 
(5, 24, 'Scheduled'), 
(6, 25, 'Scheduled'), 
(1, 26, 'Attended'), 
(1, 27, 'Cancelled'), 
(2, 28, 'Cancelled'), 
(3, 29, 'Cancelled'), 
(1, 32, 'No-show'), 
(2, 33, 'No-show'), 
(3, 34, 'No-show'), 
(3, 35, 'Attended'), 
(5, 36, 'Scheduled'), 
(6, 37, 'Scheduled'), 
(1, 38, 'Attended'), 
(4, 39, 'Attended'), 
(5, 40, 'Scheduled'), 
(7, 41, 'Cancelled')
ON CONFLICT (ID_Sale) DO NOTHING;

INSERT INTO Visits (ID_Hall, ID_Sale, CheckInTime) VALUES 
(1, 1, '2026-05-02 09:15'), 
(1, 1, '2026-05-04 10:00'), 
(1, 3, '2026-05-20 17:30'),
(1, 5, '2026-05-12 12:00'),
(1, 6, '2026-05-25 18:00'), 
(4, 3, '2026-05-26 10:00'),
(2, 4, '2026-05-05 09:00');

-- Спеціальні дані для тестування реляційних операцій (Lab_3)
INSERT INTO Sales (ID_Client, ID_Item, SalePrice, ID_Manager, SaleDate) 
VALUES (1, 4, 400.00, 3, '2026-05-26 15:00');

INSERT INTO PersonalTrainings (ID_Coach, ID_Hall, ID_Sale, TrainingDateTime, TrainingStatus)
VALUES (1, 1, (SELECT MAX(ID_Sale) FROM Sales), '2026-05-27 17:00', 'Scheduled');

-- ==============================================================================
-- 10. ТРИГЕРИ ТА ФУНКЦІЇ БІЗНЕС-ЛОГІКИ (LAB_5)
-- ==============================================================================

-- 10.1. Тригерна функція для взаємного контролю конфліктів розкладу тренера
CREATE OR REPLACE FUNCTION check_coach_schedule_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_coach_id         INTEGER;
    v_start_time       TIMESTAMP;
    v_end_time         TIMESTAMP;
    v_conflict_found   BOOLEAN := FALSE;
    v_conflict_info    TEXT;
BEGIN
    IF LOWER(TG_TABLE_NAME) = 'personaltrainings' THEN
        IF NEW.TrainingStatus = 'Cancelled' THEN
            RETURN NEW;
        END IF;

        v_coach_id   := NEW.ID_Coach;
        v_start_time := NEW.TrainingDateTime;
        v_end_time   := NEW.TrainingDateTime + INTERVAL '60 minutes';

        SELECT
            TRUE,
            FORMAT('Групове заняття (ID екземпляра: %s, дата: %s, час: %s - %s)',
                   gci.ID_Instance,
                   gci.ClassDate,
                   (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime))::time,
                   (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))::time)
        INTO v_conflict_found, v_conflict_info
        FROM GroupClassInstances gci
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        WHERE gst.ID_Coach = v_coach_id
          AND gci.ClassStatus <> 'Cancelled'
          AND v_start_time < (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))
          AND (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime)) < v_end_time
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити індивідуальне тренування: тренер (ID: %) вже зайнятий у цей час. Конфліктна подія: %',
                v_coach_id, v_conflict_info;
        END IF;

    ELSIF LOWER(TG_TABLE_NAME) = 'groupclassinstances' THEN
        IF NEW.ClassStatus = 'Cancelled' THEN
            RETURN NEW;
        END IF;

        SELECT
            gst.ID_Coach,
            NEW.ClassDate + COALESCE(NEW.ClassStartTime, gst.StartTime),
            NEW.ClassDate + COALESCE(NEW.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')
        INTO v_coach_id, v_start_time, v_end_time
        FROM GroupScheduleTemplates gst
        WHERE gst.ID_Template = NEW.ID_Template;

        SELECT
            TRUE,
            FORMAT('Індивідуальне тренування (ID: %s, дата та час: %s - %s)',
                   pt.ID_Personal,
                   pt.TrainingDateTime,
                   (pt.TrainingDateTime + INTERVAL '60 minutes')::time)
        INTO v_conflict_found, v_conflict_info
        FROM PersonalTrainings pt
        WHERE pt.ID_Coach = v_coach_id
          AND pt.TrainingStatus <> 'Cancelled'
          AND pt.TrainingDateTime < v_end_time
          AND (pt.TrainingDateTime + INTERVAL '60 minutes') > v_start_time
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити групове заняття: тренер (ID: %) вже зайнятий у цей час. Конфліктна подія: %',
                v_coach_id, v_conflict_info;
        END IF;

    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_personal_training_coach_conflict ON PersonalTrainings;
CREATE TRIGGER trg_check_personal_training_coach_conflict
BEFORE INSERT OR UPDATE OF ID_Coach, TrainingDateTime, TrainingStatus
ON PersonalTrainings
FOR EACH ROW
EXECUTE FUNCTION check_coach_schedule_conflict();

DROP TRIGGER IF EXISTS trg_check_group_class_coach_conflict ON GroupClassInstances;
CREATE TRIGGER trg_check_group_class_coach_conflict
BEFORE INSERT OR UPDATE OF ID_Template, ClassDate, ClassStartTime, ClassStatus
ON GroupClassInstances
FOR EACH ROW
EXECUTE FUNCTION check_coach_schedule_conflict();

GRANT EXECUTE ON FUNCTION check_coach_schedule_conflict() TO PUBLIC;

-- 10.1-B. Тригерна функція для взаємного контролю конфліктів розкладу клієнта
CREATE OR REPLACE FUNCTION check_client_schedule_conflict()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_client_id        INTEGER;
    v_start_time       TIMESTAMP;
    v_end_time         TIMESTAMP;
    v_conflict_found   BOOLEAN := FALSE;
    v_conflict_info    TEXT;
BEGIN
    IF LOWER(TG_TABLE_NAME) = 'personaltrainings' THEN
        IF NEW.TrainingStatus = 'Cancelled' THEN
            RETURN NEW;
        END IF;

        -- Отримуємо ID_Client через таблицю Sales
        SELECT ID_Client INTO v_client_id
        FROM Sales
        WHERE ID_Sale = NEW.ID_Sale;

        IF v_client_id IS NULL THEN
            RETURN NEW;
        END IF;

        v_start_time := NEW.TrainingDateTime;
        v_end_time   := NEW.TrainingDateTime + INTERVAL '60 minutes';

        -- 1. Перевірка на перетин з іншими персональними тренуваннями цього ж клієнта
        SELECT
            TRUE,
            FORMAT('Персональне тренування (ID: %s, дата та час: %s - %s)',
                   pt.ID_Personal,
                   pt.TrainingDateTime,
                   (pt.TrainingDateTime + INTERVAL '60 minutes')::time)
        INTO v_conflict_found, v_conflict_info
        FROM PersonalTrainings pt
        JOIN Sales s ON pt.ID_Sale = s.ID_Sale
        WHERE s.ID_Client = v_client_id
          AND pt.TrainingStatus <> 'Cancelled'
          AND pt.ID_Personal IS DISTINCT FROM NEW.ID_Personal
          AND v_start_time < (pt.TrainingDateTime + INTERVAL '60 minutes')
          AND (v_start_time + INTERVAL '60 minutes') > pt.TrainingDateTime
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити тренування: у клієнта вже заплановане інше тренування на цей час. Конфліктна подія: %',
                v_conflict_info;
        END IF;

        -- 2. Перевірка на перетин з груповими заняттями цього ж клієнта
        SELECT
            TRUE,
            FORMAT('Групове заняття (ID екземпляра: %s, дата: %s, час: %s - %s)',
                   gci.ID_Instance,
                   gci.ClassDate,
                   (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime))::time,
                   (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))::time)
        INTO v_conflict_found, v_conflict_info
        FROM GroupClassBookings gcb
        JOIN Sales s ON gcb.ID_Sale = s.ID_Sale
        JOIN GroupClassInstances gci ON gcb.ID_Instance = gci.ID_Instance
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        WHERE s.ID_Client = v_client_id
          AND gcb.BookingStatus <> 'Cancelled'
          AND gci.ClassStatus <> 'Cancelled'
          AND v_start_time < (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))
          AND v_end_time > (gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime))
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити тренування: у клієнта вже заплановане інше тренування на цей час. Конфліктна подія: %',
                v_conflict_info;
        END IF;

    ELSIF LOWER(TG_TABLE_NAME) = 'groupclassbookings' THEN
        IF NEW.BookingStatus = 'Cancelled' THEN
            RETURN NEW;
        END IF;

        -- Отримуємо ID_Client через таблицю Sales
        SELECT ID_Client INTO v_client_id
        FROM Sales
        WHERE ID_Sale = NEW.ID_Sale;

        IF v_client_id IS NULL THEN
            RETURN NEW;
        END IF;

        -- Отримуємо час цільового групового заняття
        SELECT
            gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime),
            gci.ClassDate + COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute')
        INTO v_start_time, v_end_time
        FROM GroupClassInstances gci
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        WHERE gci.ID_Instance = NEW.ID_Instance;

        IF v_start_time IS NULL THEN
            RETURN NEW;
        END IF;

        -- 1. Перевірка на перетин з іншими груповими заняттями цього ж клієнта
        SELECT
            TRUE,
            FORMAT('Групове заняття (ID екземпляра: %s, дата: %s, час: %s - %s)',
                   other_gci.ID_Instance,
                   other_gci.ClassDate,
                   (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime))::time,
                   (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime) + (other_gst.DurationMinutes * INTERVAL '1 minute'))::time)
        INTO v_conflict_found, v_conflict_info
        FROM GroupClassBookings other_gcb
        JOIN Sales s ON other_gcb.ID_Sale = s.ID_Sale
        JOIN GroupClassInstances other_gci ON other_gcb.ID_Instance = other_gci.ID_Instance
        JOIN GroupScheduleTemplates other_gst ON other_gci.ID_Template = other_gst.ID_Template
        WHERE s.ID_Client = v_client_id
          AND other_gcb.BookingStatus <> 'Cancelled'
          AND other_gci.ClassStatus <> 'Cancelled'
          AND other_gcb.ID_Booking IS DISTINCT FROM NEW.ID_Booking
          AND other_gci.ID_Instance <> NEW.ID_Instance
          AND v_start_time < (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime) + (other_gst.DurationMinutes * INTERVAL '1 minute'))
          AND v_end_time > (other_gci.ClassDate + COALESCE(other_gci.ClassStartTime, other_gst.StartTime))
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити тренування: у клієнта вже заплановане інше тренування на цей час. Конфліктна подія: %',
                v_conflict_info;
        END IF;

        -- 2. Перевірка на перетин з персональними тренуваннями цього ж клієнта
        SELECT
            TRUE,
            FORMAT('Персональне тренування (ID: %s, дата та час: %s - %s)',
                   pt.ID_Personal,
                   pt.TrainingDateTime,
                   (pt.TrainingDateTime + INTERVAL '60 minutes')::time)
        INTO v_conflict_found, v_conflict_info
        FROM PersonalTrainings pt
        JOIN Sales s ON pt.ID_Sale = s.ID_Sale
        WHERE s.ID_Client = v_client_id
          AND pt.TrainingStatus <> 'Cancelled'
          AND v_start_time < (pt.TrainingDateTime + INTERVAL '60 minutes')
          AND v_end_time > pt.TrainingDateTime
        LIMIT 1;

        IF v_conflict_found THEN
            RAISE EXCEPTION '[SCHEDULE_CONFLICT] Неможливо призначити тренування: у клієнта вже заплановане інше тренування на цей час. Конфліктна подія: %',
                v_conflict_info;
        END IF;

    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_personal_training_client_conflict ON PersonalTrainings;
CREATE TRIGGER trg_check_personal_training_client_conflict
BEFORE INSERT OR UPDATE OF TrainingDateTime, TrainingStatus
ON PersonalTrainings
FOR EACH ROW
EXECUTE FUNCTION check_client_schedule_conflict();

DROP TRIGGER IF EXISTS trg_check_group_booking_client_conflict ON GroupClassBookings;
CREATE TRIGGER trg_check_group_booking_client_conflict
BEFORE INSERT OR UPDATE OF BookingStatus, ID_Instance
ON GroupClassBookings
FOR EACH ROW
EXECUTE FUNCTION check_client_schedule_conflict();

GRANT EXECUTE ON FUNCTION check_client_schedule_conflict() TO PUBLIC;

-- 10.2. Збережена функція для отримання тижневого розкладу тренера
CREATE OR REPLACE FUNCTION get_coach_weekly_schedule(
    p_coach_name       VARCHAR,
    p_week_start_date  DATE
)
RETURNS TABLE (
    training_date      DATE,
    day_of_week        TEXT,
    start_time         TIME,
    end_time           TIME,
    training_type      TEXT,
    activity_name      TEXT,
    hall_name          VARCHAR,
    client_or_details  TEXT,
    training_status    VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_coach_id INTEGER;
BEGIN
    SELECT c.ID_Coach INTO v_coach_id
    FROM Coaches c
    JOIN Staff s ON c.ID_Staff = s.ID_Staff
    WHERE LOWER(TRIM(s.FullName)) = LOWER(TRIM(p_coach_name));

    IF v_coach_id IS NULL THEN
        RAISE EXCEPTION 'Тренера з ПІБ "%" не знайдено в базі даних.', p_coach_name;
    END IF;

    RETURN QUERY
    WITH CombinedSchedule AS (
        SELECT
            gci.ClassDate AS training_date,
            CASE EXTRACT(ISODOW FROM gci.ClassDate)
                WHEN 1 THEN 'Понеділок'
                WHEN 2 THEN 'Вівторок'
                WHEN 3 THEN 'Середа'
                WHEN 4 THEN 'Четвер'
                WHEN 5 THEN 'П''ятниця'
                WHEN 6 THEN 'Субота'
                WHEN 7 THEN 'Неділя'
            END AS day_of_week,
            COALESCE(gci.ClassStartTime, gst.StartTime) AS start_time,
            (COALESCE(gci.ClassStartTime, gst.StartTime) + (gst.DurationMinutes * INTERVAL '1 minute'))::TIME AS end_time,
            'Групове заняття'::TEXT AS training_type,
            ct.TypeName::TEXT AS activity_name,
            h.HallName AS hall_name,
            FORMAT('Фактична відвідуваність: %s ос.', gci.ActualAttendance)::TEXT AS client_or_details,
            gci.ClassStatus::VARCHAR AS training_status
        FROM GroupClassInstances gci
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
        JOIN Halls h ON gst.ID_Hall = h.ID_Hall
        WHERE gst.ID_Coach = v_coach_id
          AND gci.ClassDate >= p_week_start_date
          AND gci.ClassDate < (p_week_start_date + INTERVAL '7 days')::DATE

        UNION ALL

        SELECT
            pt.TrainingDateTime::DATE AS training_date,
            CASE EXTRACT(ISODOW FROM pt.TrainingDateTime)
                WHEN 1 THEN 'Понеділок'
                WHEN 2 THEN 'Вівторок'
                WHEN 3 THEN 'Середа'
                WHEN 4 THEN 'Четвер'
                WHEN 5 THEN 'П''ятниця'
                WHEN 6 THEN 'Субота'
                WHEN 7 THEN 'Неділя'
            END AS day_of_week,
            pt.TrainingDateTime::TIME AS start_time,
            (pt.TrainingDateTime + INTERVAL '60 minutes')::TIME AS end_time,
            'Індивідуальне тренування'::TEXT AS training_type,
            'Персональне заняття'::TEXT AS activity_name,
            h.HallName AS hall_name,
            FORMAT('Клієнт: %s (тел: %s)', cl.FullName, cl.Phone)::TEXT AS client_or_details,
            pt.TrainingStatus::VARCHAR AS training_status
        FROM PersonalTrainings pt
        JOIN Halls h ON pt.ID_Hall = h.ID_Hall
        JOIN Sales s ON pt.ID_Sale = s.ID_Sale
        JOIN Clients cl ON s.ID_Client = cl.ID_Client
        WHERE pt.ID_Coach = v_coach_id
          AND pt.TrainingDateTime::DATE >= p_week_start_date
          AND pt.TrainingDateTime::DATE < (p_week_start_date + INTERVAL '7 days')::DATE
    )
    SELECT * 
    FROM CombinedSchedule
    ORDER BY training_date ASC, start_time ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_coach_weekly_schedule(VARCHAR, DATE) TO PUBLIC;

-- 10.3. Користувацька агрегатна функція середньої тривалості/завантаженості тренера
CREATE OR REPLACE FUNCTION coach_workload_accum(
    p_state    NUMERIC[],
    p_coach_id INTEGER,
    p_duration NUMERIC
)
RETURNS NUMERIC[]
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_coach_id IS NOT NULL AND p_duration IS NOT NULL AND p_duration > 0 THEN
        p_state[1] := p_state[1] + p_duration;
        p_state[2] := p_state[2] + 1;
    END IF;

    RETURN p_state;
END;
$$;

CREATE OR REPLACE FUNCTION coach_workload_final(
    p_state NUMERIC[]
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_state IS NULL OR p_state[2] = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND(p_state[1] / p_state[2], 2);
END;
$$;

DROP AGGREGATE IF EXISTS avg_coach_workload(INTEGER, NUMERIC);

CREATE AGGREGATE avg_coach_workload(INTEGER, NUMERIC) (
    SFUNC     = coach_workload_accum,
    STYPE     = NUMERIC[],
    FINALFUNC = coach_workload_final,
    INITCOND  = '{0, 0}'
);

GRANT EXECUTE ON FUNCTION coach_workload_accum(NUMERIC[], INTEGER, NUMERIC) TO PUBLIC;
GRANT EXECUTE ON FUNCTION coach_workload_final(NUMERIC[]) TO PUBLIC;
GRANT EXECUTE ON FUNCTION avg_coach_workload(INTEGER, NUMERIC) TO PUBLIC;
