import CoreData


class Pet: NSManagedObject {
    @NSManaged
    var name: String
    
    @NSManaged
    var owners: Set<User>
}
