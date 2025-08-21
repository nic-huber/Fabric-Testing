CREATE TABLE [dbo].[FinalTable_Example] (

	[BusinessKey] varchar(255) NOT NULL, 
	[Attribut1] varchar(255) NULL, 
	[Attribut2] int NULL, 
	[DWH_ValidFrom] datetime2(6) NOT NULL, 
	[DWH_ValidUntil] datetime2(6) NULL, 
	[DWH_Active] bit NOT NULL, 
	[DWH_CreatedDate] datetime2(6) NOT NULL, 
	[DWH_CreatedBy] varchar(255) NOT NULL, 
	[DWH_ModifiedDate] datetime2(6) NULL, 
	[DWH_ModifiedBy] varchar(255) NULL
);