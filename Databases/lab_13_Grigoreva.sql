USE master;
GO

IF DB_ID(N'BeautySalons1') IS NOT NULL
BEGIN
    ALTER DATABASE BeautySalons1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BeautySalons1;
END
GO

IF DB_ID(N'BeautySalons2') IS NOT NULL
BEGIN
    ALTER DATABASE BeautySalons2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BeautySalons2;
END
GO

CREATE DATABASE BeautySalons1 ON (
    NAME = BeautySalons1_dat,
    FILENAME = 'C:\SQLData\Lab13\data1111.mdf',
    SIZE = 10MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5%
)
GO

CREATE DATABASE BeautySalons2 ON (
    NAME = BeautySalons2_dat,
    FILENAME = 'C:\SQLData\Lab13\data1222.mdf',
    SIZE = 10MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5%
)
GO

------------------------------------------------------
 
USE BeautySalons1;
GO

CREATE TABLE Salons1
(
    SalonID INT PRIMARY KEY CHECK (SalonID < 3),
    Address NVARCHAR(100) NOT NULL UNIQUE,
    OpeningHours NVARCHAR(50) NULL,
    PhoneNumber VARCHAR(15) NULL,
    Category TINYINT NULL,
);
GO

------------------------------------------------------

USE BeautySalons2;
GO

CREATE TABLE Salons2
(

    SalonID INT PRIMARY KEY CHECK (SalonID >= 3),
    Address NVARCHAR(100) NOT NULL UNIQUE,
    OpeningHours NVARCHAR(50) NULL,
    PhoneNumber VARCHAR(15) NULL,
    Category TINYINT NULL,
);
GO

USE BeautySalons1;
GO

------------------------------------------------------

-- Создание представления
CREATE VIEW SalonsView
AS
    SELECT *
    FROM BeautySalons1.dbo.Salons1
UNION ALL
    SELECT *
    FROM BeautySalons2.dbo.Salons2;
GO

-- Вставка данных
INSERT INTO SalonsView
VALUES
    (1, 'ул. Ленина, д.1','9:00-21:00','+79990001111',1),
    (2, 'ул. Пушкина, д.5','10:00-20:00','+79990002222',2),
    (3, 'ул. Гагарина, д.10','9:00-22:00','+79990003333',1),
    (4, 'ул. Мира, д.7','10:00-19:00','+79990004444',3);
GO

-- Удаление данных
DELETE FROM SalonsView WHERE Address = 'ул. Ленина, д.1';
GO

-- Обновление данных
UPDATE SalonsView SET Category = 5;
GO

--UPDATE SalonsView SET SalonID = 10 WHERE Address = 'ул. Пушкина, д.5';
--GO

SELECT *
FROM BeautySalons1.dbo.Salons1;
SELECT *
FROM BeautySalons2.dbo.Salons2;
GO
