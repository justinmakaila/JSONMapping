import CoreData
import JSONMapping


class UpdatableObject: NSManagedObject {
    @NSManaged
    var state: String
    
    @NSManaged
    var synchronizedAt: Date?
    
    var isSynchronized: Bool {
        return synchronizedAt != nil
    }
    
    override func didSyncWithJSON(success: Bool) {
        if success {
            synchronizedAt = Date()
        }
    }
}
