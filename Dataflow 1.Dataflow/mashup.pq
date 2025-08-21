[DefaultOutputDestinationSettings = [DestinationDefinition = [Kind = "Reference", QueryName = "DefaultDestination", IsNewTarget = true], UpdateMethod = [Kind = "Append"], DestinationTypeSettings = [Kind = "Table"]], StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared DefaultDestination = let
  Source = Fabric.Warehouse([CreateNavigationProperties = false]),
  Navigation = Source{[workspaceId = "3e6c0b5e-458f-45c9-9788-21a0040799d4"]}[Data],
  #"Navigation 1" = Navigation{[warehouseId = "6fa1e565-f775-4540-9bc1-deb93be85cc9"]}[Data]
in
  #"Navigation 1";
[BindToDefaultDestination = true]
shared CustomerSource = let
  Source = Fabric.Warehouse(null),
  Navigation = Source{[workspaceId = "3e6c0b5e-458f-45c9-9788-21a0040799d4"]}[Data],
  #"Navigation 1" = Navigation{[warehouseId = "6fa1e565-f775-4540-9bc1-deb93be85cc9"]}[Data],
  #"Navigation 2" = #"Navigation 1"{[Schema = "dbo", Item = "CustomerSource"]}[Data],
  #"Added custom" = Table.TransformColumnTypes(Table.AddColumn(#"Navigation 2", "InsertedDate", each iif(isNull(InsertedDate), currentTimestamp(), {InsertedDate})), {{"InsertedDate", type datetime}}),
  #"Added custom 1" = Table.TransformColumnTypes(Table.AddColumn(#"Added custom", "ModifiedDate", each currentTimestamp()), {{"ModifiedDate", type datetime}}),
  #"Added custom 2" = Table.AddColumn(#"Added custom 1", "HashKey", each sha2(256, iifNull(Title,"") +FirstName +iifNull(MiddleName,"") +LastName +iifNull(Suffix,"") +iifNull(CompanyName,"") +iifNull(SalesPerson,"") +iifNull(EmailAddress,"") +iifNull(Phone,"")))
in
  #"Added custom 2";
