CREATE TABLE [dbo].[CustomerSource_Test] (

	[DWH_ID] int NOT NULL, 
	[DWH_Key] varchar(200) NOT NULL, 
	[CustomerID] int NOT NULL, 
	[Title] varchar(8) NULL, 
	[FirstName] varchar(50) NULL, 
	[MiddleName] varchar(50) NULL, 
	[LastName] varchar(50) NULL, 
	[Suffix] varchar(10) NULL, 
	[CompanyName] varchar(128) NULL, 
	[SalesPerson] varchar(256) NULL, 
	[EmailAddress] varchar(50) NULL, 
	[Phone] varchar(25) NULL, 
	[DWH_IsActive] bit NOT NULL, 
	[DWH_ValidFrom] datetime2(6) NOT NULL, 
	[DWH_ValidUntil] datetime2(6) NOT NULL, 
	[DWH_ModifiedBy] varchar(100) NULL, 
	[DWH_ModifiedDate] datetime2(6) NULL, 
	[DWH_CreatedBy] varchar(100) NOT NULL, 
	[DWH_CreatedDate] datetime2(6) NOT NULL
);