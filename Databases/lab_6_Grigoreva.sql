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
    FILENAME = 'C:\SQLData\Lab6\data1.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = N'BeautySalons_Log',
    FILENAME = 'C:\SQLData\Lab6\log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO


----------------------------

USE BeautySalons;

CREATE TABLE Salon
    (
        SalonID INT PRIMARY KEY IDENTITY(1,1),
        Address NVARCHAR(100) NOT NULL,
        OpeningHours NVARCHAR(50),
        PhoneNumber VARCHAR(15),
        Category TINYINT,
    );
GO

INSERT INTO Salon (Address, OpeningHours, PhoneNumber, Category)
VALUES 
    (N'ул. Пушкина, д. 10', '09:00-21:00', '+79991234567', 1),
    (N'пр. Ленина, д. 25', '10:00-20:00', '+79997654321', 2),
    (N'ул. Гагарина, д. 15', '08:00-22:00', '+79991357924', 1);
GO

SELECT * 
FROM Salon;
GO

----------------------------

CREATE TABLE Service
(
    ServiceID INT PRIMARY KEY IDENTITY(1,1),
    ServiceName NVARCHAR(50) NOT NULL,
    Price MONEY NOT NULL DEFAULT 5000 CHECK(Price < 10000),
    Duration SMALLINT NOT NULL,
    Category TINYINT,
    Description NVARCHAR(255)
);
GO

INSERT INTO Service (ServiceName, Price, Duration, Category, Description)
VALUES 
    (N'Маникюр классический', 1200.00, 45, 3, N'Уход за ногтями, покрытие лаком'),
    (N'Стрижка женская', DEFAULT, 60, 1, N'Стрижка и укладка'),
    (N'Массаж лица', 1800.00, 30, 2, N'Расслабляющий массаж');
GO

SELECT *
FROM Service;
GO

SELECT SCOPE_IDENTITY() AS [SCOPE_IDENTITY];
SELECT @@IDENTITY AS [@@IDENTITY];
SELECT IDENT_CURRENT('Service') AS [IDENT_CURRENT];

----------------------------

CREATE TABLE Client
(
    ClientID UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    PhoneNumber VARCHAR(15) NOT NULL,
    LastName NVARCHAR(25),
    FirstName NVARCHAR(25),
    Gender TINYINT,
)

INSERT INTO Client (PhoneNumber, LastName, FirstName, Gender)
VALUES 
    ('+79991112233', N'Иванова', N'Мария', 0),
    ('+79994445566', N'Петрова', N'Алексей', 0),
    ('+79997778899', N'Сидорова', N'Ольга', 0);
GO

SELECT * 
FROM Client;
GO

----------------------------

IF OBJECT_ID('dbo.Master_Sequence', 'SO') IS NULL
    CREATE SEQUENCE dbo.Master_Sequence AS INT START WITH 1 INCREMENT BY 1;
GO

CREATE TABLE Master
(
    MasterID INT PRIMARY KEY DEFAULT NEXT VALUE FOR dbo.Master_Sequence,
    PhoneNumber VARCHAR(15) NOT NULL,
    LastName NVARCHAR(25),
    FirstName NVARCHAR(25),
    Specialization TINYINT,
    SkillLevel TINYINT
)

INSERT INTO Master (PhoneNumber, LastName, FirstName, Specialization, SkillLevel)
VALUES 
    ('+79992223344', N'Кузнецова', N'Анна', 0, 4),
    ('+79995556677', N'Васильев', N'Дмитрий', 1, 4),
    ('+79998889900', N'Николаева', N'Елена', 0, 5);
GO

SELECT * 
FROM Master;
GO

----------------------------

CREATE TABLE dbo.Parent
(
    ParentID INT PRIMARY KEY IDENTITY(1,1),
    ParentValue INT NOT NULL
);

CREATE TABLE dbo.Child_NoAction
(
    ChildID INT PRIMARY KEY IDENTITY(1,1),
    ParentID INT,
    ChildValue INT NOT NULL,
    CONSTRAINT FK_NoAction FOREIGN KEY (ParentID) 
    REFERENCES dbo.Parent(ParentID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.Child_Cascade
(
    ChildID INT PRIMARY KEY IDENTITY(1,1),
    ParentID INT,
    ChildValue INT NOT NULL,
    CONSTRAINT FK_Cascade FOREIGN KEY (ParentID) 
    REFERENCES dbo.Parent(ParentID) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE TABLE dbo.Child_SetNull
(
    ChildID INT PRIMARY KEY IDENTITY(1,1),
    ParentID INT NULL,
    ChildValue INT NOT NULL,
    CONSTRAINT FK_SetNull FOREIGN KEY (ParentID) 
    REFERENCES dbo.Parent(ParentID) ON DELETE SET NULL ON UPDATE NO ACTION
);

CREATE TABLE dbo.Child_SetDefault
(
    ChildID INT PRIMARY KEY IDENTITY(1,1),
    ParentID INT DEFAULT 1,
    ChildValue INT NOT NULL,
    CONSTRAINT FK_SetDefault FOREIGN KEY (ParentID) 
    REFERENCES dbo.Parent(ParentID) ON DELETE SET DEFAULT ON UPDATE NO ACTION
);

----------------------------

INSERT INTO dbo.Parent (ParentValue) VALUES (100);
INSERT INTO dbo.Parent (ParentValue) VALUES (200);
GO

INSERT INTO dbo.Child_NoAction (ParentID, ChildValue) VALUES (1, 201);
INSERT INTO dbo.Child_Cascade (ParentID, ChildValue) VALUES (2, 202);
INSERT INTO dbo.Child_SetNull (ParentID, ChildValue) VALUES (2, 203);
INSERT INTO dbo.Child_SetDefault (ParentID, ChildValue) VALUES (2, 204);
GO

DELETE FROM dbo.Parent WHERE ParentID = 2;

SELECT * FROM dbo.Child_Cascade;
SELECT * FROM dbo.Child_SetNull;
SELECT * FROM dbo.Child_SetDefault;
GO