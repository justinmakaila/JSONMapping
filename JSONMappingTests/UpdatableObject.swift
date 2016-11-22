import CoreData
import JSONMapping


class UpdatableObject: NSManagedObject {
    @NSManaged
    var updatedAt: Date
    
    @NSManaged
    var synchronizedAt: Date?
    
    var isSynchronized: Bool {
        return synchronizedAt != nil
    }
    
    var hasUpdates: Bool {
        if let synchronizedAt = synchronizedAt {
            return synchronizedAt < updatedAt
        }
        
        return false
    }
    
    override func didSyncWithJSON(success: Bool) {
        if success {
            synchronizedAt = Date()
        } else if !hasUpdates {
            synchronizedAt = Date()
        }
    }
}
