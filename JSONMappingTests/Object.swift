import CoreData


class Object: NSManagedObject {
    @NSManaged
    var boolean: Bool
    
    @NSManaged
    var data: Data
    
    @NSManaged
    var date: Date?
    
    @NSManaged
    var decimal: NSDecimalNumber
    
    @NSManaged
    var double: Double
    
    @NSManaged
    var float: Float
    
    @NSManaged
    var int16: Int16
    
    @NSManaged
    var int32: Int32
    
    @NSManaged
    var int64: Int64
    
    @NSManaged
    var string: String
}
