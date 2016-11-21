import CoreData
import JSONMapping


final class CustomMappingObject: JSONTransformObject {
    override func parseJSON(json: JSONObject, propertyDescription: NSPropertyDescription) -> Any? {
        let localKey = propertyDescription.name
        
        if localKey == "customString" {
            if let strings = json["strings"] as? JSONObject {
                if let value = strings["custom"] as? String {
                    self.customString = transformCustomString(string: value)
                    return nil
                }
            }
        }
        
        return super.parseJSON(json: json, propertyDescription: propertyDescription)
    }
    
    private func transformCustomString(string: String) -> String {
        return string + " customized further"
    }
}
