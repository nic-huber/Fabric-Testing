/***********************************************
Author:			nicolas.huber@balcab.ch
Create date:	2025-08-04 
Description:	Executes the ETL process 
Sample Call:

DECLARE
	@TargetTableName VARCHAR(100) = 'FinalTable_Example',
    @StageTableName VARCHAR(100) = 'StageTable_Example',
    @BusinessKeyColumnName VARCHAR(100) = 'BusinessKey',
    @SCDType INT = 1,
    @User VARCHAR(100) = 'Initiale_Ladung',
	@DebugMode BIT = 1,
	@ReturnMsg VARCHAR(MAX),
	@RecordsAffected INT;

EXEC dbo.sp_LoadSCDData
    @TargetTableName = @TargetTableName,
    @StageTableName = @StageTableName,
    @BusinessKeyColumnName = @BusinessKeyColumnName,
    @SCDType = @SCDType,
    @User = @User,
	@DebugMode = @DebugMode,
    @ReturnMsg = @ReturnMsg OUTPUT,
    @AffectedRecords = @RecordsAffected OUTPUT;

	SELECT 
		@ReturnMsg AS [message]
		,@RecordsAffected AS [records affected]
	
Modifications:	
	
************************************************/
CREATE PROCEDURE dbo.sp_LoadSCDData
  @TargetTableName NVARCHAR(128),
    @StageTableName NVARCHAR(128),
    @BusinessKeyColumnName NVARCHAR(128),
    @SCDType INT, -- 1 für SCD Typ 1, 2 für SCD Typ 2
    @User NVARCHAR(100) = NULL,
    @DebugMode BIT = 0, -- Neuer Debug-Modus Parameter
    @ReturnMsg NVARCHAR(MAX) OUTPUT,
    @AffectedRecords INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @CurrentDateTime DATETIME2(7) = GETDATE();
    DECLARE @UpdateSetClause NVARCHAR(MAX);
    DECLARE @ChangeDetectionClause NVARCHAR(MAX);
    DECLARE @InsertColumnList NVARCHAR(MAX);
    DECLARE @InsertValueList NVARCHAR(MAX);
    DECLARE @RowsAffected INT = 0;
    
    -- Ersetzt die Tabellenvariable durch eine temporäre Tabelle, da 'table' nicht unterstützt wird.
    CREATE TABLE #AuditColumns (
        name NVARCHAR(128) COLLATE DATABASE_DEFAULT
    );

    -- Auditspalten mit DWH_ Präfix
    INSERT INTO #AuditColumns VALUES 
    ('DWH_ValidFrom'), ('DWH_ValidUntil'), ('DWH_Active'), ('DWH_CreatedDate'), ('DWH_CreatedBy'), ('DWH_ModifiedDate'), ('DWH_ModifiedBy');

    IF @User IS NULL OR @User = ''
        SET @User = SUSER_SNAME();

    BEGIN TRY

        -- Überprüfen, ob Tabellen existieren
        IF OBJECT_ID(@TargetTableName) IS NULL OR OBJECT_ID(@StageTableName) IS NULL
        BEGIN
            SET @ReturnMsg = 'Fehler: Target oder Stage Tabelle existiert nicht.';
            SET @AffectedRecords = 0;
            RETURN;
        END

        -- Dynamische Spaltenlisten generieren mit STRING_AGG
        -- 1. UPDATE SET-Klausel für Attributsspalten
        SELECT @UpdateSetClause = STRING_AGG(QUOTENAME(c.name) + N' = Source.' + QUOTENAME(c.name), N', ')
            WITHIN GROUP (ORDER BY c.name)
        FROM sys.columns AS c
        WHERE c.object_id = OBJECT_ID(@TargetTableName)
        AND c.name COLLATE DATABASE_DEFAULT NOT IN (SELECT name FROM #AuditColumns)
        AND c.name COLLATE DATABASE_DEFAULT <> @BusinessKeyColumnName COLLATE DATABASE_DEFAULT;

        -- 2. INSERT-Spaltenliste (DWH_ValidUntil wird jetzt mit aufgenommen)
        SELECT @InsertColumnList = STRING_AGG(QUOTENAME(c.name), N', ')
            WITHIN GROUP (ORDER BY c.name)
        FROM sys.columns AS c
        WHERE c.object_id = OBJECT_ID(@TargetTableName)
        AND c.name COLLATE DATABASE_DEFAULT NOT IN ('DWH_ModifiedDate', 'DWH_ModifiedBy');

        -- 3. INSERT-Werteliste (DWH_ValidUntil wird explizit mit dem Wert befüllt)
        SELECT @InsertValueList = STRING_AGG(
            CASE c.name
                WHEN 'DWH_ValidFrom' THEN N'''' + CONVERT(NVARCHAR(30), @CurrentDateTime, 121) + N''''
                WHEN 'DWH_ValidUntil' THEN N'''9999-12-31 23:59:59.9999999'''
                WHEN 'DWH_Active' THEN N'1'
                WHEN 'DWH_CreatedDate' THEN N'Source.DWH_CreatedDate'
                WHEN 'DWH_CreatedBy' THEN N'Source.DWH_CreatedBy'
                ELSE N'Source.' + QUOTENAME(c.name)
            END, N', ') WITHIN GROUP (ORDER BY c.name)
        FROM sys.columns AS c
        WHERE c.object_id = OBJECT_ID(@TargetTableName)
        AND c.name COLLATE DATABASE_DEFAULT NOT IN ('DWH_ModifiedDate', 'DWH_ModifiedBy');

        -- 4. Bedingung für geänderte Attribute
        -- Nur auf Zeichenketten-Spalten anwenden
        SELECT @ChangeDetectionClause = STRING_AGG(
            N'(Target.' + QUOTENAME(c.name) + N' ' + 
            CASE WHEN t.name IN ('char', 'varchar', 'nchar', 'nvarchar') THEN N'COLLATE DATABASE_DEFAULT' ELSE N'' END +
            N' <> Source.' + QUOTENAME(c.name) + N' ' +
            CASE WHEN t.name IN ('char', 'varchar', 'nchar', 'nvarchar') THEN N'COLLATE DATABASE_DEFAULT' ELSE N'' END +
            N' OR (Target.' + QUOTENAME(c.name) + N' IS NULL AND Source.' + QUOTENAME(c.name) + N' IS NOT NULL) OR (Target.' + QUOTENAME(c.name) + N' IS NOT NULL AND Source.' + QUOTENAME(c.name) + N' IS NULL))'
            , N' OR ') WITHIN GROUP (ORDER BY c.name)
        FROM sys.columns AS c
        INNER JOIN sys.types AS t ON c.system_type_id = t.system_type_id
        WHERE c.object_id = OBJECT_ID(@TargetTableName)
        AND c.name COLLATE DATABASE_DEFAULT NOT IN (SELECT name FROM #AuditColumns)
        AND c.name COLLATE DATABASE_DEFAULT <> @BusinessKeyColumnName COLLATE DATABASE_DEFAULT;

        -- SCD Typ 1: Update/Insert (Überschreiben)
        IF @SCDType = 1
        BEGIN
            -- Update-Anweisung
            SET @SQL = N'
                UPDATE Target
                SET
                    ' + @UpdateSetClause + N',
                    DWH_ModifiedDate = ''' + CONVERT(NVARCHAR(30), @CurrentDateTime, 121) + N''',
                    DWH_ModifiedBy = ''' + @User + N'''
                FROM dbo.' + QUOTENAME(@TargetTableName) + N' AS Target
                JOIN dbo.' + QUOTENAME(@StageTableName) + N' AS Source
                    ON Target.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT = Source.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT
                WHERE Target.DWH_Active = 1
                AND ( ' + @ChangeDetectionClause + N' );';

            IF @DebugMode = 1
                PRINT @SQL;
            ELSE
            BEGIN
                EXEC sp_executesql @SQL;
                SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
            END

            -- Insert-Anweisung
            SET @SQL = N'
                INSERT INTO dbo.' + QUOTENAME(@TargetTableName) + N' (' + @InsertColumnList + N')
                SELECT ' + @InsertValueList + N'
                FROM dbo.' + QUOTENAME(@StageTableName) + N' AS Source
                LEFT JOIN dbo.' + QUOTENAME(@TargetTableName) + N' AS Target
                    ON Source.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT = Target.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT
                WHERE Target.' + QUOTENAME(@BusinessKeyColumnName) + N' IS NULL;';

            IF @DebugMode = 1
                PRINT @SQL;
            ELSE
            BEGIN
                EXEC sp_executesql @SQL;
                SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
            END

            SET @ReturnMsg = 'SCD Typ 1 Ausführung erfolgreich.';
        END
        -- SCD Typ 2: Historisieren + Neue Version einfügen
        ELSE IF @SCDType = 2
        BEGIN
            -- Update-Anweisung
            SET @SQL = N'
                UPDATE Target
                SET
                    Target.DWH_ValidUntil = ''' + CONVERT(NVARCHAR(30), DATEADD(ms, -3, @CurrentDateTime), 121) + N''',
                    Target.DWH_Active = 0,
                    Target.DWH_ModifiedDate = ''' + CONVERT(NVARCHAR(30), @CurrentDateTime, 121) + N''',
                    DWH_ModifiedBy = ''' + @User + N'''
                FROM dbo.' + QUOTENAME(@TargetTableName) + N' AS Target
                JOIN dbo.' + QUOTENAME(@StageTableName) + N' AS Source
                    ON Target.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT = Source.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT
                WHERE Target.DWH_Active = 1 AND ( ' + @ChangeDetectionClause + N' );';
            
            IF @DebugMode = 1
                PRINT @SQL;
            ELSE
            BEGIN
                EXEC sp_executesql @SQL;
                SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
            END

            -- Insert-Anweisung
            SET @SQL = N'
                INSERT INTO dbo.' + QUOTENAME(@TargetTableName) + N' (' + @InsertColumnList + N')
                SELECT ' + @InsertValueList + N'
                FROM dbo.' + QUOTENAME(@StageTableName) + N' AS Source
                LEFT JOIN dbo.' + QUOTENAME(@TargetTableName) + N' AS Target
                    ON Source.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT = Target.' + QUOTENAME(@BusinessKeyColumnName) + N' COLLATE DATABASE_DEFAULT AND Target.DWH_Active = 1
                WHERE Target.' + QUOTENAME(@BusinessKeyColumnName) + N' IS NULL
                   OR (Target.' + QUOTENAME(@BusinessKeyColumnName) + N' IS NOT NULL AND ( ' + @ChangeDetectionClause + N' ));';

            IF @DebugMode = 1
                PRINT @SQL;
            ELSE
            BEGIN
                EXEC sp_executesql @SQL;
                SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
            END

            SET @ReturnMsg = 'SCD Typ 2 Ausführung erfolgreich.';
        END
        ELSE
        BEGIN
            SET @ReturnMsg = 'Fehler: Ungültiger SCD-Typ. Verwenden Sie 1 für Typ 1 oder 2 für Typ 2.';
            SET @AffectedRecords = 0;
            RETURN;
        END
        
        -- Temporäre Tabelle aufräumen
        DROP TABLE #AuditColumns;

        SET @AffectedRecords = @RowsAffected;

    END TRY
    BEGIN CATCH
        -- Temporäre Tabelle auch im Fehlerfall aufräumen
        IF OBJECT_ID('tempdb..#AuditColumns') IS NOT NULL
            DROP TABLE #AuditColumns;

        SET @ReturnMsg = 'Fehler bei der Ausführung: ' + ERROR_MESSAGE();
        SET @AffectedRecords = -1;
    END CATCH
END;