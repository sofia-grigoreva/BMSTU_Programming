USE BeautySalons1;
GO

IF OBJECT_ID(N'Salon', N'U') IS NOT NULL
    DROP TABLE Salon;
GO

CREATE TABLE Salon
(
    SalonID INT PRIMARY KEY IDENTITY(1,1),
    Address NVARCHAR(100) NOT NULL UNIQUE,
    OpeningHours NVARCHAR(50) NULL,
    PhoneNumber VARCHAR(15) NULL,
    Category TINYINT NULL,
);
GO

INSERT INTO SALON (Address, OpeningHours, PhoneNumber, Category)
VALUES
('ул. Ленина, д.1','9:00-21:00','+79990001111',1),
('ул. Пушкина, д.5','10:00-20:00','+79990002222',2),
('ул. Гагарина, д.10','9:00-22:00','+79990003333',1),
('ул. Мира, д.7','10:00-19:00','+79990004444',3);
GO

USE BeautySalons2;
GO

IF OBJECT_ID(N'Appointment', N'U') IS NOT NULL
    DROP TABLE Appointment;
GO

CREATE TABLE APPOINTMENT
(
    AppointmentID INT PRIMARY KEY IDENTITY(1,1),
    SalonID INT NOT NULL,
    StartDateTime SMALLDATETIME NOT NULL,
    Status TINYINT NOT NULL DEFAULT 0 CHECK (Status IN (0,1,2,3)), 
    Price MONEY NOT NULL CHECK (Price >= 0),
    Rating TINYINT NULL DEFAULT 0 CHECK (Rating BETWEEN 0 AND 5),
);
GO

INSERT INTO APPOINTMENT (SalonID, StartDateTime, Status, Price, Rating)
VALUES
(1,  '20250320 10:00', 0, 800, 5),
(2,  '20250320 11:00', 0, 1000, 4),
(3, '20250321 09:30', 0, 900, 5),
(2,'20250321 14:00', 0, 2000, 3);
GO

------------------------------------------------------

USE BeautySalons1;
GO

-- Триггер INSERT
IF OBJECT_ID(N'trg_vSalonsFromDB1_Insert', N'TR') IS NOT NULL
    DROP TRIGGER trg_vSalonsFromDB1_Insert;
GO

CREATE TRIGGER trg_vSalonsFromDB1_Insert
ON Salon
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO BeautySalons1.dbo.Salon (Address, OpeningHours, PhoneNumber, Category)
    SELECT Address, OpeningHours, PhoneNumber, Category
    FROM inserted;
END;
GO

-- Триггер UPDATE
IF OBJECT_ID(N'trg_vSalonsFromDB1_Update', N'TR') IS NOT NULL
    DROP TRIGGER trg_vSalonsFromDB1_Update;
GO

CREATE TRIGGER trg_vSalonsFromDB1_Update
ON SALON
INSTEAD OF UPDATE
AS
BEGIN
    IF UPDATE(SalonID)
    BEGIN
        RAISERROR ('Ошибка: Нельзя изменять SalonID.', 16, 1);
        RETURN;
    END;
    
    UPDATE s
    SET s.Address = i.Address,
        s.OpeningHours = i.OpeningHours,
        s.PhoneNumber = i.PhoneNumber,
        s.Category = i.Category
    FROM BeautySalons1.dbo.Salon s
    INNER JOIN inserted i ON s.SalonID = i.SalonID;
END;
GO

-- Триггер DELETE
IF OBJECT_ID(N'trg_SalonsFromDB1_Delete', N'TR') IS NOT NULL
    DROP TRIGGER trg_SalonsFromDB1_Delete;
GO

CREATE TRIGGER trg_SalonsFromDB1_Delete
ON SALON
INSTEAD OF DELETE
AS
BEGIN

    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE EXISTS (
            SELECT 1
            FROM BeautySalons2.dbo.APPOINTMENT a
            WHERE d.SalonID = a.SalonID
        )
    )
    BEGIN
        RAISERROR ('Ошибка: Нельзя удалить салон, который используется в записях', 16, 1);
        RETURN;
    END;

    DELETE s
    FROM BeautySalons1.dbo.Salon s
    INNER JOIN deleted d ON s.SalonID = d.SalonID;
END;
GO

IF OBJECT_ID(N'vAppointmentsFromDB2', N'V') IS NOT NULL
    DROP VIEW vAppointmentsFromDB2;
