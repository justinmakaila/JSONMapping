# RemoteMapping
Provides direct mapping from Core Data entities to remote properties.

This library was built in order to make serialization of objects from Core Data to remote representations and vice versa much easier.
You can map core data attributes and relationships to custom remote property names by adding a key and value to their user info dictionaries.
You can also mark properties as local/remote primary keys.

### Usage
#### Primary Keys
To set primary keys on an entity description, just update the `userInfo` of the `NSEntityDescription` in the "Data Model Inspector" in Xcode, or explicitly set the `userInfo` dictionary in code.

Set a local primary key name:
```
entity.userInfo["primaryKey.local"] = "localPrimaryKey"
```
Get a local primary key name:
```
entity.localPrimaryKeyName
```
Get a local primary key:
```
entity.localPrimaryKey
```  
Set a remote primary key name:
```
entity.userInfo["primaryKey.remote"] = "remotePrimaryKey"
```
Get a remote primary key name:
```
entity.remotePrimaryKeyName
```
Get a remote primary key:
```
entity.remotePrimaryKey
```

#### Remote Properties
To set custom remote property names, select the attribute or relationship in your `.xcdatamodeld`, and add the proper keys and values to the `userInfo` dictionary in the "Data Model Inspector".

Set a remote property name:
```
propertyDescription.userInfo["remotePropertyName"] = "somePropertyName"
```
Get a remote property name:
```
propertyDescription.remotePropertyName
```

You can ignore properties in the same way.
```
propertyDescription.userInfo["remoteShouldIgnore"] = true
propertyDescription.remoteShouldIgnore
```


### Core Data Extensions
This library adds conformation of `RemoteEntityType` to `NSEntityDescription`, and `RemoteObjectMappingType` to `NSPropertyDescription`. 

All instances of `NSPropertyDescription` will return the `name` for `remotePropertyKey` by default.

All instances of `NSEntityDescrption` will return "remoteID" as the value for `remotePrimaryKeyName` and `localPrimaryKeyName` by default. There are also variables added for `remotePrimaryKey` and `localPrimaryKey`.

This also adds `remoteProperties`, `remotePropertiesByName`, and `remotePropertiesByLocalName` to `NSEntityDescription` instances, which filter `properties` by the information provided by `RemoteObjectMappingType` instances.

