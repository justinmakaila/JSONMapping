import CoreData
import RemoteMapping


extension JSONRepresentable where Self: NSManagedObject, Self: JSONValidator {
    /// Serializes a `NSManagedObject` to a JSONObject, using the remote properties.
    ///
    /// - Parameters:
    ///     - parent: The parent of the object.
    ///     - relationshipType: Flag indicating what type of relationships to use.
    ///     - excludeKeys: The names of properties to be removed. Should be the name of the property in your data model,
    ///                    not the remote property name.
    ///
    public func toJSON(dateFormatter: JSONDateFormatter, relationshipType: RelationshipType = .embedded, parent: NSManagedObject? = nil, excludeKeys: Set<String> = [], includeNilValues: Bool = true) -> JSONObject {
        return jsonObjectForProperties(
            entity.remoteProperties,
            dateFormatter: dateFormatter,
            parent: parent,
            relationshipType: relationshipType,
            excludeKeys: excludeKeys,
            includeNilValues: includeNilValues
        )
    }
    
    /// Serializes a `NSManagedObject` to a JSONObject representing only the changed properties, as specified by the
    /// RemoteMapping implementation
    ///
    /// - Parameters:
    ///     - parent: The parent of the object.
    ///     - relationshipType: Flag indicating what type of relationships to use.
    ///     - excludeKeys: The names of properties to be removed. Should be the name of the property in your data model,
    ///                    not the remote property name.
    ///
    public func toChangedJSON(dateFormatter: JSONDateFormatter, relationshipType: RelationshipType = .embedded, parent: NSManagedObject? = nil, excludeKeys: Set<String> = [], includeNilValues: Bool = true) -> JSONObject {
        let changedPropertyKeys: Set<String> = Set(self.changedValues().keys)
        let remoteProperties = entity.remoteProperties.filter { changedPropertyKeys.contains($0.name) }
        
        return jsonObjectForProperties(
            remoteProperties,
            dateFormatter: dateFormatter,
            parent: parent,
            relationshipType: relationshipType,
            excludeKeys: excludeKeys,
            includeNilValues: includeNilValues
        )
    }
    
    /// Syncs `self` with `json`.
    ///
    /// - Parameters:
    ///     - json: The JSON to sync with.
    ///     - dateFormatter: A `JSONDateFormatter` to be used for serialzing Dates from JSON. If none is provided,
    ///                      no dates will be processed from the JSON.
    ///     - parent: The parent of the object.
    ///     - force: Flag to force merge the JSON
    public func sync(withJSON json: JSONObject, dateFormatter: JSONDateFormatter? = nil, parent: NSManagedObject? = nil, force: Bool = false) {
        if isValid(json: json) || force {
            sync(scalarValuesWithJSON: json, dateFormatter: dateFormatter)
            sync(relationshipsWithJSON: json, dateFormatter: dateFormatter, parent: parent)
        }
    }
}

extension NSManagedObject: JSONRepresentable, JSONValidator, JSONParser {
    open func isValid(json: JSONObject) -> Bool {
        return true
    }
    
    open func parseJSON(json: JSONObject, propertyDescription: NSPropertyDescription) -> Any? {
        return json[propertyDescription.remotePropertyName]
    }
}

private extension NSManagedObject {
    /// Syncs the scalar values in the JSON to `self`
    func sync(scalarValuesWithJSON json: JSONObject, dateFormatter: JSONDateFormatter? = nil) {
        entity.remoteAttributes
            .forEach { attribute in
                if let jsonValue = parseJSON(json: json, propertyDescription: attribute) {
                    setValue(
                        attribute.value(usingRemoteValue: jsonValue, dateFormatter: dateFormatter),
                        forKey: attribute.name
                    )
                }
            }
    }
    
    func sync(relationshipsWithJSON json: JSONObject, dateFormatter: JSONDateFormatter? = nil, parent: NSManagedObject? = nil) {
        entity.remoteRelationships
            .forEach { relationship in
                let jsonValue = parseJSON(json: json, propertyDescription: relationship)
                if relationship.isToMany {
                    if let json = jsonValue as? [JSONObject] {
                        sync(toManyRelationship: relationship, withJSON: json, dateFormatter: dateFormatter, parent: parent)
                    }
                } else {
                    if let json = jsonValue as? JSONObject {
                        sync(toOneRelationship: relationship, withJSON: json, dateFormatter: dateFormatter)
                    }
                }
            }
    }
    
