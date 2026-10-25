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

