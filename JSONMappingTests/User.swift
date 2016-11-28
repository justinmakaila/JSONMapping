import CoreData

enum Gender: String {
    case male = "male"
    case female = "female"
    case other = "other"
}

class User: NSManagedObject {
    @NSManaged
    var name: String
    
    @NSManaged
    var birthdate: Date
    
    @NSManaged
    private var genderValue: String
    var gender: Gender {
        get {
            return Gender(rawValue: genderValue)!
        }
        set {
            genderValue = newValue.rawValue
        }
    }
    
    @NSManaged
    var significantOther: User?
    
    @NSManaged
    var friends: Set<User>
    
    @NSManaged
    var pet: Pet?
}
