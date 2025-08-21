CREATE TABLE [dbo].[DimCustomer] (

	[CustomerID] int NOT NULL, 
	[Title] varchar(8) NULL, 
	[FirstName] varchar(50) NOT NULL, 
	[MiddleName] varchar(50) NULL, 
	[LastName] varchar(50) NOT NULL, 
	[Suffix] varchar(10) NULL, 
	[CompanyName] varchar(128) NULL, 
	[SalesPerson] varchar(256) NULL, 
	[EmailAddress] varchar(50) NULL, 
	[Phone] varchar(25) NULL, 
	[InsertedDate] datetime2(3) NOT NULL, 
	[ModifiedDate] datetime2(3) NOT NULL, 
	[HashKey] char(64) NULL
);