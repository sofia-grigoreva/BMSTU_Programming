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
    FILENAME = 'C:\SQLData\Lab5\data1.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = N'BeautySalons_Log',
    FILENAME = 'C:\SQLData\Lab5\log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO


----------------------------

USE BeautySalons;

CREATE TABLE Salon
(
    SalonID INT PRIMARY KEY,
    Address NVARCHAR(100) NOT NULL,
    OpeningHours NVARCHAR(50),
    PhoneNumber VARCHAR(15),
    Category TINYINT,
);
GO

SELECT *
FROM Salon; 
GO

----------------------------

ALTER DATABASE BeautySalons
ADD FILEGROUP MyFileGroup;  
GO

ALTER DATABASE BeautySalons
ADD FILE(
    NAME = BeautySalons_File,  
    FILENAME = 'C:\SQLData\Lab5\data2.mdf',  
    SIZE = 5MB,  
    MAXSIZE = 25MB,  
    FILEGROWTH = 5%
)
TO FILEGROUP MyFileGroup;
GO

----------------------------

ALTER DATABASE BeautySalons
    MODIFY FILEGROUP MyFileGroup DEFAULT;
GO

----------------------------

CREATE TABLE Service
(
    ServiceID INT PRIMARY KEY,
    ServiceName NVARCHAR(50) NOT NULL,
    Price MONEY NOT NULL,
    Duration SMALLINT NOT NULL,
    Category TINYINT,
    Description NVARCHAR(255)
);
GO

INSERT INTO Service
    (ServiceID, ServiceName, Price, Duration, Category, Description)
VALUES
    (1, N'Маникюр классический', 1200.00, 45, 3, N'Уход за ногтями, покрытие лаком')
GO

SELECT *
FROM Service;
GO

----------------------------

ALTER DATABASE BeautySalons
    MODIFY FILEGROUP [PRIMARY] DEFAULT;
GO

SELECT *
INTO NewService
FROM Service;
GO

DROP TABLE Service;
GO

ALTER DATABASE BeautySalons
    REMOVE FILE BeautySalons_File;
GO

ALTER DATABASE BeautySalons
    REMOVE FILEGROUP MyFileGroup;
GO

SELECT *
FROM NewService;
GO


----------------------------

CREATE SCHEMA MySchema;
GO

ALTER SCHEMA MySchema
    TRANSFER dbo.Salon;
GO

IF OBJECT_ID(N'MySchema.Salon') IS NOT NULL
BEGIN
    DROP TABLE MySchema.Salon;
END
GO

DROP SCHEMA MySchema;
GO