GO

CREATE VIEW vAppointmentsFromDB2
AS
    SELECT
        AppointmentID,
        SalonID,
        StartDateTime,
        Status,
        Price,
        Rating
    FROM BeautySalons2.dbo.APPOINTMENT;
GO

------------------------------------------------------

USE BeautySalons2;
GO

-- Триггер INSERT
IF OBJECT_ID(N'trg_AppointmentsFromDB2_Insert', N'TR') IS NOT NULL
    DROP TRIGGER trg_AppointmentsFromDB2_Insert;
GO

CREATE TRIGGER trg_AppointmentsFromDB2_Insert
ON APPOINTMENT
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM BeautySalons1.dbo.Salon s
            WHERE i.SalonID = s.SalonID
        )
    )
    BEGIN
        RAISERROR ('Ошибка: SalonID не существует в таблице Salon.', 16, 1);
        RETURN;
    END;
    INSERT INTO BeautySalons2.dbo.APPOINTMENT (SalonID, StartDateTime, Status, Price, Rating)
    SELECT SalonID, StartDateTime, Status, Price, Rating
    FROM inserted;
END;
GO

-- Триггер UPDATE
IF OBJECT_ID(N'trg_AppointmentsFromDB2_Update', N'TR') IS NOT NULL
    DROP TRIGGER trg_AppointmentsFromDB2_Update;
GO

CREATE TRIGGER trg_AppointmentsFromDB2_Update
ON APPOINTMENT
INSTEAD OF UPDATE
AS
BEGIN 
    IF UPDATE(AppointmentID)
    BEGIN
        RAISERROR ('Ошибка: Нельзя изменять AppointmentID.', 16, 1);
        RETURN;
    END;
    
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM BeautySalons1.dbo.Salon s
            WHERE i.SalonID = s.SalonID
        )
    )
    BEGIN
        RAISERROR ('Ошибка: SalonID не существует в таблице Salon.', 16, 1);
        RETURN;
    END;
   
    UPDATE a
    SET a.SalonID = i.SalonID,
        a.StartDateTime = i.StartDateTime,
        a.Status = i.Status,
        a.Price = i.Price,
        a.Rating = i.Rating
    FROM BeautySalons2.dbo.APPOINTMENT a
    INNER JOIN inserted i ON a.AppointmentID = i.AppointmentID;
END;
GO

-- Триггер DELETE
IF OBJECT_ID(N'trg_AppointmentsFromDB2_Delete', N'TR') IS NOT NULL
    DROP TRIGGER trg_AppointmentsFromDB2_Delete;
GO

CREATE TRIGGER trg_AppointmentsFromDB2_Delete
ON APPOINTMENT
INSTEAD OF DELETE
AS
BEGIN
    DELETE a
    FROM BeautySalons2.dbo.APPOINTMENT a
    INNER JOIN deleted d ON a.AppointmentID = d.AppointmentID;
END;
GO

IF OBJECT_ID(N'vSalonsFromDB1', N'V') IS NOT NULL
    DROP VIEW vSalonsFromDB1;
GO

CREATE VIEW vSalonsFromDB1
AS
    SELECT
        SalonID,
        Address,
        OpeningHours,
        PhoneNumber,
        Category
    FROM BeautySalons1.dbo.Salon;
GO


------------------------------------------------------

USE BeautySalons1;
GO

INSERT INTO vAppointmentsFromDB2 (SalonID, StartDateTime, Status, Price, Rating)
VALUES (1, '20250322 15:00', 1, 1200, 4);

UPDATE vAppointmentsFromDB2
SET Price = 850, Rating = 5
WHERE AppointmentID = 1;

DELETE FROM vAppointmentsFromDB2
WHERE AppointmentID = 4;

------------------------------------------------------

USE BeautySalons2;
GO

INSERT INTO vSalonsFromDB1 (Address, OpeningHours, PhoneNumber, Category)
VALUES ('ул. Новая, д.15', '8:00-22:00', '+79990005555', 2);

UPDATE vSalonsFromDB1
SET OpeningHours = '9:00-23:00'
WHERE Address = 'ул. Новая, д.15';

DELETE FROM vSalonsFromDB1
WHERE Address = 'ул. Мира, д.7';

SELECT *
FROM BeautySalons1.dbo.Salon;
SELECT *
FROM BeautySalons2.dbo.Appointment;
GO