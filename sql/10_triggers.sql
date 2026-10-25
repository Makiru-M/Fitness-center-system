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

-- 10.1-B. Тригер заборони Check-in у зал для заморожених або недійсних абонементів (TICKET-020)
CREATE OR REPLACE FUNCTION check_visit_active_sub()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_current_status VARCHAR(20);
    v_end_date       DATE;
BEGIN
    SELECT cs.CurrentStatus, cs.EndDate
    INTO v_current_status, v_end_date
    FROM ClientSubscriptions cs
    WHERE cs.ID_Sale = NEW.ID_Sale;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Абонемент за чеком % не знайдено або операція не пов''язана з абонементом.', NEW.ID_Sale;
    END IF;

    IF v_current_status = 'Frozen' THEN
        RAISE EXCEPTION 'Вхід заблоковано: абонемент клієнта заморожено. Для відвідування необхідно розморозити абонемент.';
    END IF;

    IF v_current_status <> 'Active' OR v_end_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'У клієнта немає активного дійсного абонемента для входу в зал!';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_visit_active_sub ON Visits;
CREATE TRIGGER trg_check_visit_active_sub
BEFORE INSERT ON Visits
FOR EACH ROW
EXECUTE FUNCTION check_visit_active_sub();

GRANT EXECUTE ON FUNCTION check_visit_active_sub() TO PUBLIC;

-- 10.1-C. Тригер перевірки статусу абонемента клієнта при бронюванні тренувань (TICKET-021, Database-First / DRY)
CREATE OR REPLACE FUNCTION fn_check_booking_client_subscription()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_client_id        INTEGER;
    v_latest_status    VARCHAR(20);
    v_sub_end_date     DATE;
BEGIN
    -- Визначаємо ID_Client за NEW.ID_Sale
    IF NEW.ID_Sale IS NOT NULL THEN
        SELECT ID_Client INTO v_client_id
        FROM Sales
        WHERE ID_Sale = NEW.ID_Sale;
    END IF;

    IF v_client_id IS NULL THEN
        RAISE EXCEPTION 'Неможливо перевірити абонемент: не вказано дійсний чек продажу або клієнта.';
    END IF;

    -- Знаходимо найактуальніший абонемент клієнта
    SELECT cs.CurrentStatus, cs.EndDate
    INTO v_latest_status, v_sub_end_date
    FROM ClientSubscriptions cs
    JOIN Sales s ON cs.ID_Sale = s.ID_Sale
    WHERE s.ID_Client = v_client_id
      AND cs.EndDate >= CURRENT_DATE
    ORDER BY cs.EndDate DESC, cs.ID_ClientSub DESC
    LIMIT 1;

    IF v_latest_status = 'Frozen' THEN
        RAISE EXCEPTION 'Запис неможливий: ваш абонемент заморожено. Будь ласка, розморозьте абонемент перед записом на тренування.';
    END IF;

    IF v_latest_status IS NULL OR v_latest_status <> 'Active' THEN
        RAISE EXCEPTION 'Запис неможливий: відсутній активний абонемент.';
    END IF;

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

-- ============================================================================
-- 10.1-F. Тригери заборони перенесення занять у минуле (TICKET-035)
-- ============================================================================

-- 1. Перевірка для деталей запиту на зміну розкладу (PT_TimeChangeDetails)
CREATE OR REPLACE FUNCTION fn_check_pt_timechange_past()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.NewDateTime <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Новий час тренування не може бути в минулому.';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_pt_timechange_past ON PT_TimeChangeDetails;
CREATE TRIGGER trg_check_pt_timechange_past
BEFORE INSERT OR UPDATE OF NewDateTime
ON PT_TimeChangeDetails
FOR EACH ROW
EXECUTE FUNCTION fn_check_pt_timechange_past();

GRANT EXECUTE ON FUNCTION fn_check_pt_timechange_past() TO PUBLIC;

-- 2. Перевірка для створення та оновлення часу тренування (PersonalTrainings)
CREATE OR REPLACE FUNCTION fn_check_pt_reschedule_past()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.TrainingStatus = 'Scheduled' AND NEW.TrainingDateTime < CURRENT_TIMESTAMP THEN
        IF TG_OP = 'INSERT' THEN
            RAISE EXCEPTION 'Неможливо запланувати тренування на час у минулому.';
        ELSE
            RAISE EXCEPTION 'Неможливо перенести тренування на час у минулому.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_pt_reschedule_past ON PersonalTrainings;
CREATE TRIGGER trg_check_pt_reschedule_past
BEFORE INSERT OR UPDATE OF TrainingDateTime
ON PersonalTrainings
FOR EACH ROW
EXECUTE FUNCTION fn_check_pt_reschedule_past();

GRANT EXECUTE ON FUNCTION fn_check_pt_reschedule_past() TO PUBLIC;

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


