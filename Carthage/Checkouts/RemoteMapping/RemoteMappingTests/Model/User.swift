import Foundation
import CoreData


public final class User: NSManagedObject {
    
    @NSManaged
    public var age: Int16
    
    @NSManaged
    fileprivate var favoriteWordsValue: Data
    public var favoriteWords: [String] {
        get {
            guard let favoriteWords = NSKeyedUnarchiver.unarchiveObject(with: favoriteWordsValue) as? [String]
            else {
                return []
            }
            
            return favoriteWords
        }
        set {
            favoriteWordsValue = NSKeyedArchiver.archivedData(withRootObject: newValue)
        }
    }
    
    @NSManaged
    public var transformable: [String]
    
    @NSManaged
    public var birthdate: Date
    
    @NSManaged
    public var height: Float
    
    @NSManaged
    public var name: String
    
    @NSManaged
    public var detail: String
    
    /// MARK: Relationships
    
    @NSManaged
    public var bestFriend: User?
}
