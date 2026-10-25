SET session_replication_role = replica;

-- ------------------------------------------------------------------------------
-- 9. ПОЧАТКОВІ ДАНІ (SEED DATA)
-- ------------------------------------------------------------------------------

INSERT INTO Positions (PositionName) VALUES 
('Менеджер клієнтів'), 
('Старший тренер'), 
('Тренер'), 
('HR Менеджер'), 
('Директор')
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

-- ClassTypes are seeded after PriceList below

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
('Білоус Наталія Юріївна', '1993-01-05', '+380670000000', 'Female', 'client_nataliya'),
('Тестовий Клієнт Олександрович', '1995-05-15', '+380671234567', 'Male', 'test_client_login'),
('Особистий Клієнт Тест', '1998-08-20', '+380677654321', 'Female', 'my_login')
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
('Дитяче тренування (Kids Fitness)', 'Group training', 150.00, 'Заняття для дітей.'),
('Hatha Yoga', 'Group training', 200.00, 'Групове заняття Hatha Yoga'),
('Power Crossfit', 'Group training', 200.00, 'Групове заняття Power Crossfit'),
('Zumba', 'Group training', 200.00, 'Групове заняття Zumba'),
('Morning Stretch', 'Group training', 200.00, 'Групове заняття Morning Stretch'),
('Box Training', 'Group training', 200.00, 'Групове заняття Box Training'),
('Aqua Aerobics', 'Group training', 200.00, 'Групове заняття Aqua Aerobics'),
('Pilates Basics', 'Group training', 200.00, 'Групове заняття Pilates Basics'),
('Body Pump', 'Group training', 200.00, 'Групове заняття Body Pump'),
('Total Abs', 'Group training', 200.00, 'Групове заняття Total Abs'),
('Tai Chi', 'Group training', 200.00, 'Групове заняття Tai Chi')
ON CONFLICT DO NOTHING;

INSERT INTO ClassTypes (TypeName, ID_Item) VALUES 
('Hatha Yoga', 7), 
('Power Crossfit', 8), 
('Zumba', 9), 
('Morning Stretch', 10), 
('Box Training', 11), 
('Aqua Aerobics', 12), 
('Pilates Basics', 13), 
('Body Pump', 14), 
('Total Abs', 15), 
('Tai Chi', 16),
('Kids Fitness', 6)
ON CONFLICT (TypeName) DO UPDATE SET ID_Item = EXCLUDED.ID_Item;

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
ON CONFLICT DO NOTHING;

INSERT INTO ClientSubscriptions (ID_Sale, StartDate, EndDate, CurrentStatus, RemainingFreezingDays) VALUES 
(1, '2026-05-01', '2026-05-31', 'Active', 7),
(2, '2026-01-10', '2026-07-10', 'Active', 23),
(3, '2026-01-01', '2027-01-01', 'Active', 50),
(4, '2026-04-15', '2026-05-15', 'Expired', 0),
(5, '2026-05-10', '2026-06-09', 'Frozen', 0),
(6, '2026-05-20', '2026-06-19', 'Active', 7)
ON CONFLICT DO NOTHING;

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
ON CONFLICT DO NOTHING;

INSERT INTO PT_Changelog (ID_Personal, RequestType, Reason, ChangeInitiator, ChangeTimestamp, Status) VALUES 
(11, 'Cancel', 'Хвороба', 'Client', '2026-05-24 18:00', 'Approved'),
(12, 'Cancel', 'Термінова нарада', 'Client', '2026-05-26 08:15', 'Approved'),
(4, 'Reschedule', 'Участь у семінарі', 'Coach', '2026-05-19 14:00', 'Approved');

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
(2, 4, '18:00', 60, 4, 1),
(11, 6, '12:30', 60, 7, 7);

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
ON CONFLICT DO NOTHING;

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



SET session_replication_role = DEFAULT;
