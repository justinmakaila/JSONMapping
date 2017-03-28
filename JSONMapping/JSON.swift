import Foundation
import CoreData


public typealias JSONObject = [String: Any]

public protocol JSONDateFormatter {
    func string(from: Date) -> String
    func date(from: String) -> Date?
}

extension DateFormatter: JSONDateFormatter { }

@available(iOS 10.0, *)
extension ISO8601DateFormatter: JSONDateFormatter { }


public protocol JSONValidator {
    func isValid(json: JSONObject) -> Bool
}

public protocol JSONParser {
    func parseJSON(json: JSONObject, propertyDescription: NSPropertyDescription) -> Any?
}


/// Represents relationships for JSON serialization
public enum RelationshipType: Equatable {
    public static func == (lhs: RelationshipType, rhs: RelationshipType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.embedded, .embedded):
            return true
        case (.reference, .reference):
            return true
        default:
            return false
        }
    }
    
    
    /// Don't include any relationship
    case none
    
    /// Include embedded objects
    case embedded

    /// Include refrences by primary key
    case reference
    
    case custom((NSManagedObject) -> Any)
    
    init?(string: String) {
        switch string {
        case "none":
            self = .none
        case "embedded":
            self = .embedded
        case "reference":
            self = .reference
        default:
            return nil
        }
    }
}



public protocol JSONRepresentable {
    func toJSON(dateFormatter: JSONDateFormatter, relationshipType: RelationshipType, parent: NSManagedObject?, excludeKeys: Set<String>, includeNilValues: Bool) -> JSONObject
    
    func toChangedJSON(dateFormatter: JSONDateFormatter, relationshipType: RelationshipType, parent: NSManagedObject?, excludeKeys: Set<String>, includeNilValues: Bool) -> JSONObject
    
    func sync(withJSON json: JSONObject, dateFormatter: JSONDateFormatter?, parent: NSManagedObject?, force: Bool)
}
