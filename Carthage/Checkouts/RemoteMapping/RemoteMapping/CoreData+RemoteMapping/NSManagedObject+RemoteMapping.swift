import CoreData


public extension NSManagedObject {
    /// The receiver's local primary key
    var localPrimaryKeyName: String {
        return entity.localPrimaryKeyName
    }
    
    /// The receiver's remote primary key
    var remotePrimaryKeyName: String {
        return entity.remotePrimaryKeyName
    }
    
    /// The value for `localPrimaryKeyName`.
    var primaryKey: Any? {
        return value(forKey: localPrimaryKeyName)
    }
}
