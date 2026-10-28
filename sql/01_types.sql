-- ------------------------------------------------------------------------------
-- 1. СТВОРЕННЯ КОРИСТУВАЛЬНИЦЬКИХ ТИПІВ (ENUM)
-- ------------------------------------------------------------------------------
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activity_status') THEN
        CREATE TYPE activity_status AS ENUM ('Scheduled', 'Completed', 'Cancelled', 'No-show', 'Attended');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'service_category') THEN
        CREATE TYPE service_category AS ENUM ('Membership', 'Personal training', 'Group training', 'Extra');
    END IF;
END
$$;
