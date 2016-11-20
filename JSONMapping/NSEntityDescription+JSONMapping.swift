import CoreData


extension NSEntityDescription {
    var parentRelationship: NSRelationshipDescription? {
        return relationships
            .filter { $0.destinationEntity?.name == name && !$0.isToMany }
            .first
    }
}
