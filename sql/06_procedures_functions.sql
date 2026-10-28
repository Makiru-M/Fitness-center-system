-- ------------------------------------------------------------------------------
-- 6. ЗБЕРЕЖЕНІ ПРОЦЕДУРИ ТА ФУНКЦІЇ (SECURITY DEFINER)
-- ------------------------------------------------------------------------------

-- Допоміжна функція валідації формату українського номера телефону (+380XXXXXXXXX)
CREATE OR REPLACE FUNCTION fn_validate_phone(p_phone VARCHAR)
RETURNS VOID
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_phone IS NULL OR p_phone !~ '^\+380\d{9}$' THEN
        RAISE EXCEPTION 'Некоректний формат номера телефону. Очікується формат +380XXXXXXXXX.';
    END IF;
END;
$$;

-- Допоміжна процедура створення системного облікового запису користувача PostgreSQL
CREATE OR REPLACE PROCEDURE sp_create_db_user(
    p_username VARCHAR,
    p_password VARCHAR,
    p_role_name VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF p_username IS NULL OR length(trim(p_username)) = 0 THEN
        RAISE EXCEPTION 'Логін користувача БД обов''язковий!';
    END IF;
    IF p_password IS NULL OR length(trim(p_password)) = 0 THEN
        RAISE EXCEPTION 'Пароль користувача обов''язковий!';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = trim(p_username)) THEN
        RAISE EXCEPTION 'Користувач % вже зареєстрований у системі!', trim(p_username);
    END IF;

    EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE %I', trim(p_username), p_password, p_role_name);
END;
$$;

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

    -- Валідація дати початку дії абонемента
    IF v_start_date IS NOT NULL AND v_start_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Дата початку дії абонемента не може бути в минулому.';
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

    IF v_active_end_date IS NOT NULL THEN
        IF (v_active_end_date - CURRENT_DATE) > 7 THEN
            RAISE EXCEPTION 'Оформити новий абонемент можна не раніше ніж за 7 днів до закінчення діючого (доступно з %).', (v_active_end_date - INTERVAL '7 days')::DATE;
        END IF;

        IF v_start_date IS NOT NULL AND v_start_date <= v_active_end_date THEN
            RAISE EXCEPTION 'Дата початку нового абонемента (%) не може перетинатися з діючим абонементом (діє до %).', v_start_date, v_active_end_date;
        END IF;

        IF v_start_date IS NULL THEN
            v_start_date := v_active_end_date + INTERVAL '1 day';
        END IF;
    ELSE
        IF v_start_date IS NULL THEN
            v_start_date := CURRENT_DATE;
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
    p_manager_id INT DEFAULT NULL,
    p_item_id INT DEFAULT NULL
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
    v_target_item_id INT := p_item_id;
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

    -- Валідація дати та часу тренування
    IF p_training_datetime < CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Дата та час персонального тренування не можуть бути в минулому.';
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

    -- Валідація категорії товару при вказаному p_item_id
    IF v_target_item_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM PriceList 
            WHERE ID_Item = v_target_item_id 
              AND Category = 'Personal training' 
              AND PriceEndDate IS NULL
        ) THEN
            RAISE EXCEPTION 'Обрана послуга не належить до активної категорії "Personal training"!';
        END IF;
    END IF;

    -- Створення чека продажу послуги персонального тренування (з урахуванням p_item_id або активного тарифу)
    IF v_target_item_id IS NOT NULL THEN
        SELECT res.out_sale_id, res.out_final_price
        INTO v_sale_id, v_final_price
        FROM fn_process_sale_with_promo(v_client_id, NULL, v_target_item_id, p_promo_code, p_manager_id) res;
    ELSE
        SELECT res.out_sale_id, res.out_final_price
        INTO v_sale_id, v_final_price
        FROM fn_process_sale_with_promo(v_client_id, 'Personal training', NULL, p_promo_code, p_manager_id) res;
    END IF;

    -- Вставка в PersonalTrainings:
    -- 1) trg_check_personal_training_sub_status перевірить статус абонемента клієнта (Active vs Frozen/відсутній)
    -- 2) trg_check_personal_training_coach_conflict перевірить зайнятість тренера
    -- 3) trg_check_personal_training_client_conflict перевірить зайнятість клієнта
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
    v_final_price DECIMAL(10,2);
    v_duration INT;
    v_max_freeze INT;
    v_end_date DATE;
