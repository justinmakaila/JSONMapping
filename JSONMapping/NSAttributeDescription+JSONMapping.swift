import CoreData


extension NSAttributeType {
    var isNumber: Bool {
        switch self {
            case .integer16AttributeType,
                 .integer32AttributeType,
                 .integer64AttributeType,
                 .decimalAttributeType,
                 .doubleAttributeType,
                 .floatAttributeType:
            return true
        default:
            return false
        }
    }
    
    var isBoolean: Bool {
        return self == .booleanAttributeType
    }
    
    var isString: Bool {
        return self == .stringAttributeType
    }
    
    var isData: Bool {
        return self == .binaryDataAttributeType
    }
    
    var isDate: Bool {
        return self == .dateAttributeType
    }
    
    var isDecimalNumber: Bool {
        return self == .decimalAttributeType
    }
}

extension NSAttributeDescription {
    /// Attempts to transform `remoteValue` to the value as specified by `self`.
    ///
    ///  - Parameters:
    ///    - remoteValue: The value to transform, e.g. value from a JSON object
    ///    - dateFormatter: The date formatter to use to transform `Date` values.
    ///
    ///  - Returns: The transformed value of `remoteValue` as specified by self or nil.
    public func value(fromJSONValue value: Any, dateFormatter: JSONDateFormatter? = nil) -> Any? {
        /// If `remoteValue` is already the type specified by `valueClassName`, return it.
        if let valueClassName = attributeValueClassName,
            let valueClass: AnyClass = NSClassFromString(valueClassName),
            (value as AnyObject).isKind(of: valueClass) {
            /// Booleans are stored as NSNumber. Therefore, NSNumber instances will not be transformed
            if !attributeType.isBoolean {
                return value
            }
        }
        
        if attributeType.isData {
            return NSKeyedArchiver.archivedData(withRootObject: value)
        }
        
        if let remoteValue = value as? String {
            if attributeType.isNumber {
                return NumberFormatter().number(from: remoteValue)
            } else if attributeType.isDate {
                return dateFormatter?.date(from: remoteValue)
            } else if attributeType.isDecimalNumber {
                return NSDecimalNumber(string: remoteValue)
            }
        }
        
        if let remoteValue = value as? NSNumber {
            if attributeType.isString {
                return "\(remoteValue)"
            } else if attributeType.isDecimalNumber {
                return NSDecimalNumber(decimal: remoteValue.decimalValue)
            } else if attributeType.isDate {
                return Date(timeIntervalSince1970: remoteValue.doubleValue)
            } else if attributeType.isBoolean {
                return remoteValue.boolValue
            }
        }
        
        return nil
    }
}
