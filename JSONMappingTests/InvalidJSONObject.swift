import CoreData
import JSONMapping


class InvalidJSONObject: NSManagedObject {
    @NSManaged
    var string: String?
    
    override func isValid(json: JSONObject) -> Bool {
        return false
    }
}
