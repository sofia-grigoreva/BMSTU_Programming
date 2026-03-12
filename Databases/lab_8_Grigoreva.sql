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
    FILENAME = 'C:\SQLData\Lab8\data1.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = N'BeautySalons_Log',
    FILENAME = 'C:\SQLData\Lab8\log.ldf',
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
GO

INSERT INTO MASTER
    (PhoneNumber, LastName, FirstName, Specialization, SkillLevel)
VALUES
    ('+79167778899', 'Кузнецова', 'Анна', 1, 5),
    ('+79166665544', 'Смирнов', 'Дмитрий', 2, 4),
    ('+79164443322', 'Волкова', 'Елена', 3, 5);
GO

INSERT INTO SERVICE
    (ServiceName, Price, Duration, Category, Description)
VALUES
    ('Стрижка женская', 1500.00, 60, 1, 'Модная стрижка с укладкой'),
    ('Cтрижка мужская', 800.00, 30, 1, 'Классическая мужская стрижка'),
    ('Mаникюр', 1200.00, 45, 2, 'Аппаратный маникюр с покрытием'),
    ('Педикюр', 1500.00, 60, 2, 'Аппаратный педикюр с покрытием'),
    ('Окрашивание волос', 2500.00, 120, 1, 'Сложное окрашивание с тонированием');
GO

INSERT INTO SALON
    (Address, OpeningHours, PhoneNumber, Category)
VALUES
    ('ул. Пушкина, д.10', '09:00-21:00', '+74951234567', 1),
    ('пр. Ленина, д.25', '10:00-20:00', '+74959876543', 2),
    ('ул. Гагарина, д.15', '08:00-22:00', '+74957654321', 1);
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

------------------------------------------------------------------------

-- 1. Хранимая процедура

DROP PROCEDURE IF EXISTS dbo.GetClientsByNameLength;
GO

CREATE PROCEDURE dbo.GetClientsByNameLength
    @cursor CURSOR VARYING OUTPUT,
    @NameLength INT
AS
BEGIN
    SET @cursor = CURSOR SCROLL FOR
    SELECT ClientID, FirstName, LastName, PhoneNumber, Gender
    FROM CLIENT
    WHERE LEN(FirstName) = @NameLength;

    OPEN @cursor;
END;
GO



DECLARE @cur CURSOR;
DECLARE @ID INT, @FN NVARCHAR(25), @LN NVARCHAR(25),
        @PH VARCHAR(15), @G TINYINT;

EXEC dbo.GetClientsByNameLength @cursor=@cur OUTPUT, @NameLength=5;

FETCH NEXT FROM @cur INTO @ID, @FN, @LN, @PH, @G;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @ID AS ClientID, @FN AS FirstName, @LN AS LastName, @PH AS Phone, @G AS Gender;
    FETCH NEXT FROM @cur INTO @ID, @FN, @LN, @PH, @G;
END;

CLOSE @cur;
DEALLOCATE @cur;
GO


-- 2. Пользовательская функция + модифицированная хранимая процедура

DROP FUNCTION IF EXISTS dbo.UpperFirstName;
GO

CREATE FUNCTION dbo.UpperFirstName(@Name NVARCHAR(25))
RETURNS NVARCHAR(25)
AS
BEGIN
    RETURN UPPER(@Name);
END;
GO


DROP PROCEDURE IF EXISTS dbo.GetUppercasedClients;
GO

CREATE PROCEDURE dbo.GetUppercasedClients
    @cursor CURSOR VARYING OUTPUT,
    @NameLength INT
AS
BEGIN
    SET @cursor = CURSOR SCROLL FOR
    SELECT ClientID,
           dbo.UpperFirstName(FirstName) AS UpperName,
           LastName,
           PhoneNumber,
           Gender
    FROM CLIENT
    WHERE LEN(FirstName) = @NameLength;

    OPEN @cursor;
END;
GO

