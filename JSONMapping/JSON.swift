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
    func toJSON(relationshipType: RelationshipType, excludeKeys: Set<String>, includeNilValues: Bool, dateFormatter: JSONDateFormatter?, parent: NSManagedObject?) -> JSONObject
    func toChangedJSON(relationshipType: RelationshipType, excludeKeys: Set<String>, includeNilValues: Bool, dateFormatter: JSONDateFormatter?, parent: NSManagedObject?) -> JSONObject
    func merge(withJSON json: JSONObject, dateFormatter: JSONDateFormatter?, parent: NSManagedObject?, force: Bool)
}


public protocol JSONInitializable { }

extension JSONInitializable where Self: NSManagedObject, Self: JSONRepresentable {
    @available(iOS 10.0, *)
    public init(context: NSManagedObjectContext, json: JSONObject, dateFormatter: JSONDateFormatter? = nil) {
        self.init(context: context)
        merge(withJSON: json, dateFormatter: dateFormatter)
    }
    
    public init(entity entityDescription: NSEntityDescription, insertInto context: NSManagedObjectContext, json: JSONObject, dateFormatter: JSONDateFormatter? = nil) {
        self.init(entity: entityDescription, insertInto: context)
        merge(withJSON: json, dateFormatter: dateFormatter)
    }
}
