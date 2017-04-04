import CoreData


extension NSEntityDescription: RemoteEntityType {
    /// The remote primary key name.
    ///
    /// Defaults to `localPrimaryKeyName` if none provided.
    public var remotePrimaryKeyName: String {
        if let remotePrimaryKey = userInfo?[RemoteMapping.Key.RemotePrimaryKey.rawValue] as? String {
            return remotePrimaryKey
        } else if let superentityRemotePrimaryKey = superentity?.remotePrimaryKeyName {
            return superentityRemotePrimaryKey
        }
        
        return localPrimaryKeyName
    }
    
    /// The local primary key name.
    ///
    /// Defaults to "remoteID" if none is provided
    public var localPrimaryKeyName: String {
        if let localPrimaryKey = userInfo?[RemoteMapping.Key.LocalPrimaryKey.rawValue] as? String {
            return localPrimaryKey
        }
        
        if let superentityLocalPrimaryKey = superentity?.localPrimaryKeyName {
            return superentityLocalPrimaryKey
        }
        
        return RemoteMapping.Key.DefaultLocalPrimaryKey.rawValue
    }
}

/// MARK: - Propery Helpers
/// MARK: Remote Properties
extension NSEntityDescription {
    /// The properties represented on the remote.
    public var remoteProperties: [NSPropertyDescription] {
        return properties.filter { !$0.remoteShouldIgnore }
    }
    
    /// An index of remote property names and the corresponding
    /// property description.
    public func remotePropertiesByName(_ useLocalNames: Bool = false) -> [String: NSPropertyDescription] {
        return remoteProperties
            .reduce([String: NSPropertyDescription]()) { remotePropertiesByName, propertyDescription in
                let key = (useLocalNames) ? propertyDescription.name : propertyDescription.remotePropertyName
                var properties = remotePropertiesByName
                properties[key] = propertyDescription
                
                return properties
            }
    }
}

/// MARK: Relationships
extension NSEntityDescription {
    public var relationships: [NSRelationshipDescription] {
        return properties.flatMap { $0 as? NSRelationshipDescription }
    }
    
    /// The relationships represented on the remote.
    public var remoteRelationships: [NSRelationshipDescription] {
        return remoteProperties.flatMap { $0 as? NSRelationshipDescription }
    }
    
    /// An index of remote property names and the corresponding relationship 
    /// description.
    public func remoteRelationshipsByName(_ useLocalNames: Bool = false) -> [String: NSRelationshipDescription] {
        return remoteRelationships
            .reduce([String: NSRelationshipDescription]()) { remoteRelationshipsByName, relationshipDescription in
                let key = (useLocalNames) ? relationshipDescription.name : relationshipDescription.remotePropertyName
                var relationships = remoteRelationshipsByName
                relationships[key] = relationshipDescription
                
                return relationships
            }
    }
}

/// MARK: Attributes
extension NSEntityDescription {
    public var attributes: [NSAttributeDescription] {
        return properties.flatMap { $0 as? NSAttributeDescription }
    }
    
    public var remoteAttributes: [NSAttributeDescription] {
        return remoteProperties.flatMap { $0 as? NSAttributeDescription }
    }
    
    /// An index of remote attribute names and the corresponding attribute
    /// description.
    public func remoteAttributesByName(_ useLocalNames: Bool = false) -> [String: NSAttributeDescription] {
        return remoteAttributes
            .reduce([String: NSAttributeDescription]()) { remoteAttributesByName, attributeDescription in
                let key = (useLocalNames) ? attributeDescription.name : attributeDescription.remotePropertyName
                var attributes = remoteAttributesByName
                attributes[key] = attributeDescription
                
                return attributes
            }
    }
}

/// MARK: - Query Helpers
/// MARK: Local Predicates
extension NSEntityDescription {
    /// Returns a predicate matching the value of key `localPrimaryKeyName`
    /// against `keyValue`.
    public func matchingLocalPrimaryKey<Value: CVarArg>(keyValue: Value) -> NSPredicate {
        return NSPredicate(format: "%K == %@", localPrimaryKeyName, keyValue)
    }
    
    /// Returns a predicate matching the value of key `localPrimaryKeyName` 
    /// in `keyValues`.
    public func matchingLocalPrimaryKeys<Value: CVarArg>(keyValues: [Value]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", localPrimaryKeyName, keyValues)
    }
    
    /// Returns a predicate matching the value of key `localPrimaryKeyName`
    /// in the set `keyValues`.
    public func matchingLocalPrimaryKeys<Value: CVarArg & Hashable>(keyValues: Set<Value>) -> NSPredicate {
        return NSPredicate(format: "%K in %@", localPrimaryKeyName, keyValues)
    }
}

/// MARK: Remote Predicates
extension NSEntityDescription {
    /// Returns a predicate matching the value of key `remotePrimaryKeyName`
    /// against `keyValue`.
    public func matchingRemotePrimaryKey<Value: CVarArg>(keyValue: Value) -> NSPredicate {
        return NSPredicate(format: "%K == %@", remotePrimaryKeyName, keyValue)
    }
    
    /// Returns a predicate matching the value of key `remotePrimaryKeyName`
    /// in `keyValues`.
    public func matchingRemotePrimaryKeys<Value: CVarArg>(keyValues: [Value]) -> NSPredicate {
        return NSPredicate(format: "%K in %@", remotePrimaryKeyName, keyValues)
    }
    
    /// Returns a predicate matching the value of key `remotePrimaryKeyName`
    /// in the set `keyValues`.
    public func matchingRemotePrimaryKeys<Value: CVarArg & Hashable>(keyValues: Set<Value>) -> NSPredicate {
        return NSPredicate(format: "%K in %@", remotePrimaryKeyName, keyValues)
    }
}