DECLARE @cur2 CURSOR;
DECLARE @ID INT, @FN NVARCHAR(25), @LN NVARCHAR(25),
        @PH VARCHAR(15), @G TINYINT;

EXEC dbo.GetUppercasedClients @cursor=@cur2 OUTPUT, @NameLength=5;

FETCH NEXT FROM @cur2 INTO @ID, @FN, @LN, @PH, @G;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @ID AS ClientID, @FN AS UpperName, @LN AS LastName, @PH AS Phone, @G AS Gender;
    FETCH NEXT FROM @cur2 INTO @ID, @FN, @LN, @PH, @G;
END;

CLOSE @cur2;
DEALLOCATE @cur2;
GO



-- 3. Процедура с прокуткой курсора

DROP FUNCTION IF EXISTS dbo.IsIvanova;
GO

CREATE FUNCTION dbo.IsIvanova(@Surname NVARCHAR(25))
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN @Surname = N'Иванова' THEN 1 ELSE 0 END;
END;
GO


DROP PROCEDURE IF EXISTS dbo.PrintIvanovaClients;
GO

CREATE PROCEDURE dbo.PrintIvanovaClients
AS
BEGIN
    DECLARE @cursor CURSOR;
    EXEC dbo.GetClientsByNameLength @cursor = @cursor OUTPUT, @NameLength = 5;

    DECLARE @ClientID INT, @FName NVARCHAR(25), @LName NVARCHAR(25),
            @Phone VARCHAR(15), @Gender TINYINT;

    PRINT 'Клиенты с длиной имени 5 и фамилией Иванова:';

    FETCH NEXT FROM @cursor INTO @ClientID, @FName, @LName, @Phone, @Gender;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF dbo.IsIvanova(@LName) = 1
        BEGIN
            SELECT @ClientID AS ClientID,
                   @FName    AS FirstName,
                   @LName    AS LastName,
                   @Phone    AS PhoneNumber,
                   @Gender   AS Gender;
        END;
        FETCH NEXT FROM @cursor INTO @ClientID, @FName, @LName, @Phone, @Gender;
    END;

    CLOSE @cursor;
    DEALLOCATE @cursor;
END;
GO

EXEC dbo.PrintIvanovaClients;
GO

-- 4. Выборка с помощью табличной функции

DROP FUNCTION IF EXISTS dbo.ExpensiveServicesUpper;
GO

CREATE FUNCTION dbo.ExpensiveServicesUpper()
RETURNS TABLE
AS
RETURN (
    SELECT 
        ServiceID,
        dbo.UpperFirstName(ServiceName) AS UpperServiceName,
        Price,
        Duration,
        Category
    FROM SERVICE
    WHERE Price > 1000
);
GO

CREATE FUNCTION dbo.ExpensiveServicesUpper2()
RETURNS @ServicesTable TABLE
(
    ServiceID INT,
    UpperServiceName NVARCHAR(200),
    Price DECIMAL(10,2),
    Duration INT,
    Category NVARCHAR(100)
)
AS
BEGIN
    INSERT INTO @ServicesTable
    SELECT 
        s.ServiceID,
        dbo.UpperFirstName(s.ServiceName) AS UpperServiceName,
        s.Price,
        s.Duration,
        s.Category
    FROM SERVICE s
    WHERE s.Price > 1000;

    RETURN;
END;
GO



DROP PROCEDURE IF EXISTS dbo.UseExpensiveServicesUpper;
GO

CREATE PROCEDURE dbo.UseExpensiveServicesUpper
AS
BEGIN
    SELECT * 
    FROM dbo.ExpensiveServicesUpper();
END;
GO


EXEC dbo.UseExpensiveServicesUpper;
GO


DROP PROCEDURE IF EXISTS dbo.UseExpensiveServicesUpper2;
GO

CREATE PROCEDURE dbo.UseExpensiveServicesUpper2
AS
BEGIN
    SELECT * 
    FROM dbo.ExpensiveServicesUpper();
END;
GO


EXEC dbo.UseExpensiveServicesUpper2;
GO