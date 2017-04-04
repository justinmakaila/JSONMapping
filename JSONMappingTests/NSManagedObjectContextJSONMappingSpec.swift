import Quick
import Nimble
import CoreDataStack
import RemoteMapping

@testable
import JSONMapping


final class NSManagedObjectContext_JSONMappingSpec: QuickSpec {
    override func spec() {
        let bundle = Bundle.init(for: Object.self)
        let dataStack = CoreDataStack(modelName: "DataModel", bundle: bundle, storeType: .inMemory)
        let dateFormatter = DateFormatter()
        
        describe("NSManagedObjectContext") {
            /// Create a new context that is a child of the main context so it's changes are never persisted beyond
            /// the main context.
            let managedObjectContext = dataStack.newBackgroundContext(parentContext: dataStack.mainContext)
            
            /// Reset the context and the main context (just in case) after ever test.
            afterEach {
                managedObjectContext.reset()
                dataStack.mainContext.reset()
            }
            
            context("given an entity") {
                let entityName = "User"
                let today = Date()
                let localPrimaryKey = "name"
                let userJSONCollection: [JSONObject] = [
                    [
                        "name": "justin",
                        "birthdate": dateFormatter.string(from: today),
                        "gender": "male"
                    ]
                ]
                
                it("can return an index of NSManagedObjectIDs by given String attributes.") {
                    let user = User(context: managedObjectContext)
                    user.merge(withJSON: userJSONCollection.first!, dateFormatter: dateFormatter)
                }
                
                context("detecting which primary keys in a given collection need to be updated or inserted") {
                    it("detects inserts") {
                        let primaryKeys: Set<String> = ["justin"]
                        let (updates, inserts) = managedObjectContext.detectChanges(
                            inEntity: entityName,
                            primaryKeyCollection: primaryKeys,
                            localPrimaryKeyName: localPrimaryKey,
                            predicate: nil
                        )
                        
                        expect(updates).to(beEmpty())
                        expect(inserts).toNot(beEmpty())
                    }
                    
                    it("detects updates") {
                        let user = User(context: managedObjectContext)
                        user.merge(
                            withJSON: userJSONCollection.first!,
                            dateFormatter: dateFormatter
                        )
                        
                        expect(user.name).to(equal("justin"))
                        
                        try! managedObjectContext.save()
                        
                        expect(user.isInserted).to(beTrue())
                        
                        let (updates, inserts) = managedObjectContext.detectChanges(
                            inEntity: entityName,
                            primaryKeyCollection: ["justin"],
                            localPrimaryKeyName: localPrimaryKey,
                            predicate: nil
                        )
                        
                        expect(updates).toNot(beEmpty())
                        expect(inserts).to(beEmpty())
                    }
                }
                
                context("given a collection of JSON") {

                }
                
                it("returns an array of tuples representing updates to be made (NSManagedObjectContext, JSONObject) and inserts (JSONObject)") { }
            }
        }
    }
}
