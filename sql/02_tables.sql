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

-- Співробітники фітнес-клубу
CREATE TABLE IF NOT EXISTS Staff (
    ID_Staff SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    BirthDate DATE NOT NULL,
    Phone VARCHAR(15) NOT NULL UNIQUE CHECK (Phone ~ '^\+380\d{9}$'),
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
    Phone VARCHAR(15) NOT NULL UNIQUE CHECK (Phone ~ '^\+380\d{9}$'),
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
    ItemName VARCHAR(100) NOT NULL,
    Category VARCHAR(30) NOT NULL CHECK (Category IN ('Membership', 'Personal training', 'Group training', 'Extra')),
    Price DECIMAL(10, 2) NOT NULL CHECK (Price >= 0),
    PriceStartDate DATE NOT NULL DEFAULT CURRENT_DATE,
    PriceEndDate DATE DEFAULT NULL,
    Description TEXT
);

-- Специфікація абонементів (тривалість, заморозка)
CREATE TABLE IF NOT EXISTS PriceListSubs (
    ID_Item INTEGER PRIMARY KEY REFERENCES PriceList(ID_Item) ON DELETE CASCADE,
    DurationDays INTEGER NOT NULL CHECK (DurationDays > 0),
    MaxFreezingDays INTEGER NOT NULL DEFAULT 0 CHECK (MaxFreezingDays >= 0)
);

-- Види групових занять
CREATE TABLE IF NOT EXISTS ClassTypes (
    ID_ClassType SERIAL PRIMARY KEY,
    TypeName VARCHAR(50) NOT NULL UNIQUE,
    ID_Item INTEGER REFERENCES PriceList(ID_Item)
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
    ChangeTimestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending', 'Approved', 'Rejected'))
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

