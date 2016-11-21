import Foundation
import CoreData


public typealias JSONObject = [String: Any]

/// Represents relationships for JSON serialization
public enum RelationshipType: String {
    /// Don't include any relationship
    case none = "none"
    /// Include embedded objects
    case embedded = "embedded"
    /// Include refrences by primary key
    case reference = "reference"
}

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

public protocol JSONRepresentable {
    func toJSON(dateFormatter: JSONDateFormatter, relationshipType: RelationshipType, parent: NSManagedObject?, excludeKeys: Set<String>, includeNilValues: Bool) -> JSONObject
    func toChangedJSON(dateFormatter: JSONDateFormatter, relationshipType: RelationshipType, parent: NSManagedObject?, excludeKeys: Set<String>, includeNilValues: Bool) -> JSONObject
    func sync(withJSON json: JSONObject, dateFormatter: JSONDateFormatter?, parent: NSManagedObject?, force: Bool)
}
