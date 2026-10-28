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

-- 10.1-B. Допоміжна функція валідації активного абонемента за чеком (DRY / Database-First)
CREATE OR REPLACE FUNCTION fn_assert_active_subscription_by_sale(p_sale_id INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_current_status VARCHAR(20);
    v_end_date       DATE;
BEGIN
    IF p_sale_id IS NULL THEN
        RAISE EXCEPTION 'Неможливо перевірити абонемент: не вказано дійсний чек продажу.';
    END IF;

    SELECT cs.CurrentStatus, cs.EndDate
    INTO v_current_status, v_end_date
    FROM ClientSubscriptions cs
    WHERE cs.ID_Sale = p_sale_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Абонемент за чеком % не знайдено або операція не пов''язана з абонементом.', p_sale_id;
    END IF;

    IF v_current_status = 'Frozen' THEN
        RAISE EXCEPTION 'Вхід заблоковано: абонемент клієнта заморожено. Для відвідування необхідно розморозити абонемент.';
    END IF;

    IF v_current_status <> 'Active' OR v_end_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'У клієнта немає активного дійсного абонемента для входу в зал!';
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION fn_assert_active_subscription_by_sale(INT) TO PUBLIC;

-- 10.1-C. Тригер заборони Check-in у зал для заморожених або недійсних абонементів (TICKET-020)
CREATE OR REPLACE FUNCTION check_visit_active_sub()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    PERFORM fn_assert_active_subscription_by_sale(NEW.ID_Sale);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_visit_active_sub ON Visits;
CREATE TRIGGER trg_check_visit_active_sub
BEFORE INSERT ON Visits
FOR EACH ROW
EXECUTE FUNCTION check_visit_active_sub();

GRANT EXECUTE ON FUNCTION check_visit_active_sub() TO PUBLIC;

-- 10.1-D. Тригер перевірки статусу абонемента клієнта при бронюванні тренувань (TICKET-021, Database-First / DRY)
CREATE OR REPLACE FUNCTION fn_check_booking_client_subscription()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.ID_Sale IS NULL THEN
        RAISE EXCEPTION 'Неможливо перевірити абонемент: не вказано дійсний чек продажу або клієнта.';
    END IF;

    BEGIN
        PERFORM fn_assert_active_subscription_by_sale(NEW.ID_Sale);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE '%заморожено%' THEN
                RAISE EXCEPTION 'Запис неможливий: ваш абонемент заморожено. Будь ласка, розморозьте абонемент перед записом на тренування.';
            ELSIF SQLERRM LIKE '%немає активного дійсного абонемента%' OR SQLERRM LIKE '%не знайдено%' THEN
                RAISE EXCEPTION 'Запис неможливий: відсутній активний абонемент.';
            ELSE
                RAISE;
            END IF;
    END;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_personal_training_sub_status ON PersonalTrainings;
CREATE TRIGGER trg_check_personal_training_sub_status
BEFORE INSERT OR UPDATE OF ID_Sale
ON PersonalTrainings
FOR EACH ROW
EXECUTE FUNCTION fn_check_booking_client_subscription();

DROP TRIGGER IF EXISTS trg_check_group_booking_sub_status ON GroupClassBookings;
CREATE TRIGGER trg_check_group_booking_sub_status
BEFORE INSERT OR UPDATE OF ID_Sale
ON GroupClassBookings
FOR EACH ROW
EXECUTE FUNCTION fn_check_booking_client_subscription();

GRANT EXECUTE ON FUNCTION fn_check_booking_client_subscription() TO PUBLIC;

-- ============================================================================
-- 10.1-E. Уніфікований тригер заборони призначення або перенесення занять у минуле (TICKET-035, TICKET-116)
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_check_not_past_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_target_time TIMESTAMP;
BEGIN
    IF LOWER(TG_TABLE_NAME) = 'pt_timechangedetails' THEN
        v_target_time := NEW.NewDateTime;
        IF v_target_time <= CURRENT_TIMESTAMP THEN
            RAISE EXCEPTION 'Новий час тренування не може бути в минулому.';
        END IF;
    ELSIF LOWER(TG_TABLE_NAME) = 'personaltrainings' THEN
        v_target_time := NEW.TrainingDateTime;
        IF NEW.TrainingStatus = 'Scheduled' AND v_target_time < CURRENT_TIMESTAMP THEN
            IF TG_OP = 'INSERT' THEN
                RAISE EXCEPTION 'Неможливо запланувати тренування на час у минулому.';
            ELSE
                RAISE EXCEPTION 'Неможливо перенести тренування на час у минулому.';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_pt_timechange_past ON PT_TimeChangeDetails;
CREATE TRIGGER trg_check_pt_timechange_past
BEFORE INSERT OR UPDATE OF NewDateTime
ON PT_TimeChangeDetails
FOR EACH ROW
EXECUTE FUNCTION fn_check_not_past_timestamp();

DROP TRIGGER IF EXISTS trg_check_pt_reschedule_past ON PersonalTrainings;
CREATE TRIGGER trg_check_pt_reschedule_past
BEFORE INSERT OR UPDATE OF TrainingDateTime
ON PersonalTrainings
FOR EACH ROW
EXECUTE FUNCTION fn_check_not_past_timestamp();

GRANT EXECUTE ON FUNCTION fn_check_not_past_timestamp() TO PUBLIC;

-- Забезпечення видалення старих функцій
DROP FUNCTION IF EXISTS fn_check_pt_timechange_past();
DROP FUNCTION IF EXISTS fn_check_pt_reschedule_past();
-- ============================================================================
-- 10.1-G. Тригер заборони заморозки абонемента в минулому (TICKET-036)
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_check_freezing_dates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.FreezeStartDate < CURRENT_DATE THEN
        RAISE EXCEPTION 'Дата початку заморозки не може бути в минулому.';
    END IF;
    IF NEW.FreezeEndDate <= NEW.FreezeStartDate THEN
        RAISE EXCEPTION 'Дата закінчення заморозки повинна бути пізнішою за дату початку.';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_freezing_dates ON FreezingLogs;
CREATE TRIGGER trg_check_freezing_dates
BEFORE INSERT OR UPDATE OF FreezeStartDate, FreezeEndDate
ON FreezingLogs
FOR EACH ROW
EXECUTE FUNCTION fn_check_freezing_dates();

GRANT EXECUTE ON FUNCTION fn_check_freezing_dates() TO PUBLIC;