    func sync(toOneRelationship relationship: NSRelationshipDescription, withJSON json: JSONObject, dateFormatter: JSONDateFormatter? = nil) {
        guard let managedObjectContext = managedObjectContext,
            let destinationEntity = relationship.destinationEntity,
            let destinationEntityName = destinationEntity.name,
            !json.isEmpty
        else {
            return
        }
        
        if let remotePrimaryKey = json[destinationEntity.remotePrimaryKeyName] as? String {
            setValue(
                managedObjectContext.upsert(json: json, inEntity: destinationEntity, withPrimaryKey: remotePrimaryKey, dateFormatter: dateFormatter),
                forKey: relationship.name
            )
        } else {
            guard let object = value(forKey: relationship.name) as? NSManagedObject
            else {
                let object = NSEntityDescription.insertNewObject(forEntityName: destinationEntityName, into: managedObjectContext)
                object.sync(withJSON: json, dateFormatter: dateFormatter)
                return setValue(object, forKey: relationship.name)
            }
            
            object.sync(withJSON: json, dateFormatter: dateFormatter)
        }
    }
    
    func sync(toManyRelationship relationship: NSRelationshipDescription, withJSON json: [JSONObject], dateFormatter: JSONDateFormatter? = nil, parent: NSManagedObject? = nil) {
        guard let managedObjectContext = managedObjectContext,
            let destinationEntity = relationship.destinationEntity,
            let destinationEntityName = destinationEntity.name
        else {
            return
        }
        
        let inverseIsToMany = relationship.inverseRelationship?.isToMany ?? false
        
        if json.count > 0 {
            var destinationEntityPredicate: NSPredicate? = nil
            
            if inverseIsToMany && relationship.isToMany {
                
            } else if let inverseEntityName = relationship.inverseRelationship?.name {
                destinationEntityPredicate = NSPredicate(format: "%K = %@", inverseEntityName, self)
            }
            
            let changes = managedObjectContext.update(
                entityNamed: destinationEntityName,
                withJSON: json,
                dateFormatter: dateFormatter,
                parent: self,
                predicate: destinationEntityPredicate
            )
            
            setValue(Set(changes), forKey: relationship.name)
        } else if let parent = parent,
            parent.entity.name == destinationEntityName,
            inverseIsToMany {
            if relationship.isOrdered {
                let relatedObjects = mutableOrderedSetValue(forKey: relationship.name)
                if !relatedObjects.contains(parent) {
                    relatedObjects.add(parent)
                    setValue(relatedObjects, forKey: relationship.name)
                }
            } else {
                let relatedObjects = mutableSetValue(forKey: relationship.name)
                if !relatedObjects.contains(parent) {
                    relatedObjects.add(parent)
                    setValue(relatedObjects, forKey: relationship.name)
                }
            }
        }
    }
}


/// Helpers
private extension NSManagedObject {
    /// Returns a JSON object.
    ///
    /// - Parameters:
    ///     - properties: The properties to use for serialization.
    ///     - parent: The parent of the object.
    ///     - relationshipType: Flag indicating what type of relationships to use.
    ///     - excludeKeys: The names of properties to be removed. Should be the name of the property in your data model, not the remote property name.
    ///
    func jsonObjectForProperties(_ properties: [NSPropertyDescription], dateFormatter: JSONDateFormatter, parent: NSManagedObject? = nil, relationshipType: RelationshipType = .embedded, excludeKeys: Set<String> = [], includeNilValues: Bool = true) -> JSONObject {
        var jsonObject = JSONObject()
        
        properties
            .filter { !excludeKeys.contains($0.name) }
            .forEach { propertyDescription in
                let remoteRelationshipName = propertyDescription.remotePropertyName
                
                if let attributeDescription = propertyDescription as? NSAttributeDescription {
                    jsonObject[remoteRelationshipName] = json(
                        valueForAttribute: attributeDescription,
                        dateFormatter: dateFormatter,
                        includeNilValues: includeNilValues
                    )
                } else if let relationshipDescription = propertyDescription as? NSRelationshipDescription,
                    (relationshipType != .none) {
                    /// A valid relationship is one which does not go back up the relationship heirarchy...
                    /// TODO: This condition could be much clearer
                    let isValidRelationship = !(parent != nil
                        && (parent?.entity == relationshipDescription.destinationEntity)
                        && !relationshipDescription.isToMany)
                    
                    if isValidRelationship {
                        jsonObject[remoteRelationshipName] = json(
                            valueForRelationship: relationshipDescription,
                            relationshipType: relationshipType,
                            dateFormatter: dateFormatter,
                            includeNilValues: includeNilValues
                        )
                    }
                }
            }
        
        return jsonObject
    }
    
