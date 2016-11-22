import Quick
import Nimble
import CoreDataStack

@testable
import JSONMapping

func objectIsValid(object: NSManagedObject) -> Bool {
    var isValid = false
    do {
        try object.validateForUpdate()
        isValid = true
    } catch {
        print(error)
    }
    
    return isValid
}


class SyncJSONSpec: QuickSpec {
    override func spec() {
        var dataStack: CoreDataStack!
        var managedObjectContext: NSManagedObjectContext!
        let dateFormatter = ISO8601DateFormatter()
        
        beforeSuite {
            let bundle = Bundle.init(for: Object.self)
            dataStack = CoreDataStack(modelName: "DataModel", bundle: bundle, storeType: .inMemory)
            managedObjectContext = dataStack.mainContext
        }
        
        describe("NSManagedObjectContext") {
            let birthdate = Date()
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
            
            afterEach {
                managedObjectContext.reset()
            }
            
            it ("can sync an entire JSON collection") {
                let changes = managedObjectContext.update(
                    entityNamed: "User",
                    withJSON: jsonCollection,
                    dateFormatter: dateFormatter
                )
                
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
                    let changes = managedObjectContext.update(
                        entityNamed: "User",
                        withJSON: duplicateJSONCollection,
                        dateFormatter: dateFormatter
                    )
                    
                    expect(changes.count).to(equal(1))
                }
                
                it("will overwrite changes in previous versions with duplicates") {
                    let changes = managedObjectContext.update(
                        entityNamed: "User",
                        withJSON: duplicateJSONCollection,
                        dateFormatter: dateFormatter
                    )
                    
                    let newUser = changes.first as? User
                    
                    expect(newUser).toNot(beNil())
                    expect(newUser?.gender.rawValue).to(equal(Gender.female.rawValue))
                }
            }
        }
        
        describe("NSManagedObject sync with JSON") {
            var user: User!
            let userBirthdate = Date()
            
            beforeEach {
                user = User(context: managedObjectContext)
                user.name = "Justin"
                user.birthdate = userBirthdate
                user.gender = .male
            }
            
            afterEach {
                managedObjectContext.reset()
            }
            
            it ("can sync with JSON scalar values") {
                let date = Date()
                let customDateFormatter = DateFormatter()
                customDateFormatter.dateFormat = "YYYY-MM-DD'T'HH:mm:ss.SSSZ"
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
            
            it ("does not sync values that do not match the type") {
                expect(objectIsValid(object: user)).to(beTrue())
                
                user.sync(withJSON: [
                    "name": 12345,
                    "gender": [],
                    "birthdate": [:]
                ])
                
                expect(objectIsValid(object: user)).to(beTrue())
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
            
            describe("nil values") {
                it ("overwrites optional properties with nil") {
                    let finn = User(context: managedObjectContext)
                    finn.name = "Finn"
                    finn.gender = .male
                    finn.birthdate = Date()
                    
                    let luci = User(context: managedObjectContext)
                    luci.name = "Luci"
                    luci.gender = .female
                    luci.birthdate = Date()
                    
                    finn.significantOther = luci
                    
                    expect(finn.significantOther).toNot(beNil())
                    expect(objectIsValid(object: finn)).to(beTrue())
                    
                    let breakupJSON: JSONObject = [
                        "significantOther": NSNull()
                    ]
                    
                    finn.sync(withJSON: breakupJSON)
                    
                    expect(finn.significantOther).to(beNil())
                    expect(objectIsValid(object: finn)).to(beTrue())
                }
                
                it ("will not overwirte non-optional properties with nil") {
                    let finn = User(context: managedObjectContext)
                    finn.name = "Finn"
                    finn.gender = .male
                    finn.birthdate = Date()
                    
                    expect(objectIsValid(object: finn)).to(beTrue())
                    
                    let invalidJSON: JSONObject = [
                        "birthdate": NSNull(),
                        "friends": NSNull()
                    ]
                    
                    finn.sync(withJSON: invalidJSON, dateFormatter: dateFormatter)
                    
                    expect(objectIsValid(object: finn)).to(beTrue())
                }
            }
            
            it ("does not create duplicate objects") {
                let birthdate = Date()
                
                let finn = User(context: managedObjectContext)
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
                let luci = User(context: managedObjectContext)
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
            
            describe("subclasses") {
                it ("can hook into when sync starts") {
                    let updatableObject = UpdatableObject(context: managedObjectContext)
                }
                
                it ("can hook into when sync finishes") {
                    let updatableObject = UpdatableObject(context: managedObjectContext)
                    expect(updatableObject.synchronizedAt).to(beNil())
                    
                    updatableObject.sync(withJSON: [
                        "state": "completed"
                    ])
                    
                    expect(updatableObject.synchronizedAt).toNot(beNil())
                }
                
                it ("can reject JSON merges") {
                    let object = InvalidJSONObject(context: managedObjectContext)
                    
                    object.sync(withJSON: [
                        "string": "this is a test string"
                    ])
                    
                    expect(object.string).to(beNil())
                }
                
                it ("can be forced to accept JSON merges") {
                    let object = InvalidJSONObject(context: managedObjectContext)
                    
                    object.sync(
                        withJSON: [
                            "string": "this is a test string"
                        ],
                        force: true
                    )
                    
                    expect(object.string).to(equal("this is a test string"))
                }
                
                it ("can parse custom relationships from the JSON into itself") {
                    let json: JSONObject = [
                        "strings": [
                            "custom": "custom string",
                            "debug": "debug string"
                        ]
                    ]
                    
                    let object = JSONTransformObject(context: managedObjectContext)
                    object.sync(withJSON: json)
                    
                    expect(object.customString).toNot(beNil())
                    expect(object.customString).to(equal("custom string"))
                }
                
                it ("can parse custom relationships via manual override") {
                    let json: JSONObject = [
                        "strings": [
                            "custom": "custom string",
                            "debug": "debug string"
                        ]
                    ]
                    
                    let object = CustomMappingObject(context: managedObjectContext)
                    object.sync(withJSON: json)
                    
                    expect(object.customString).toNot(beNil())
                    expect(object.customString).to(equal("custom string customized further"))
                }
            }
        }
    }
}
