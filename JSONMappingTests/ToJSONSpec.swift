import Quick
import Nimble
import CoreDataStack
import RemoteMapping

@testable
import JSONMapping

class ToJSONSpec: QuickSpec {
    override func spec() {
        var dataStack: CoreDataStack!
        
        beforeSuite {
            let bundle = Bundle.init(for: Object.self)
            dataStack = CoreDataStack(modelName: "DataModel", bundle: bundle, storeType: .inMemory)
        }
        
        describe("NSManagedObject to JSON") {
            var user: User!
            let dateFormatter = ISO8601DateFormatter()
            let userBirthdate = Date()
            
            beforeEach {
                user = User(context: dataStack.mainContext)
                user.name = "Justin"
                user.birthdate = userBirthdate
                user.gender = .male
            }
            
            afterEach {
                dataStack.mainContext.reset()
            }
            
            it ("can include nil values") {
                let userJSON = user.toJSON(dateFormatter: dateFormatter)
                
                expect(userJSON.count).to(equal(8))
                expect(userJSON["name"] as? String).to(equal(user.name))
                expect(userJSON["birthdate"] as? String).to(equal(dateFormatter.string(from: userBirthdate)))
                expect(userJSON["gender"] as? String).to(equal(Gender.male.rawValue))
                expect(userJSON["significantOther"] as? NSNull).to(equal(NSNull()))
                expect((userJSON["friends"] as? [JSONObject])).toNot(beNil())
                expect((userJSON["friends"] as? [JSONObject])?.count).to(equal(0))
            }
            
            it ("can exclude nil values") {
                let userJSON = user.toJSON(dateFormatter: dateFormatter, includeNilValues: false)
                
                expect(userJSON.count).to(equal(4))
                expect(userJSON["name"] as? String).to(equal(user.name))
                expect(userJSON["birthdate"] as? String).to(equal(dateFormatter.string(from: userBirthdate)))
                expect(userJSON["gender"] as? String).to(equal(Gender.male.rawValue))
                expect(userJSON["significantOther"]).to(beNil())
                expect(userJSON["friends"]).to(be([]))
            }
            
            it ("can exclude keys from the JSON") {
                let birthdate = Date()
                
                user.name = "Justin"
                user.birthdate = birthdate
                user.gender = .male
                
                let userJSON = user.toJSON(
                    dateFormatter: dateFormatter,
                    excludeKeys: [
                        "birthdate"
                    ]
                )
                
                expect(userJSON.count).to(equal(user.entity.properties.count - 1))
                expect(userJSON.keys).to(contain("name", "gender"))
                expect(userJSON.keys).toNot(contain("birthdate"))
            }
            
            it ("can transform itself to JSON based on the currently registered changes") {
                try! dataStack.mainContext.save()
                
                expect(user.hasChanges).to(beFalse())
                
                user.name = "Michael"
                
                let userJSON = user.toChangedJSON(dateFormatter: dateFormatter)
                
                expect(userJSON.count).to(equal(1))
                expect(userJSON["name"]).toNot(beNil())
                
                dataStack.mainContext.delete(user)
                try! dataStack.mainContext.save()
            }
            
            describe("with relationships") {
                beforeEach {
                    let significantOther: User = User(context: dataStack.mainContext)
                    significantOther.name = "Paige"
                    significantOther.birthdate = Date()
                    significantOther.gender = .female
                    
                    user.significantOther = significantOther
                    
                    let friend: User = User(context: dataStack.mainContext)
                    friend.name = "Finn"
                    friend.birthdate = Date()
                    friend.gender = .male
                    
                    user.friends.insert(friend)
                }
                
                it ("can exclude all relationships") {
                    let attributeCount = user.entity.attributes.count
                    
                    let userJSON = user.toJSON(dateFormatter: dateFormatter, relationshipType: .none)
                    
                    expect(userJSON.count).to(equal(attributeCount))
                    expect(userJSON["friends"]).to(beNil())
                    expect(userJSON["significantOther"]).to(beNil())
                }
                
                it ("can embed all relationships") {
                    let userJSON = user.toJSON(dateFormatter: dateFormatter, relationshipType: .embedded)
                    
                    expect(userJSON["significantOther"]).toNot(beNil())
                    expect(userJSON["friends"]).toNot(beNil())
                    expect((userJSON["friends"] as? [JSONObject])?.count).to(equal(1))
                }
                
                it ("can embed relationships via primary key") {
                    let userJSON = user.toJSON(dateFormatter: dateFormatter, relationshipType: .reference)
                    
                    expect(userJSON["significantOther"]).toNot(beNil())
                    expect(userJSON["significantOther"] as? String).to(equal("Paige"))
                    
                    expect((userJSON["friends"] as? [String])).toNot(beEmpty())
                    expect((userJSON["friends"] as? [String])).to(contain("Finn"))
                    expect((userJSON["friends"] as? [String])?.count).to(equal(user.friends.count))
                }
                
                it ("can embed relationships using a custom strategy") {
                    let userJSON = user.toChangedJSON(dateFormatter: dateFormatter, relationshipType: .custom({ object in
                        return RelationshipWrapper(primaryKey: object.primaryKey as! String)
                    }))
                    
                    let significantOtherValue = RelationshipWrapper(primaryKey: "Paige")
                    let friendValue = RelationshipWrapper(primaryKey: "Finn")
                    
                    expect(userJSON["significantOther"] as? RelationshipWrapper).to(equal(significantOtherValue))
                    
                    expect((userJSON["friends"] as? [RelationshipWrapper])).toNot(beEmpty())
                    expect((userJSON["friends"] as? [RelationshipWrapper])).to(contain(friendValue))
                    expect((userJSON["friends"] as? [RelationshipWrapper])?.count).to(equal(user.friends.count))
                }
                
                it ("will not embed parent relationships in children") {
                    let userJSON = user.toJSON(dateFormatter: dateFormatter, relationshipType: .embedded)
                    
                    let childJSON = userJSON["significantOther"] as? JSONObject
                    
                    expect(childJSON).toNot(beNil())
                    expect(childJSON?["significantOther"]).to(beNil())
                }
            }
        }
    }
}


struct RelationshipWrapper: Equatable {
    public static func == (lhs: RelationshipWrapper, rhs: RelationshipWrapper) -> Bool {
        return (lhs.primaryKey == rhs.primaryKey)
    }
    
    let primaryKey: String
}