    /// Transforms an object to JSON, using the supplied `relationshipType`.
    func json(attributesForObject object: NSManagedObject, dateFormatter: JSONDateFormatter, parent: NSManagedObject?, relationshipType: RelationshipType, includeNilValues: Bool = true) -> Any {
        switch relationshipType {
        case .embedded:
            return object.toJSON(
                dateFormatter: dateFormatter,
                relationshipType: relationshipType,
                parent: parent,
                includeNilValues: includeNilValues
            )
        case .reference:
            return object.primaryKey ?? NSNull()
        default:
            return NSNull()
        }
    }
    
    /// Returns the JSON value of `attributeDescription` if it's `attributeType` is not a "Transformable" attribute.
    func json(valueForAttribute attribute: NSAttributeDescription, dateFormatter: JSONDateFormatter? = nil, includeNilValues: Bool = false) -> Any? {
        var attributeValue: Any?
        
        if attribute.attributeType != .transformableAttributeType {
            attributeValue = value(forKey: attribute.name)
            
            if let date = attributeValue as? Date {
                return dateFormatter?.string(from: date)
            } else if let data = attributeValue as? Data {
                return NSKeyedUnarchiver.unarchiveObject(with: data)
            }
        }
        
        if attributeValue == nil && includeNilValues {
            attributeValue = NSNull()
        }
        
        return attributeValue
    }
    
    /// Returns the JSON value of `relationship` if it's `attributeType`
    func json(valueForRelationship relationship: NSRelationshipDescription, relationshipType: RelationshipType, dateFormatter: JSONDateFormatter,  includeNilValues: Bool = false) -> Any? {
        let relationshipMappingType = relationship.relationshipMapping ?? relationshipType
        
        /// If there are relationships at `localRelationshipName`
        if let relationshipValue = value(forKey: relationship.name) {
            /// If the relationship is to a single object...
            if let destinationObject = relationshipValue as? NSManagedObject {
                return json(
                    attributesForObject: destinationObject,
                    dateFormatter: dateFormatter,
                    parent: self,
                    relationshipType: relationshipMappingType,
                    includeNilValues: includeNilValues
                )
                
                /// If the relationship is to a set of objects...
            } else if let relationshipSet = relationshipValue as? Set<NSManagedObject> {
                return relationshipSet.map { object in
                    return json(
                        attributesForObject: object,
                        dateFormatter: dateFormatter,
                        parent: self,
                        relationshipType: relationshipMappingType,
                        includeNilValues: includeNilValues
                    )
                }
                
                /// If the relationship is to an ordered set of objects...
            } else if let relationshipSet = (relationshipValue as? NSOrderedSet)?.set as? Set<NSManagedObject> {
                return relationshipSet.map { object in
                    return json(
                        attributesForObject: object,
                        dateFormatter: dateFormatter,
                        parent: self,
                        relationshipType: relationshipMappingType,
                        includeNilValues: includeNilValues
                    )
                }
            }
        }
        
        return includeNilValues ? NSNull() : nil
    }
    
    /// Gets a `NSAttributeDescription` matching `key`, or nil.
    func attributeDescription(forRemoteKey key: String) -> NSAttributeDescription? {
        var foundAttributeDescription: NSAttributeDescription?
        
        for (_, propertyDescription) in entity.properties.enumerated() {
            if let attributeDescription = propertyDescription as? NSAttributeDescription {
                let remoteKey = attributeDescription.remotePropertyName
                
                if remoteKey == key || attributeDescription.name == key {
                    foundAttributeDescription = attributeDescription
                }
            }
        }
        
        return foundAttributeDescription
    }
}
