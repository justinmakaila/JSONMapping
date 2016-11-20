import Quick
import Nimble
import CoreDataStack

@testable
import JSONMapping


class SyncJSONSpec: QuickSpec {
    override func spec() {
        var dataStack: CoreDataStack!
        
        beforeSuite {
            let bundle = Bundle.init(for: Object.self)
            dataStack = CoreDataStack(modelName: "DataModel", bundle: bundle, storeType: .inMemory)
        }
        
        describe("NSManagedObjectContext") {
            let birthdate = Date()
            let dateFormatter = ISO8601DateFormatter()
            let jsonCollection: [JSONObject] = [
                [
                    "name": "Justin",
                    "gender": "male",
                    "birthdate": dateFormatter.string(from: birthdate)
                ],
                [
                    "name": "Paige",
                    "gender": "female",
                    "birthdate": dateFormatter.string(from: birthdate)
                ]
            ]
            
            it ("can sync an entire JSON collection") {
                let changes = dataStack.mainContext.update(entityNamed: "User", withJSON: jsonCollection)
                expect(changes.count).to(equal(2))
            }
            
            describe("inserting duplicates") {
                let duplicateJSONCollection: [JSONObject] = [
                    [
                        "name": "Justin",
                        "gender": "male",
                        "birthdate": dateFormatter.string(from: birthdate)
                    ],
                    [
                        "name": "Justin",
                        "gender": "female",
                        "birthdate": dateFormatter.string(from: birthdate)
                    ],
                ]
                
                it ("will not insert duplicates") {
                    let changes = dataStack.mainContext.update(entityNamed: "User", withJSON: duplicateJSONCollection)
                    
                    expect(changes.count).to(equal(1))
                }
                
                it("will overwrite changes in previous versions with duplicates") {
                    let changes = dataStack.mainContext.update(entityNamed: "User", withJSON: duplicateJSONCollection)
                    
                    let newUser = changes.first as? User
                    
                    expect(newUser).toNot(beNil())
                    expect(newUser?.gender.rawValue).to(equal(Gender.female.rawValue))
                }
            }
        }
        
        describe("NSManagedObject sync with JSON") {
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
            
            it ("can sync with JSON scalar values") {
                let date = Date()
                let customDateFormatter = DateFormatter()
                customDateFormatter.dateFormat = "YYYY-MM-DD'T'hh:mm:ss.sssZ"
                let birthdateString = customDateFormatter.string(from: date)
                
                let json: JSONObject = [
                    "name": "Michael",
                    "gender": "male",
                    "birthdate": birthdateString
                ]
                
                user.sync(withJSON: json, dateFormatter: customDateFormatter)
                
                expect(user.name).to(equal("Michael"))
                expect(user.gender).to(equal(Gender.male))
                
                expect(user.birthdate).toNot(beNil())
    //                expect(user.birthdate).to(equal(date))
            }
            
            it ("can sync with JSON relationships") {
                let birthdate = Date()
                let json: JSONObject = [
                    "name": "Justin",
                    "gender": "male",
                    "birthdate": dateFormatter.string(from: birthdate),
                    "significantOther": [
                        "name": "Paige",
                        "gender": "female",
                        "birthdate": dateFormatter.string(from: birthdate)
                    ],
                    "friends": [
                        [
                            "name": "Finn",
                            "gender": "male",
                            "birthdate": dateFormatter.string(from: birthdate)
                        ],
                        [
                            "name": "Luci",
                            "gender": "female",
                            "birthdate": dateFormatter.string(from: birthdate),
                            "significantOther": "Finn"
                        ]
                    ]
                ]
                
                user.sync(withJSON: json, dateFormatter: dateFormatter)
                
                expect(user.significantOther).toNot(beNil())
                expect(user.significantOther?.significantOther).to(equal(user))
                
                expect(user.friends).toNot(beNil())
                expect(user.friends.count).to(equal(2))
            }
            
            it ("does not create duplicate objects") {
                let birthdate = Date()
                
                let finn = User(context: dataStack.mainContext)
                finn.sync(withJSON: [
                    "name": "Finn",
                    "gender": "male",
                    "birthdate": dateFormatter.string(from: birthdate)
                ])
                
                expect(finn.primaryKey as? String).to(equal("Finn"))
                
                let luciJSON: JSONObject = [
                    "name": "Luci",
                    "gender": "female",
                    "birthdate": dateFormatter.string(from: birthdate)
                ]
                let luci = User(context: dataStack.mainContext)
                luci.sync(withJSON: luciJSON)
                
                luci.significantOther = finn
                
                expect(luci.primaryKey as? String).to(equal("Luci"))
                expect(finn.significantOther).to(equal(luci))
                expect(luci.significantOther).to(equal(finn))
                
                /// Attempt to add the JSON version of Luci to the user
                user.sync(
                    withJSON: [
                        "friends": [
                            luci.toJSON(dateFormatter: dateFormatter)
                        ]
                    ],
                    dateFormatter: dateFormatter
                )
                
                expect(user.friends.count).to(equal(1))
                expect(user.friends.first).to(equal(luci))
            }
            
            describe("NSManagedObject subclass") {
                it("can reject JSON merges") {
                    let object = InvalidJSONObject(context: dataStack.mainContext)
                    
                    object.sync(withJSON: [
                        "string": "this is a test string"
                    ])
                    
                    expect(object.string).to(beNil())
                }
                
                it("can be forced to accept JSON merges") {
                    let object = InvalidJSONObject(context: dataStack.mainContext)
                    
                    object.sync(
                        withJSON: [
                            "string": "this is a test string"
                        ],
                        force: true
                    )
                    
                    expect(object.string).to(equal("this is a test string"))
                }
            }
        }
    }
}
