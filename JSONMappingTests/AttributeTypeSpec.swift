import Quick
import Nimble
import CoreData

@testable
import JSONMapping

class AttributeTypeSpec: QuickSpec {
    override func spec() {
        let allAttributeTypes: [NSAttributeType] = [
            .integer16AttributeType,
            .integer32AttributeType,
            .integer64AttributeType,
            .decimalAttributeType,
            .doubleAttributeType,
            .floatAttributeType,
            .stringAttributeType,
            .binaryDataAttributeType,
            .booleanAttributeType,
            .dateAttributeType,
            .objectIDAttributeType,
            .transformableAttributeType,
            .undefinedAttributeType,
        ]
        
        it ("can tell if it's a number") {
            allAttributeTypes.forEach { attributeType in
                if [NSAttributeType.integer16AttributeType,
                    NSAttributeType.integer32AttributeType,
                    NSAttributeType.integer64AttributeType,
                    NSAttributeType.decimalAttributeType,
                    NSAttributeType.doubleAttributeType,
                    NSAttributeType.floatAttributeType].contains(attributeType) {
                    expect(attributeType.isNumber).to(beTrue())
                } else {
                    expect(attributeType.isNumber).to(beFalse())
                }
            }
        }
        
        it ("can tell if it's a string") {
            allAttributeTypes.forEach { attributeType in
                if attributeType == .stringAttributeType {
                    expect(attributeType.isString).to(beTrue())
                } else {
                    expect(attributeType.isString).to(beFalse())
                }
            }
        }
        
        it ("can tell if it's data") {
            allAttributeTypes.forEach { attributeType in
                if attributeType == .binaryDataAttributeType {
                    expect(attributeType.isData).to(beTrue())
                } else {
                    expect(attributeType.isData).to(beFalse())
                }
            }
        }
        
        it ("can tell if it's a date") {
            allAttributeTypes.forEach { attributeType in
                if attributeType == .dateAttributeType {
                    expect(attributeType.isDate).to(beTrue())
                } else {
                    expect(attributeType.isDate).to(beFalse())
                }
            }
        }
        
        it ("can tell if it's a decimal number") {
            allAttributeTypes.forEach { attributeType in
                if attributeType == .decimalAttributeType {
                    expect(attributeType.isDecimalNumber).to(beTrue())
                } else {
                    expect(attributeType.isDecimalNumber).to(beFalse())
                }
            }
        }
    }
}
