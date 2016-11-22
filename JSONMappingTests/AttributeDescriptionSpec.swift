import Quick
import Nimble
import CoreDataStack

@testable
import JSONMapping

class AttributeDescriptionSpec: QuickSpec {
    override func spec() {
        var dataStack: CoreDataStack!
        var object: Object!
        var attributeIndex: [String: NSAttributeDescription] {
            return object.entity.attributesByName
        }
        
        beforeSuite {
            let bundle = Bundle.init(for: Object.self)
            dataStack = CoreDataStack(modelName: "DataModel", bundle: bundle, storeType: .inMemory)
            object = Object(context: dataStack.mainContext)
        }
        
        it ("can transform boolean values") {
            guard let booleanAttribute = attributeIndex["boolean"] else { fatalError() }
            
            let remoteValue = false
            let boolValue = booleanAttribute.value(fromJSONValue: remoteValue) as? Bool
            
            expect(boolValue).toNot(beNil())
            expect(boolValue).to(beFalse())
            
            let numberOneValue = booleanAttribute.value(fromJSONValue: 1) as? Bool
            
            expect(numberOneValue).toNot(beNil())
            expect(numberOneValue).to(beTrue())
            
            let zeroValue = booleanAttribute.value(fromJSONValue: 0) as? Bool
            
            expect(zeroValue).toNot(beNil())
            expect(zeroValue).to(beFalse())
            
            let randomValue = booleanAttribute.value(fromJSONValue: arc4random_uniform(100)) as? Bool
            
            expect(randomValue).toNot(beNil())
            expect(randomValue).to(beTrue())
            
            /// !!!: I'm not sure if this is desired, but it's definitely happening.
            let stringValue = booleanAttribute.value(fromJSONValue: "") as? Bool
            expect(stringValue).to(beNil())
            expect(stringValue).to(beFalsy())
            
            /// !!!: I'm not sure if this is desired, but it's definitely happening.
            let trueStringValue = booleanAttribute.value(fromJSONValue: "true") as? Bool
            expect(trueStringValue).to(beNil())
            expect(trueStringValue).to(beFalsy())
            
            /// !!!: I'm not sure if this is desired, but it's definitely happening.
            let falseStringValue = booleanAttribute.value(fromJSONValue: "false") as? Bool
            expect(falseStringValue).to(beNil())
            expect(falseStringValue).to(beFalsy())
            
            /// !!!: I'm not sure if this is desired, but it's definitely happening.
            let randomStringValue = booleanAttribute.value(fromJSONValue: "alshegwe") as? Bool
            expect(randomStringValue).to(beNil())
            expect(randomStringValue).to(beFalsy())
        }
        
        it ("can transform a string to a 16-bit integer") {
            guard let intAttribute = attributeIndex["int16"] else { fatalError() }
            
            let stringValue = intAttribute.value(fromJSONValue: "12") as? Int16
            
            expect(stringValue).toNot(beNil())
            expect(stringValue).to(equal(12))
        }
        
        it ("can transform a string to a 32-bit integer") {
            guard let intAttribute = attributeIndex["int32"] else { fatalError() }
            
            let stringValue = intAttribute.value(fromJSONValue: "12") as? Int32
            
            expect(stringValue).toNot(beNil())
            expect(stringValue).to(equal(12))
        }
        
        it ("can transform a string to a 64-bit integer") {
            guard let intAttribute = attributeIndex["int64"] else { fatalError() }
            
            let stringValue = intAttribute.value(fromJSONValue: "12") as? Int64
            
            expect(stringValue).toNot(beNil())
            expect(stringValue).to(equal(12))
        }
        
        it ("can transform a date string to a date") {
            let ISOFormatString = "YYYY-MM-DD'T'hh:mm:ss.sss"
            let date = Date()
            let customDateFormatter = DateFormatter()
            customDateFormatter.dateFormat = ISOFormatString
            
            let birthdateString = customDateFormatter.string(from: date)
            
            guard let dateAttribute = attributeIndex["date"] else { fatalError() }
            
            let stringValue = dateAttribute.value(fromJSONValue: birthdateString, dateFormatter: customDateFormatter)
            
            expect(stringValue).toNot(beNil())
        }
    }
}
