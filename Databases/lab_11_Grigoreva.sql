USE master;
GO

IF DB_ID(N'BeautySalons') IS NOT NULL
BEGIN
    ALTER DATABASE BeautySalons SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BeautySalons;
END
GO

CREATE DATABASE BeautySalons
ON PRIMARY
(
    NAME = N'BeautySalons_Primary',
    FILENAME = 'C:\SQLData\Lab11\data1.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = N'BeautySalons_Log',
    FILENAME = 'C:\SQLData\Lab11\log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE BeautySalons;
GO

------------------------------------------------------

CREATE TABLE CLIENT
(
    ClientID INT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE,
    LastName NVARCHAR(25) NOT NULL,
    FirstName NVARCHAR(25) NOT NULL,
    Gender TINYINT NOT NULL DEFAULT 0 CHECK (Gender IN (0,1)),
    DateOfBirth SMALLDATETIME NULL
);
GO

CREATE TABLE MASTER
(
    MasterID INT IDENTITY(1,1) PRIMARY KEY,
    PhoneNumber VARCHAR(15) NOT NULL UNIQUE,
    LastName NVARCHAR(25) NOT NULL,
    FirstName NVARCHAR(25) NOT NULL,
    Specialization TINYINT NULL,
    SkillLevel TINYINT NULL DEFAULT 3 CHECK (SkillLevel BETWEEN 1 AND 5)
);
GO

CREATE TABLE SERVICE
(
    ServiceID INT IDENTITY(1,1) PRIMARY KEY,
    ServiceName NVARCHAR(50) NOT NULL UNIQUE,
    Price MONEY NOT NULL CHECK (Price >= 0),
    Duration SMALLINT NOT NULL CHECK (Duration > 0),
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
    Status TINYINT NOT NULL DEFAULT 0 CHECK (Status IN (0,1,2,3)), 
    Price MONEY NOT NULL CHECK (Price >= 0),
    Rating TINYINT NULL DEFAULT 0 CHECK (Rating BETWEEN 0 AND 5),
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

------------------------------------------------------

CREATE TRIGGER trg_InsertMasterService
ON MASTER
AFTER INSERT
AS
BEGIN
    INSERT INTO MASTER_SERVICE (MasterID, ServiceID)
    SELECT i.MasterID, s.ServiceID
    FROM INSERTED i
    CROSS JOIN SERVICE s;
END;
GO

CREATE TRIGGER trg_InsertServiceMaster
ON SERVICE
AFTER INSERT
AS
BEGIN
    INSERT INTO MASTER_SERVICE (MasterID, ServiceID)
    SELECT m.MasterID, i.ServiceID
    FROM INSERTED i
    CROSS JOIN MASTER m;
END;
GO

INSERT INTO CLIENT (PhoneNumber, LastName, FirstName, Gender, DateOfBirth)
VALUES 
('+79991230001','Иванов','Иван',1,'19900101'),
('+79991230002','Петров','Петр',1,'19850512'),
('+79991230003','Сидорова','Мария',0,'19920820'),
('+79991230004','Кузнецова','Анна',0,'19880315'),
('+79991230005','Смирнов','Алексей',1,'19951205'),
('+79991230006','Фёдорова','Екатерина',0,'19930310'),
('+79991230007','Морозов','Дмитрий',1,'19891122'),
('+79991230008','Ковалёва','Ольга',0,'19900708'),
('+79991230009','Новиков','Сергей',1,'19920615'),
('+79991230010','Васильева','Наталья',0,'19881230');

INSERT INTO MASTER (PhoneNumber, LastName, FirstName, Specialization, SkillLevel)
VALUES
('+79990000001','Петров','Пётр',1,5),
('+79990000002','Иванова','Ольга',2,4),
('+79990000003','Сидоров','Сергей',3,3),
('+79990000004','Кузнецов','Дмитрий',1,2),
('+79990000005','Смирнова','Елена',2,4),
('+79990000006','Фёдоров','Алексей',1,3),
('+79990000007','Морозова','Анна',3,5),
('+79990000008','Ковалёв','Никита',2,2);

INSERT INTO SERVICE (ServiceName, Price, Duration, Category, Description)
VALUES
('Стрижка',1000,60,1,'Классическая стрижка'),
('Маникюр',800,45,2,'Женский маникюр'),
('Педикюр',900,50,2,'Женский педикюр'),
('Окрашивание',2000,120,1,'Окрашивание волос'),
('Укладка',1500,70,1,'Стильная укладка'),
('Массаж',1200,60,3,'Расслабляющий массаж');

INSERT INTO SALON (Address, OpeningHours, PhoneNumber, Category)
VALUES
('ул. Ленина, д.1','9:00-21:00','+79990001111',1),
('ул. Пушкина, д.5','10:00-20:00','+79990002222',2),
('ул. Гагарина, д.10','9:00-22:00','+79990003333',1),
('ул. Мира, д.7','10:00-19:00','+79990004444',3);

INSERT INTO APPOINTMENT (ClientID, MasterID, SalonID, ServiceID, StartDateTime, Status, Price, Rating)
VALUES
(1, 2, 1, 2, '20250320 10:00', 0, 800, 5),
(2, 1, 2, 1, '20250320 11:00', 0, 1000, 4),
(3, 3, 3, 3, '20250321 09:30', 0, 900, 5),
(4, 4, 4, 4, '20250321 14:00', 0, 2000, 3),
(5, 5, 1, 5, '20250322 10:30', 0, 1500, 4),
(6, 6, 2, 6, '20250322 13:00', 0, 1200, 5),
(7, 7, 3, 2, '20250323 11:00', 0, 800, 4),
(8, 8, 4, 3, '20250323 15:00', 0, 900, 5),
(9, 1, 1, 1, '20250324 10:00', 0, 1000, 3),
(10, 2, 2, 4, '20250324 12:30', 0, 2000, 4),
(3, 3, 3, 5, '20250325 09:00', 0, 1500, 5),
(4, 4, 4, 6, '20250325 11:30', 0, 1200, 4);
GO

-------------------------------------------------------

SELECT DISTINCT
    LastName AS Фамилия,
    FirstName AS Имя,
    DATEDIFF(YEAR, DateOfBirth, GETDATE()) AS Возраст
FROM CLIENT
ORDER BY Возраст DESC;

-- Вычисление средней, минимальной и максимальной цены услуг по категориям
SELECT 
    Category AS Категория,
    AVG(Price) AS СредняяЦена,
    MIN(Price) AS МинимальнаяЦена,
    MAX(Price) AS МаксимальнаяЦена
FROM SERVICE
GROUP BY Category;

-- Подсчет количества услуг, оказанных клиентам в возрасте от 25 до 35 лет
SELECT COUNT(*) AS КоличествоУслуг
FROM APPOINTMENT a
INNER JOIN CLIENT c ON a.ClientID = c.ClientID
WHERE DATEDIFF(YEAR, c.DateOfBirth, GETDATE()) BETWEEN 25 AND 35;

-- Суммарный доход каждого мастера, вывод только тех, у кого доход больше 2000
SELECT 
    m.LastName AS ФамилияМастера, 
    m.FirstName AS ИмяМастера, 
    SUM(a.Price) AS ОбщийДоход
FROM MASTER m
INNER JOIN APPOINTMENT a ON m.MasterID = a.MasterID
GROUP BY m.LastName, m.FirstName
HAVING SUM(a.Price) > 2000
ORDER BY ОбщийДоход ASC;

-- Отображение всех мастеров и услуг, с которыми они связаны
SELECT 
    m.LastName AS ФамилияМастера, 
    m.FirstName AS ИмяМастера,
    s.ServiceName AS Услуга,
    ms.MasterID AS СуществуетЗапись
FROM MASTER m
FULL OUTER JOIN MASTER_SERVICE ms ON m.MasterID = ms.MasterID
FULL OUTER JOIN SERVICE s ON ms.ServiceID = s.ServiceID
ORDER BY m.LastName, s.ServiceName;

-- Список всех мастеров и услуг, на которые они подписаны, включая все услуги
SELECT 
    m.MasterID AS IDМастера,
    m.LastName AS ФамилияМастера,
    m.FirstName AS ИмяМастера,
    s.ServiceID AS IDУслуги,
    s.ServiceName AS Услуга
FROM MASTER m
RIGHT JOIN MASTER_SERVICE ms ON m.MasterID = ms.MasterID
RIGHT JOIN SERVICE s ON ms.ServiceID = s.ServiceID
ORDER BY s.ServiceName, m.LastName;

SELECT PhoneNumber AS Телефон, LastName AS Фамилия, FirstName AS Имя FROM CLIENT
UNION ALL
SELECT PhoneNumber AS Телефон, LastName AS Фамилия, FirstName AS Имя FROM MASTER;

SELECT LastName AS Фамилия FROM CLIENT
UNION
SELECT LastName AS Фамилия FROM MASTER;

SELECT FirstName AS Имя FROM CLIENT
INTERSECT
SELECT FirstName AS Имя FROM MASTER;

SELECT PhoneNumber AS Телефон, LastName AS Фамилия, FirstName AS Имя FROM CLIENT
EXCEPT
SELECT PhoneNumber AS Телефон, LastName AS Фамилия, FirstName AS Имя FROM MASTER;

-- Повышение уровня навыка мастеров, которые провели более 3 записей
UPDATE MASTER
SET SkillLevel = SkillLevel + 1
WHERE MasterID IN (
    SELECT MasterID
    FROM APPOINTMENT
    GROUP BY MasterID
    HAVING COUNT(*) > 3
);

-- Добавление пометки о специальном предложении к услугам, содержащим "Женский"
UPDATE SERVICE
SET Description = Description + ' (специальное предложение)'
WHERE Description LIKE '%Женский%';

DELETE FROM CLIENT
WHERE DateOfBirth IS NULL;

-- Удаление клиентов, у которых нет записей на услуги
DELETE FROM CLIENT
WHERE EXISTS (
    SELECT 1
    FROM CLIENT c2
    LEFT JOIN APPOINTMENT a ON c2.ClientID = a.ClientID
    WHERE CLIENT.ClientID = c2.ClientID
      AND a.ClientID IS NULL
);

INSERT INTO CLIENT (PhoneNumber, LastName, FirstName, DateOfBirth)
SELECT PhoneNumber, LastName, FirstName, NULL AS DateOfBirth
FROM MASTER
WHERE NOT EXISTS (
    SELECT 1 FROM CLIENT c WHERE c.PhoneNumber = MASTER.PhoneNumber
);

