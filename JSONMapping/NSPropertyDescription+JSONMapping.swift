import CoreData


extension NSPropertyDescription {
    /// The default relationship mapping.
    ///
    /// This overrides
    public var relationshipMapping: RelationshipType? {
        guard let relationshipMappingValue = userInfo?["relationshipType"] as? String
        else {
            return nil
        }
        
        return RelationshipType(rawValue: relationshipMappingValue)
    }
}
