CREATE TABLE [dbo].[CustomerSource_TMP] (

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
	[ModifiedBy] varchar(100) NULL, 
	[ModifiedDate] datetime2(3) NULL, 
	[CreatedBy] varchar(100) NOT NULL, 
	[CreatedDate] datetime2(3) NULL, 
	[ValidFrom] datetime2(3) NULL, 
	[ValidUntil] datetime2(3) NULL
);