BEGIN
    PERFORM fn_validate_phone(p_phone);

    -- Створення користувача PostgreSQL з роллю client_role через єдину процедуру
    CALL sp_create_db_user(p_db_user, p_password, 'client_role');

    -- Додавання профілю клієнта
    INSERT INTO Clients (FullName, BirthDate, Phone, Gender, DB_User)
    VALUES (p_fullname, p_birthdate, p_phone, p_gender, p_db_user)
    RETURNING ID_Client INTO v_client_id;

    -- Додавання медичних застережень, якщо вказано
    IF p_medical_notes IS NOT NULL AND length(trim(p_medical_notes)) > 0 THEN
        INSERT INTO MedicalNotes (ID_Client, NotesText)
        VALUES (v_client_id, p_medical_notes);
    END IF;

    -- Оформлення продажу та застосування промокоду
    SELECT out_sale_id, out_final_price
    INTO v_sale_id, v_final_price
    FROM fn_process_sale_with_promo(v_client_id, NULL, p_item_id, p_promo_code, NULL);

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
    PERFORM fn_validate_phone(p_phone);

    -- Створення акаунту тренера через єдину процедуру
    CALL sp_create_db_user(p_db_user, p_password, 'coach_role');

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
    p_position_name VARCHAR DEFAULT 'Менеджер клієнтів',
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
    PERFORM fn_validate_phone(p_phone);

    -- Створення акаунту менеджера через єдину процедуру
    CALL sp_create_db_user(p_db_user, p_password, 'manager_role');

    SELECT ID_Position INTO v_pos_id FROM Positions WHERE PositionName ILIKE '%' || p_position_name || '%' LIMIT 1;
    IF v_pos_id IS NULL THEN
        SELECT ID_Position INTO v_pos_id FROM Positions LIMIT 1;
    END IF;

    INSERT INTO Staff (FullName, BirthDate, Phone, ID_Position, DB_User, HireDate)
    VALUES (p_fullname, p_birthdate, p_phone, v_pos_id, p_db_user, COALESCE(p_hire_date, CURRENT_DATE))
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

    -- Захист від самозвільнення
    IF v_db_user = SESSION_USER THEN
        RAISE EXCEPTION 'Помилка безпеки: Співробітник не може звільнити сам себе!';
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
    CALL sp_create_db_user(p_db_user, p_password, 'client_role');
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
BEGIN
    IF p_freeze_start_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Дата початку заморозки не може бути в минулому.';
    END IF;

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

