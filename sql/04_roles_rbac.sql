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
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'test_client_login') THEN
        CREATE USER test_client_login WITH PASSWORD 'client123' IN ROLE client_role;
    ELSE
        ALTER USER test_client_login WITH PASSWORD 'client123';
        GRANT client_role TO test_client_login;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'my_login') THEN
        CREATE USER my_login WITH PASSWORD 'client123' IN ROLE client_role;
    ELSE
        ALTER USER my_login WITH PASSWORD 'client123';
        GRANT client_role TO my_login;
    END IF;

    FOR r IN SELECT unnest(ARRAY['client_hanna', 'client_maksym', 'client_olga', 'client_igor', 'client_svitlana', 'client_denis', 'client_kateryna', 'client_artem', 'client_nataliya']) AS usr
    LOOP
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = r.usr) THEN
            EXECUTE format('CREATE USER %I WITH PASSWORD %L IN ROLE client_role', r.usr, 'pass_123');
        END IF;
    END LOOP;
END
$$;

