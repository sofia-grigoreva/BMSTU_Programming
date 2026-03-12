USE master;
GO

IF DB_ID(N'BeautySalons') IS NOT NULL
BEGIN
    ALTER DATABASE BeautySalons SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BeautySalons;
    PRINT 'Deleted old database';
END
GO

CREATE DATABASE BeautySalons
ON PRIMARY
(
    NAME = N'BeautySalons_Primary',
    FILENAME = 'C:\SQLData\Lab9\data1.mdf',
    SIZE = 10MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
)
LOG ON
(
    NAME = N'BeautySalons_Log',
    FILENAME = 'C:\SQLData\Lab9\log.ldf',
    SIZE = 5MB,
    MAXSIZE = 25MB,
    FILEGROWTH = 5MB
);
GO

USE BeautySalons;
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

CREATE TABLE SERVICE_EXTRA
(
    ServiceID INT PRIMARY KEY,
    SideEffects NVARCHAR(255) NULL,
    Recommendations NVARCHAR(255) NULL,
    CONSTRAINT FK_ServiceExtra_Service FOREIGN KEY(ServiceID)
        REFERENCES SERVICE(ServiceID) ON DELETE CASCADE
);
GO

-- 1. Триггеры на SERVICE

IF OBJECT_ID(N'Service_Insert') IS NOT NULL DROP TRIGGER Service_Insert;
IF OBJECT_ID(N'Service_Update') IS NOT NULL DROP TRIGGER Service_Update;
IF OBJECT_ID(N'Service_Delete') IS NOT NULL DROP TRIGGER Service_Delete;
GO

CREATE TRIGGER Service_Insert
ON SERVICE
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE Price < 300)
    BEGIN
        RAISERROR('Цена услуги не может быть ниже 300 рублей!', 16, 1);
        RETURN;
    END
END;
GO

CREATE TRIGGER Service_Update
ON SERVICE
AFTER UPDATE
AS
BEGIN

    IF UPDATE(ServiceID)
    BEGIN
        RAISERROR('Изменение ID запрещено!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM inserted WHERE Price < 300)
    BEGIN
        RAISERROR('Цена услуги не может быть ниже 300 рублей!', 16, 1);
        RETURN;
    END
END;
GO

CREATE TRIGGER Service_Delete
ON SERVICE
AFTER DELETE
AS
BEGIN
    PRINT 'Удалены услуги';
END;
GO


INSERT INTO SERVICE(ServiceName, Price, Duration, Category, Description)
VALUES ('Укладка', 500, 60, 4, REPLICATE('a', 101));

UPDATE SERVICE
SET Price = 600, Description = REPLICATE('b', 150)
WHERE ServiceID = 1;

DELETE FROM SERVICE WHERE ServiceID = 1;
GO

-- 2. Триггеры на VIEW

CREATE VIEW Service_VIEW AS
SELECT 
    S.ServiceID,
    S.ServiceName,
    S.Price,
    S.Duration,
    S.Category,
    S.Description,
    E.SideEffects,
    E.Recommendations
FROM SERVICE S
LEFT JOIN SERVICE_EXTRA E ON S.ServiceID = E.ServiceID;
GO


IF OBJECT_ID('Service_View_Insert', 'TR') IS NOT NULL DROP TRIGGER Service_View_Insert;
GO

CREATE TRIGGER Service_View_Insert
ON Service_VIEW
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE Description IS NOT NULL AND LEN(Description) <= 100)
    BEGIN
        RAISERROR('Описание должно быть больше 100 символов!', 16, 1);
        RETURN;
    END

    INSERT INTO SERVICE(ServiceName, Price, Duration, Category, Description)
    SELECT ServiceName, Price, Duration, Category, Description
    FROM inserted;

    INSERT INTO SERVICE_EXTRA(ServiceID, SideEffects, Recommendations)
    SELECT S.ServiceID, I.SideEffects, I.Recommendations
    FROM inserted I
    JOIN SERVICE S 
        ON S.ServiceName = I.ServiceName 
       AND S.Price = I.Price 
       AND S.Duration = I.Duration;

    PRINT 'Вставка через VIEW выполнена';
END;
GO

IF OBJECT_ID('Service_View_Update', 'TR') IS NOT NULL DROP TRIGGER Service_View_Update;
GO

CREATE TRIGGER Service_View_Update
ON Service_VIEW
INSTEAD OF UPDATE
AS
BEGIN

    IF UPDATE(ServiceID)
    BEGIN
        RAISERROR('Изменение ID запрещено!', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM inserted WHERE Description IS NOT NULL AND LEN(Description) <= 100)
    BEGIN
        RAISERROR('Описание должно быть больше 100 символов!', 16, 1);
        RETURN;
    END

    UPDATE S
    SET 
        S.ServiceName = I.ServiceName,
        S.Price = I.Price,
        S.Duration = I.Duration,
        S.Category = I.Category,
        S.Description = I.Description
    FROM SERVICE S
    JOIN inserted I ON S.ServiceID = I.ServiceID;

    UPDATE E
    SET 
        E.SideEffects = I.SideEffects,
        E.Recommendations = I.Recommendations
    FROM SERVICE_EXTRA E
    JOIN inserted I ON E.ServiceID = I.ServiceID;

    PRINT 'Обновление через VIEW выполнено';
END;
GO


IF OBJECT_ID('Service_View_Delete', 'TR') IS NOT NULL DROP TRIGGER Service_View_Delete;
GO

CREATE TRIGGER Service_View_Delete
ON Service_VIEW
INSTEAD OF DELETE
AS
BEGIN

    DELETE E
    FROM SERVICE_EXTRA E
    JOIN deleted D ON E.ServiceID = D.ServiceID;

    DELETE S
    FROM SERVICE S
    JOIN deleted D ON S.ServiceID = D.ServiceID;

    PRINT 'Удаление через VIEW выполнено';
END;
GO


INSERT INTO Service_VIEW(ServiceName, Price, Duration, Category, Description, SideEffects, Recommendations)
VALUES ('Укладка', 500, 60, 4, REPLICATE('a', 120), 'Может вызвать аллергию', 'Избегать воды 2 часа');

INSERT INTO Service_VIEW(ServiceName, Price, Duration, Category, Description, SideEffects, Recommendations)
VALUES ('Укладка1', 1500, 160, 14, REPLICATE('a', 120), 'Может вызвать аллергию', 'Избегать воды 2 часа');

INSERT INTO Service_VIEW(ServiceName, Price, Duration, Category, Description, SideEffects, Recommendations)
VALUES ('Укладка12', 11500, 10, 14, REPLICATE('a', 120), 'Может вызвать аллергию', 'Избегать воды 2 часа');


UPDATE Service_VIEW
SET 
    Price = 650,
    Description = REPLICATE('b',150),
    SideEffects = 'Нет',
    Recommendations = 'Можно мыть голову на следующий день'
WHERE ServiceID = 2;

select * from Service_VIEW

update Service_VIEW
set ServiceID = ServiceID+1

select * from Service_VIEW

DELETE FROM Service_VIEW WHERE ServiceID = 2;

select * from Service_VIEW