-- 6.7-B. Реєстрація відвідування залу (Check-in турнікета, Задача M4, SECURITY DEFINER)
CREATE OR REPLACE FUNCTION sp_register_visit(
    p_client_id INT,
    p_hall_id   INT
)
RETURNS TABLE (
    out_visit_id INT,
    out_client_id INT,
    out_client_name VARCHAR,
    out_hall_name VARCHAR,
    out_sub_status VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_client_name VARCHAR;
    v_hall_name   VARCHAR;
    v_hall_active BOOLEAN;
    v_has_active  BOOLEAN := FALSE;

    v_sale_id     INT;
    v_visit_id    INT;
    v_sub_status  VARCHAR(20);
BEGIN
    -- 1. Валідація зали
    SELECT HallName, IsActive INTO v_hall_name, v_hall_active
    FROM Halls
    WHERE ID_Hall = p_hall_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Зал з ID % не знайдено.', p_hall_id;
    END IF;

    IF NOT v_hall_active THEN
        RAISE EXCEPTION 'Зал "%" закритий на обслуговування або неактивний.', v_hall_name;
    END IF;

    -- 2. Валідація клієнта
    SELECT FullName INTO v_client_name
    FROM Clients
    WHERE ID_Client = p_client_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Клієнта з ID % не знайдено.', p_client_id;
    END IF;

    -- 3. Перевірка наявності діючого активного абонемента
    SELECT cs.ID_Sale, cs.CurrentStatus
    INTO v_sale_id, v_sub_status
    FROM ClientSubscriptions cs
    JOIN Sales s ON cs.ID_Sale = s.ID_Sale
    WHERE s.ID_Client = p_client_id
      AND cs.CurrentStatus = 'Active'
      AND cs.EndDate >= CURRENT_DATE
    ORDER BY cs.EndDate DESC
    LIMIT 1;

    IF FOUND THEN
        v_has_active := TRUE;
    ELSE
        -- Перевіряємо, чи є заморожений діючий абонемент
        IF EXISTS (
            SELECT 1
            FROM ClientSubscriptions cs
            JOIN Sales s ON cs.ID_Sale = s.ID_Sale
            WHERE s.ID_Client = p_client_id
              AND cs.CurrentStatus = 'Frozen'
              AND cs.EndDate >= CURRENT_DATE
        ) THEN
            RAISE EXCEPTION 'Вхід заблоковано: абонемент клієнта заморожено. Для відвідування необхідно розморозити абонемент.';
        ELSE
            RAISE EXCEPTION 'У клієнта немає активного дійсного абонемента для входу в зал!';
        END IF;
    END IF;

    -- 4. Реєстрація відвідування
    INSERT INTO Visits (ID_Hall, ID_Sale, CheckInTime)
    VALUES (p_hall_id, v_sale_id, CURRENT_TIMESTAMP)
    RETURNING ID_Visit INTO v_visit_id;

    RETURN QUERY SELECT v_visit_id, p_client_id, v_client_name, v_hall_name, v_sub_status;
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
    v_item_id           INTEGER;
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
        -- Підтягуємо ID_Item безпосередньо з ClassTypes обраного екземпляра заняття
        SELECT ct.ID_Item INTO v_item_id
        FROM GroupClassInstances gci
        JOIN GroupScheduleTemplates gst ON gci.ID_Template = gst.ID_Template
        JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
        WHERE gci.ID_Instance = p_instance_id;

        IF v_item_id IS NOT NULL THEN
            SELECT res.out_sale_id INTO v_sale_id
            FROM fn_process_sale_with_promo(v_client_id, NULL, v_item_id, p_promo_code, NULL) res;
        ELSE
            SELECT res.out_sale_id INTO v_sale_id
            FROM fn_process_sale_with_promo(v_client_id, 'Group training', NULL, p_promo_code, NULL) res;
        END IF;
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

    -- Створення запису бронювання:
    -- 1) trg_check_group_booking_sub_status перевірить статус абонемента (Active vs Frozen/відсутній)
    -- 2) trg_check_group_booking_client_conflict перевірить відсутність перетину часу з іншими тренуваннями клієнта
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
            SELECT gst.ID_Template, gst.DayOfWeek, gst.StartTime 
            FROM GroupScheduleTemplates gst
            JOIN ClassTypes ct ON gst.ID_ClassType = ct.ID_ClassType
            LEFT JOIN PriceList pl ON ct.ID_Item = pl.ID_Item
            WHERE pl.PriceEndDate IS NULL OR pl.ID_Item IS NULL
            ORDER BY gst.ID_Template 
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
GRANT EXECUTE ON FUNCTION sp_book_personal_training(INT, INT, INT, TIMESTAMP, VARCHAR, INT, INT) TO client_role, manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_register_client TO guest, manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_create_client_user(VARCHAR, VARCHAR) TO manager_role, director_role;
GRANT EXECUTE ON FUNCTION sp_hire_coach TO hr_role, director_role;
GRANT EXECUTE ON FUNCTION sp_hire_manager TO hr_role, director_role;
GRANT EXECUTE ON FUNCTION sp_fire_employee TO hr_role, director_role;
GRANT EXECUTE ON PROCEDURE sp_freeze_client_subscription(INTEGER, DATE, DATE, VARCHAR) TO client_role;
GRANT EXECUTE ON PROCEDURE sp_unfreeze_client_subscription(INTEGER) TO client_role;
GRANT EXECUTE ON FUNCTION sp_register_visit(INT, INT) TO manager_role, director_role;
GRANT EXECUTE ON PROCEDURE sp_book_group_class(INTEGER, INTEGER, INTEGER, VARCHAR) TO client_role, manager_role, director_role;
GRANT EXECUTE ON PROCEDURE sp_cancel_group_booking(INTEGER) TO client_role, manager_role;
GRANT EXECUTE ON PROCEDURE sp_generate_weekly_group_instances(INTEGER) TO director_role, manager_role, client_role, coach_role;

