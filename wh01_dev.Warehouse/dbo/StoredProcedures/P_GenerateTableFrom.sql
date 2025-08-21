/********************************************************************************

Author:			nicolas.huber@balcab.ch
Create date:	2025-08-04
Description:	
Sample Call:	
	
	DECLARE 
     @ReturnMsg NVARCHAR(4000)
	,@dbName NVARCHAR(100) = N'wh01_dev'
    ,@SourceTableName NVARCHAR(100) = 'CustomerSource'
    ,@TargetTableName NVARCHAR(100) = 'CustomerSource_Test'
	
	EXEC [dbo].[P_GenerateTableFrom]
	 @ReturnMsg OUT
	,@dbName = @dbName
    ,@SourceTableName = @SourceTableName
	,@TargetTableName = @TargetTableName
    
	
	SELECT 
	 @ReturnMsg AS [message]
										
Modifications:		
20170901 HN: Initial script
**********************************************************************************/
CREATE PROCEDURE [dbo].[P_GenerateTableFrom]
    (
	 @ReturnMsg NVARCHAR(4000) = NULL OUTPUT
    ,@dbName NVARCHAR(100) = NULL
    ,@SourceTableName NVARCHAR(100) = NULL
    ,@TargetTableName NVARCHAR(100) = NULL
    )
AS
    SET NOCOUNT ON;

    SET ANSI_NULLS ON;

    SET QUOTED_IDENTIFIER ON;


    DECLARE 
	   @sql_drop_objects NVARCHAR(MAX)
	   ,@sql_create_table NVARCHAR(MAX)
	   ,@colscandtype NVARCHAR(MAX) = N''
	   --,@dbName NVARCHAR(100) = N'wh01_dev'      
  	   --,@SourceTableName NVARCHAR(100) = 'CustomerSource'
	   --,@TargetTableName NVARCHAR(100) = 'CustomerSource_Test'


SET @sql_drop_objects = N'

-- ** Use when drop of all objects is required **

USE ' + QUOTENAME(@dbName) + ' 

DROP TABLE [dbo].[' + @TargetTableName + '];

';
PRINT @sql_drop_objects;

IF OBJECT_ID(@TargetTableName) IS NOT NULL
EXEC sp_executesql  @sql_drop_objects

	   SELECT @colscandtype +=
        N'' + QUOTENAME(c.name) + N' ' +
        ty.name +
        CASE
            WHEN ty.name IN ('varchar', 'nvarchar', 'char', 'nchar', 'varbinary') THEN N'(' + IIF(c.max_length = -1, 'MAX', CAST(c.max_length AS NVARCHAR(10))) + N')'
            WHEN ty.name IN ('decimal', 'numeric') THEN N'(' + CAST(c.precision AS NVARCHAR(10)) + N',' + CAST(c.scale AS NVARCHAR(10)) + N')'
            WHEN ty.name IN ('datetime2', 'time') THEN N'(6)' -- 6 is max for Fabric warehouse
            ELSE N''
        END +
        CASE WHEN c.is_nullable = 1 THEN N' NULL' ELSE N' NOT NULL' END + ',' + CHAR(13) + CHAR(10)

	FROM
        sys.columns AS c
    JOIN
        sys.types AS ty 
		ON c.system_type_id = ty.system_type_id 
		AND c.user_type_id = ty.user_type_id
    WHERE
        c.object_id = OBJECT_ID(@SourceTableName) -- Sicherstellen, dass @SourceTableName existiert!
    ORDER BY
        c.column_id


--PRINT @colscandtype


    SET @sql_create_table = N'
USE ' + QUOTENAME(@dbName) + '

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON;

CREATE TABLE [dbo].[' + @TargetTableName + '](
	[DWH_ID] [int] NOT NULL,
	[DWH_Key] [varchar](200) NOT NULL,
	' + @colscandtype + '
	[DWH_IsActive] [BIT] NOT NULL,
	[DWH_ValidFrom] [DATETIME2](6) NOT NULL,
	[DWH_ValidUntil] [DATETIME2](6) NOT NULL,
	[DWH_ModifiedBy] [VARCHAR](100) NULL,
	[DWH_ModifiedDate] [DATETIME2](6) NULL,
	[DWH_CreatedBy] [VARCHAR](100) NOT NULL,
	[DWH_CreatedDate] [DATETIME2](6) NOT NULL,
	)'

--PRINT  @sql_create_table;

EXEC sp_executesql @sql_create_table

SET @ReturnMsg = 'Procedure successfully completed!';
    PRINT @ReturnMsg;

RETURN 0; -- everything is fine, have a nice day