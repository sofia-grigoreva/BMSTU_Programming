USE BeautySalons1;
GO

IF OBJECT_ID(N'Salons1', N'U') IS NOT NULL
    DROP TABLE Salons1;
GO

CREATE TABLE Salons1
(
    SalonID INT PRIMARY KEY,
    Address NVARCHAR(100) NOT NULL UNIQUE,
    OpeningHours NVARCHAR(50) NULL,
);
GO

------------------------------------------------------

USE BeautySalons2;
GO

IF OBJECT_ID(N'Salons2', N'U') IS NOT NULL
    DROP TABLE Salons2;
GO

CREATE TABLE Salons2
(
    SalonID INT PRIMARY KEY,
    PhoneNumber VARCHAR(15) NULL,
    Category TINYINT NULL,
);
GO

------------------------------------------------------

USE BeautySalons1;
GO

IF OBJECT_ID(N'SalonsView', N'V') IS NOT NULL
    DROP VIEW SalonsView;
GO

CREATE VIEW SalonsView
AS
    SELECT
        p1.SalonID,
        p1.Address,
        p1.OpeningHours,
        p2.PhoneNumber,
        p2.Category
    FROM BeautySalons1.dbo.Salons1 p1
        INNER JOIN BeautySalons2.dbo.Salons2 p2 ON p1.SalonID = p2.SalonID;
GO

IF OBJECT_ID(N'InsertSalonsViewTrg', N'TR') IS NOT NULL
    DROP TRIGGER InsertSalonsViewTrg;
GO

-- Вставка данных
CREATE TRIGGER InsertSalonsViewTrg
ON SalonsView
INSTEAD OF INSERT
AS
BEGIN

    INSERT INTO BeautySalons1.dbo.Salons1
        (SalonID, Address, OpeningHours)
    SELECT SalonID, Address, OpeningHours
    FROM inserted;

    INSERT INTO BeautySalons2.dbo.Salons2
        (SalonID, PhoneNumber, Category)
    SELECT SalonID, PhoneNumber, Category
    FROM inserted;
END;
GO

IF OBJECT_ID(N'UpdateSalonsViewTrg', N'TR') IS NOT NULL
    DROP TRIGGER UpdateSalonsViewTrg;
GO

-- Обновление данных
CREATE TRIGGER UpdateSalonsViewTrg
ON SalonsView
INSTEAD OF UPDATE
AS
BEGIN
    
    IF UPDATE(SalonID)
    BEGIN
        RAISERROR('Нельзя изменить столбец SalonID', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    UPDATE p1
    SET 
        p1.Address = i.Address,
        p1.OpeningHours = i.OpeningHours
    FROM BeautySalons1.dbo.Salons1 p1
        INNER JOIN inserted i ON p1.SalonID = i.SalonID;
    
    UPDATE p2
    SET 
        p2.PhoneNumber = i.PhoneNumber,
        p2.Category = i.Category
    FROM BeautySalons2.dbo.Salons2 p2
        INNER JOIN inserted i ON p2.SalonID = i.SalonID;
END;
GO

IF OBJECT_ID(N'DeleteSalonsViewTrg', N'TR') IS NOT NULL
    DROP TRIGGER DeleteSalonsViewTrg;
GO

-- Удаление данных
CREATE TRIGGER DeleteSalonsViewTrg
ON SalonsView
INSTEAD OF DELETE
AS
BEGIN

    DELETE FROM BeautySalons2.dbo.Salons2
    WHERE SalonID IN (SELECT SalonID FROM deleted);
    
    DELETE FROM BeautySalons1.dbo.Salons1
    WHERE SalonID IN (SELECT SalonID FROM deleted);
END;
GO

------------------------------------------------------

INSERT INTO SalonsView
    (SalonID, Address, OpeningHours, PhoneNumber, Category)
VALUES
    (1, 'ул. Ленина, 10', '9:00-20:00', '+79161234567', 1),
    (2, 'ул. Пушкина, 5', '10:00-21:00', '+79169876543', 2);
GO

SELECT *
FROM SalonsView;
GO

UPDATE SalonsView
SET
    Address = 'ул. Ленина, 44',
    OpeningHours = '9:00-22:00',
    PhoneNumber = '+79161112233'
WHERE SalonID = 1;
GO

DELETE FROM SalonsView
WHERE SalonID = 2;
GO

SELECT *
FROM BeautySalons1.dbo.Salons1;
SELECT *
FROM BeautySalons2.dbo.Salons2;
GO