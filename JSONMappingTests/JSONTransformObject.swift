import CoreData
import JSONMapping

class JSONTransformObject: NSManagedObject {
    @NSManaged
    var customString: String?
    
    override func parseJSON(json: JSONObject, propertyDescription: NSPropertyDescription) -> Any? {
        let localKey = propertyDescription.name
        
        if localKey == "customString" {
            if let strings = json["strings"] as? JSONObject {
                if let value = strings["custom"] as? String {
                    return value
                }
            }
        }
        
        return super.parseJSON(json: json, propertyDescription: propertyDescription)
    }
}