-- 6.10. Оновлення та версіонування тарифу прайс-листа (D10, SECURITY DEFINER)
CREATE OR REPLACE FUNCTION sp_update_price_tariff(
    p_item_id INT,
    p_new_price NUMERIC
)
RETURNS TABLE (
    old_item_id INT,
    new_item_id INT,
    item_name VARCHAR,
    new_price NUMERIC,
    effective_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_old_rec RECORD;
    v_new_id INT;
BEGIN
    IF p_new_price IS NULL OR p_new_price < 0 THEN
        RAISE EXCEPTION 'Ціна тарифу повинна бути невід''ємною!';
    END IF;

    SELECT ID_Item, ItemName, Category, Description, PriceStartDate, PriceEndDate
    INTO v_old_rec
    FROM PriceList
    WHERE ID_Item = p_item_id
    FOR UPDATE;

    IF v_old_rec.ID_Item IS NULL THEN
        RAISE EXCEPTION 'Тариф із ID % не знайдено в прайс-листі!', p_item_id;
    END IF;

    IF v_old_rec.PriceEndDate IS NOT NULL THEN
        RAISE EXCEPTION 'Тариф із ID % вже є закритим (історичним)!', p_item_id;
    END IF;

    UPDATE PriceList
    SET PriceEndDate = CURRENT_DATE
    WHERE ID_Item = p_item_id;

    INSERT INTO PriceList (ItemName, Category, Price, PriceStartDate, PriceEndDate, Description)
    VALUES (v_old_rec.ItemName, v_old_rec.Category, p_new_price, CURRENT_DATE, NULL, v_old_rec.Description)
    RETURNING ID_Item INTO v_new_id;

    UPDATE ClassTypes
    SET ID_Item = v_new_id
    WHERE ID_Item = p_item_id;

    UPDATE PriceListSubs
    SET ID_Item = v_new_id
    WHERE ID_Item = p_item_id;

    RETURN QUERY SELECT p_item_id, v_new_id, v_old_rec.ItemName, p_new_price, CURRENT_DATE;
END;
$$;

-- 6.11. Створення послуги під ключ з автоматичним налаштуванням зв'язків (D10, SECURITY DEFINER)
CREATE OR REPLACE FUNCTION sp_create_service_turnkey(
    p_item_name VARCHAR,
    p_category VARCHAR,
    p_price NUMERIC,
    p_description TEXT,
    -- Поля для Membership
    p_duration_days INT DEFAULT NULL,
    p_max_freezing_days INT DEFAULT NULL,
    -- Поля для Group training
    p_day_of_week INT DEFAULT NULL,
    p_start_time TIME DEFAULT NULL,
    p_duration_minutes INT DEFAULT NULL,
    p_hall_id INT DEFAULT NULL,
    p_coach_id INT DEFAULT NULL
)
RETURNS TABLE (
    item_id INT,
    classtype_id INT,
    template_id INT,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_item_id INT;
    v_classtype_id INT := NULL;
    v_template_id INT := NULL;
    v_duration_min INT := COALESCE(p_duration_minutes, 60);
BEGIN
    IF p_price IS NULL OR p_price < 0 THEN
        RAISE EXCEPTION 'Ціна послуги повинна бути невід''ємною!';
    END IF;

    IF p_item_name IS NULL OR length(trim(p_item_name)) = 0 THEN
        RAISE EXCEPTION 'Назва послуги не може бути порожньою!';
    END IF;

    IF p_category NOT IN ('Membership', 'Personal training', 'Group training', 'Extra') THEN
        RAISE EXCEPTION 'Некоректна категорія послуги: %!', p_category;
    END IF;

    -- Створюємо запис у PriceList
    INSERT INTO PriceList (ItemName, Category, Price, PriceStartDate, PriceEndDate, Description)
    VALUES (trim(p_item_name), p_category, p_price, CURRENT_DATE, NULL, p_description)
    RETURNING ID_Item INTO v_item_id;

    IF p_category = 'Membership' THEN
        IF p_duration_days IS NULL OR p_duration_days <= 0 THEN
            RAISE EXCEPTION 'Для категорії Membership тривалість абонемента (duration_days) є обов''язковою і повинна бути більшою за 0!';
        END IF;
        IF p_max_freezing_days IS NOT NULL AND p_max_freezing_days < 0 THEN
            RAISE EXCEPTION 'Кількість днів заморозки не може бути від''ємною!';
        END IF;

        INSERT INTO PriceListSubs (ID_Item, DurationDays, MaxFreezingDays)
        VALUES (v_item_id, p_duration_days, COALESCE(p_max_freezing_days, 0));

    ELSIF p_category = 'Group training' THEN
        -- Створюємо або прив'язуємо ClassTypes
        SELECT ID_ClassType INTO v_classtype_id
        FROM ClassTypes
        WHERE TypeName = trim(p_item_name);

        IF v_classtype_id IS NOT NULL THEN
            UPDATE ClassTypes
            SET ID_Item = v_item_id
            WHERE ID_ClassType = v_classtype_id;
        ELSE
            INSERT INTO ClassTypes (TypeName, ID_Item)
            VALUES (trim(p_item_name), v_item_id)
            RETURNING ID_ClassType INTO v_classtype_id;
        END IF;

        -- Якщо передано розклад, створюємо шаблон і генеруємо екземпляри
        IF p_day_of_week IS NOT NULL AND p_start_time IS NOT NULL AND p_hall_id IS NOT NULL AND p_coach_id IS NOT NULL THEN
            INSERT INTO GroupScheduleTemplates (ID_ClassType, DayOfWeek, StartTime, DurationMinutes, ID_Hall, ID_Coach)
            VALUES (v_classtype_id, p_day_of_week, p_start_time, v_duration_min, p_hall_id, p_coach_id)
            RETURNING ID_Template INTO v_template_id;

            CALL sp_generate_weekly_group_instances(1);
        END IF;

    END IF;

    RETURN QUERY SELECT v_item_id, v_classtype_id, v_template_id, 'Послугу успішно створено під ключ'::TEXT;
END;
$$;

-- Додаткові права на нові функції/процедури
GRANT EXECUTE ON FUNCTION sp_update_price_tariff(INT, NUMERIC) TO director_role;
GRANT EXECUTE ON FUNCTION sp_create_service_turnkey(VARCHAR, VARCHAR, NUMERIC, TEXT, INT, INT, INT, TIME, INT, INT, INT) TO director_role;
GRANT EXECUTE ON FUNCTION sp_book_personal_training(INT, INT, INT, TIMESTAMP, VARCHAR, INT, INT) TO client_role, manager_role, director_role;

-- 6.12. Деактивація / архівування послуги з прайсу (TICKET-062, Soft Delete, SECURITY DEFINER)
CREATE OR REPLACE FUNCTION sp_deactivate_price_item(
    p_item_id INT
)
RETURNS TABLE (
    item_id INT,
    item_name VARCHAR,
    status TEXT,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_item_name VARCHAR(100);
    v_price_end_date DATE;
BEGIN
    SELECT ItemName, PriceEndDate
    INTO v_item_name, v_price_end_date
    FROM PriceList
    WHERE ID_Item = p_item_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Послугу з ID % не знайдено в прайс-листі!', p_item_id;
    END IF;

    IF v_price_end_date IS NOT NULL THEN
        RAISE EXCEPTION 'Послуга з ID % вже вилучена з прайсу (архівна)!', p_item_id;
    END IF;

    UPDATE PriceList
    SET PriceEndDate = CURRENT_DATE
    WHERE ID_Item = p_item_id;

    RETURN QUERY SELECT 
        p_item_id, 
        v_item_name, 
        'Archived'::TEXT, 
        'Послугу успішно вилучено з активного прайсу.'::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION sp_deactivate_price_item(INT) TO director_role;

