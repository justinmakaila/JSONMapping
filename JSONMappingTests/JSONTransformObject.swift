import CoreData
import JSONMapping

class JSONTransformObject: NSManagedObject {
    @NSManaged
    var customString: String?
    
    override func parseJSON(json: JSONObject, localKey: String, remoteKey: String) -> Any? {
        if localKey == "customString" {
            if let strings = json["strings"] as? JSONObject {
                if let value = strings["custom"] as? String {
                    return value
                }
            }
        }
        
        return super.parseJSON(json: json, localKey: localKey, remoteKey: remoteKey)
    }
}
