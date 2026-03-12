USE master;
GO

IF DB_ID(N'BeautySalons') IS NOT NULL
BEGIN
    ALTER DATABASE BeautySalons SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BeautySalons;
    PRINT 'Delete';
END
GO
 
----------------------------

CREATE DATABASE BeautySalons
ON PRIMARY
(
    NAME = N'BeautySalons_Primary',
    FILENAME = 'C:\SQLData\Lab7\data1.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = N'BeautySalons_Log',
    FILENAME = 'C:\SQLData\Lab7\log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO


----------------------------

USE BeautySalons;

CREATE TABLE CLIENT
(
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE,
    LastName NVARCHAR(25) NOT NULL,
    FirstName NVARCHAR(25) NOT NULL,
    Gender TINYINT NOT NULL DEFAULT 0 CHECK (Gender IN (0, 1)),
);
GO

CREATE TABLE MASTER
(
    MasterID INT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE,
    LastName NVARCHAR(25) NOT NULL,
    FirstName NVARCHAR(25) NOT NULL,
    Specialization TINYINT NULL,
    SkillLevel TINYINT NULL DEFAULT 3 CHECK (SkillLevel IN (1, 2, 3, 4, 5))
);
GO

CREATE TABLE SERVICE
(
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceName NVARCHAR(50) NOT NULL UNIQUE,
    Price MONEY NOT NULL,
    Duration SMALLINT NOT NULL,
    Category TINYINT NULL,
    Description NVARCHAR(255) NULL
);
GO

CREATE TABLE SALON
(
    SalonID INT IDENTITY(1,1) PRIMARY KEY,
    Address NVARCHAR(100) NOT NULL UNIQUE,
    OpeningHours NVARCHAR(50) NULL,
    PhoneNumber VARCHAR(15) NULL,
    Category TINYINT NULL
);
GO

CREATE TABLE APPOINTMENT
(
    ClientID INT NOT NULL,
    MasterID INT NOT NULL,
    SalonID INT NOT NULL,
    ServiceID INT NOT NULL,
    StartDateTime SMALLDATETIME NOT NULL,
    Status TINYINT NOT NULL DEFAULT 0 CHECK (Status IN (0, 1, 2, 3)),
    Price MONEY NULL,
    Rating TINYINT NULL DEFAULT 0 CHECK (Rating IN (0, 1, 2, 3, 4, 5)),
    PRIMARY KEY (ClientID, MasterID, SalonID, ServiceID, StartDateTime),
    FOREIGN KEY (ClientID) REFERENCES CLIENT(ClientID) ON DELETE CASCADE,
    FOREIGN KEY (MasterID) REFERENCES MASTER(MasterID) ON DELETE CASCADE,
    FOREIGN KEY (SalonID) REFERENCES SALON(SalonID) ON DELETE CASCADE,
    FOREIGN KEY (ServiceID) REFERENCES SERVICE(ServiceID) ON DELETE CASCADE
);
GO

CREATE TABLE MASTER_SERVICE
(
    MasterID INT NOT NULL,
    ServiceID INT NOT NULL,
    PRIMARY KEY (MasterID, ServiceID),
    FOREIGN KEY (MasterID) REFERENCES MASTER(MasterID) ON DELETE CASCADE,
    FOREIGN KEY (ServiceID) REFERENCES SERVICE(ServiceID) ON DELETE CASCADE
);
GO

INSERT INTO CLIENT
    (PhoneNumber, LastName, FirstName, Gender)
VALUES
    ('+79161234567', 'Иванова', 'Мария', 1),
    ('+79169876543', 'Петров', 'Алексей', 0),
    ('+79165544332', 'Сидорова', 'Ольга', 1);
SELECT *
FROM CLIENT;
GO

INSERT INTO MASTER
    (PhoneNumber, LastName, FirstName, Specialization, SkillLevel)
VALUES
    ('+79167778899', 'Кузнецова', 'Анна', 1, 5),
    ('+79166665544', 'Смирнов', 'Дмитрий', 2, 4),
    ('+79164443322', 'Волкова', 'Елена', 3, 5);
SELECT *
FROM MASTER;
GO

INSERT INTO SERVICE
    (ServiceName, Price, Duration, Category, Description)
VALUES
    ('Стрижка женская', 1500.00, 60, 1, 'Модная стрижка с укладкой'),
    ('Cтрижка мужская', 800.00, 30, 1, 'Классическая мужская стрижка'),
    ('Mаникюр', 1200.00, 45, 2, 'Аппаратный маникюр с покрытием'),
    ('Педикюр', 1500.00, 60, 2, 'Аппаратный педикюр с покрытием'),
    ('Окрашивание волос', 2500.00, 120, 1, 'Сложное окрашивание с тонированием');
SELECT *
FROM SERVICE;
GO

INSERT INTO SALON
    (Address, OpeningHours, PhoneNumber, Category)
VALUES
    ('ул. Пушкина, д.10', '09:00-21:00', '+74951234567', 1),
    ('пр. Ленина, д.25', '10:00-20:00', '+74959876543', 2),
    ('ул. Гагарина, д.15', '08:00-22:00', '+74957654321', 1);
SELECT *
FROM SALON;
GO

INSERT INTO MASTER_SERVICE
    (MasterID, ServiceID)
VALUES
    (1, 1),
    (1, 3),
    (2, 2),
    (3, 1),
    (3, 3),
    (1, 4),
    (2, 5),
    (3, 5);
SELECT *
FROM MASTER_SERVICE;
GO

INSERT INTO APPOINTMENT
    (ClientID, MasterID, SalonID, ServiceID, StartDateTime, Status, Price, Rating)
VALUES
    (1, 1, 1, 1, '20250320 10:00', 1, 1500.00, 5),
    (2, 2, 1, 2, '20250320 11:00', 1, 800.00, 4),
    (3, 3, 2, 3, '20250321 14:00', 0, 1200.00, NULL),
    (1, 1, 1, 3, '20250322 16:00', 0, 1200.00, NULL),
    (2, 3, 3, 5, '20250323 12:00', 0, 2500.00, NULL);
GO

-- 1. Представление на основе одной из таблиц
CREATE VIEW ActiveAppointments
AS
    SELECT
        ClientID,
        MasterID,
        SalonID,
        ServiceID,
        StartDateTime,
        Status,
        Price,
        Rating
    FROM APPOINTMENT
    WHERE Status IN (0, 1);
GO

SELECT *
FROM ActiveAppointments;
GO

-- 2. Представление на основе полей обеих связанных таблиц
CREATE VIEW AppointmentClientView
AS
    SELECT
        A.ClientID,
        C.FirstName + ' ' + C.LastName AS ClientFullName,
        C.PhoneNumber AS ClientPhone,
        CASE C.Gender 
        WHEN 0 THEN 'Мужской' 
        WHEN 1 THEN 'Женский' 
    END AS Gender,
        A.MasterID,
        A.SalonID,
        A.ServiceID,
        A.StartDateTime,
        CASE A.Status 
        WHEN 0 THEN 'Запланирована'
        WHEN 1 THEN 'Подтверждена' 
        WHEN 2 THEN 'Выполнена'
        WHEN 3 THEN 'Отменена'
    END AS StatusName,
        A.Price,
        A.Rating
    FROM APPOINTMENT A
        JOIN CLIENT C ON A.ClientID = C.ClientID;
GO

SELECT *
FROM AppointmentClientView;
GO

-- 3. Индекс с включением неключевых полей
CREATE INDEX IX_Appointment_StartDateTime  
ON APPOINTMENT (StartDateTime)  
INCLUDE (Status, Price);
GO

SELECT
    name AS IndexName,
    type_desc AS IndexType,
    is_unique AS IsUnique
FROM sys.indexes
WHERE object_id = OBJECT_ID('APPOINTMENT') AND name = 'IX_Appointment_StartDateTime';
GO

-- Пример запроса, который может быть ускорен с помощью этого индекса
SELECT
    StartDateTime,
    Status,
    Price,
    CASE Status 
        WHEN 0 THEN 'Запланирована'
        WHEN 1 THEN 'Подтверждена' 
        WHEN 2 THEN 'Выполнена'
        WHEN 3 THEN 'Отменена'
    END AS StatusName
FROM APPOINTMENT
WHERE StartDateTime BETWEEN '20250320 10:00' AND '20250322 10:00'
    AND Status = 1
ORDER BY StartDateTime;
GO

-- 4. Индексированное представление
CREATE VIEW MasterAppointmentCount
WITH
    SCHEMABINDING
AS
    SELECT
        MasterID,
        COUNT_BIG(*) AS AppointmentCount
    FROM dbo.APPOINTMENT
    GROUP BY MasterID;
GO

-- Создание уникального кластерного индекса для представления
CREATE UNIQUE CLUSTERED INDEX IX_MasterAppointmentCount  
ON MasterAppointmentCount (MasterID);
GO

SELECT
    M.MasterID,
    M.FirstName + ' ' + M.LastName AS MasterName,
    M.SkillLevel,
    MAC.AppointmentCount
FROM MasterAppointmentCount MAC
    JOIN MASTER M ON MAC.MasterID = M.MasterID
ORDER BY MAC.AppointmentCount DESC;
GO