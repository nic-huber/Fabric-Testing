-- Fabric notebook source

-- METADATA ********************

-- META {
-- META   "kernel_info": {
-- META     "name": "sqldatawarehouse"
-- META   },
-- META   "dependencies": {
-- META     "warehouse": {
-- META       "default_warehouse": "3be85cc9-deb9-9bc1-4540-f7756fa1e565",
-- META       "known_warehouses": [
-- META         {
-- META           "id": "3be85cc9-deb9-9bc1-4540-f7756fa1e565",
-- META           "type": "Datawarehouse"
-- META         }
-- META       ]
-- META     }
-- META   }
-- META }

-- CELL ********************

/*
CREATE TABLE [dbo].[CustomerSource] (
    [CustomerID] [int] NOT NULL,
    [Title] [varchar](8),
    [FirstName] [varchar](50),
    [MiddleName] [varchar](50),
    [LastName] [varchar](50),
    [Suffix] [varchar](10),
    [CompanyName] [varchar](128),
    [SalesPerson] [varchar](256),
    [EmailAddress] [varchar](50),
    [Phone] [varchar](25)
) --WITH ( HEAP )
WITH
*/

CREATE TABLE [dbo].[CustomerSource_TMP] (
    [CustomerID] [int] NOT NULL,
    [Title] [varchar](8),
    [FirstName] [varchar](50),
    [MiddleName] [varchar](50),
    [LastName] [varchar](50),
    [Suffix] [varchar](10),
    [CompanyName] [varchar](128),
    [SalesPerson] [varchar](256),
    [EmailAddress] [varchar](50),
    [Phone] [varchar](25)
) --WITH ( HEAP )


/*
COPY INTO [dbo].[CustomerSource]
FROM 'https://solliancepublicdata.blob.core.windows.net/dataengineering/dp-203/awdata/CustomerSource.csv'
WITH (
    FILE_TYPE='CSV',
    FIELDTERMINATOR='|',
    FIELDQUOTE='',
    ROWTERMINATOR='0x0a',
    ENCODING = 'UTF16'
)



CREATE TABLE dbo.[DimCustomer](
    [CustomerID] [int] NOT NULL,
    [Title] [varchar](8) NULL,
    [FirstName] [varchar](50) NOT NULL,
    [MiddleName] [varchar](50) NULL,
    [LastName] [varchar](50) NOT NULL,
    [Suffix] [varchar](10) NULL,
    [CompanyName] [varchar](128) NULL,
    [SalesPerson] [varchar](256) NULL,
    [EmailAddress] [varchar](50) NULL,
    [Phone] [varchar](25) NULL,
    [InsertedDate] DATETIME2(3) NOT NULL,
    [ModifiedDate] DATETIME2(3) NOT NULL,
    [HashKey] [char](64)
)

WITH
(
  --  DISTRIBUTION = REPLICATE,
  ..  CLUSTERED COLUMNSTORE INDEX
)
*/

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

select * from CustomerSource_TMP

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

DROP TABLE CustomerSource_TMP

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }

-- CELL ********************

-- Beginnt ein neuer Batch
GO

DECLARE @SourceTableName NVARCHAR(128) = 'CustomerSource';
DECLARE @NewTableName NVARCHAR(128) = 'CustomerSource_TMP';
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnDefinitions NVARCHAR(MAX) = N'';

SELECT @ColumnDefinitions = STUFF((
    SELECT
    'hello'
    FROM
        sys.columns AS c
    JOIN
        sys.types AS ty ON c.system_type_id = ty.system_type_id AND c.user_type_id = ty.user_type_id
    WHERE
        c.object_id = OBJECT_ID(@SourceTableName)
    ORDER BY
        c.column_id
    FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 2, N'');

SET @SQL = N'CREATE TABLE dbo.' + QUOTENAME(@NewTableName) + N' (' + @ColumnDefinitions + N');';

PRINT @SQL;

-- Beendet diesen Batch
GO

-- METADATA ********************

-- META {
-- META   "language": "sql",
-- META   "language_group": "sqldatawarehouse"
-- META }
