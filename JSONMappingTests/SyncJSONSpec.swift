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
                let birthdate = dateFormatter.string(from: Date())
                let updatedBirthdate = dateFormatter.string(from: Date(timeIntervalSinceNow: 500))
                let duplicateJSONCollection: [JSONObject] = [
                    [
                        "name": "Justin",
                        "gender": "male",
                        "birthdate": birthdate,
                        "friends": [
                            [
                                "name": "Finn",
                                "gender": "male",
                                "birthdate":birthdate
                            ]
                        ],
                        "pet": [
                            "name": "Slayer"
                        ]
                    ],
                    [
                        "name": "Paige",
                        "gender": "female",
                        "birthdate": birthdate,
                        "friends": [
                            [
                                "name": "Finn",
                                "gender": "male",
                                "birthdate": updatedBirthdate
                            ]
                        ],
                        "pet": [
                            "name": "Slayer"
                        ]
                    ],
                ]
                
                it ("will not insert duplicates") {
                    for _ in 0..<5 {
                        let _ = managedObjectContext.update(
                            entityNamed: "User",
                            withJSON: duplicateJSONCollection,
                            dateFormatter: dateFormatter
                        )
                    }
                    
                    let userCountRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
                    let userCount = try! managedObjectContext.count(for: userCountRequest)
                    
                    expect(userCount).to(equal(3))
                    
                    let petCountRequest = NSFetchRequest<NSManagedObject>(entityName: "Pet")
                    let petCount = try! managedObjectContext.count(for: petCountRequest)
                    
                    expect(petCount).to(equal(1))
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
                
                user.sync(
                    withJSON: [
                        "name": "Michael",
                        "gender": "male",
                        "birthdate": birthdateString,
                        "metadata": [
                            "nickname": "Shredlord",
                            "favoriteNumber": "666",
                            "favoriteWords": [
                                "yolo",
                                "lol",
                                "ok"
                            ]
                        ]
                    ],
                    dateFormatter: customDateFormatter
                )
                
                expect(user.name).to(equal("Michael"))
                expect(user.gender).to(equal(Gender.male))
                expect(user.birthdate).toNot(beNil())
                expect(user.metadata).toNot(beEmpty())
                expect(user.metadata["nickname"] as? String).to(equal("Shredlord"))
                expect(user.metadata["favoriteNumber"] as? String).to(equal("666"))
                expect(user.metadata["favoriteWords"] as? [String]).to(contain(["yolo", "lol", "ok"]))
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
            
            describe ("syncing relationships") {
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
                
                it ("can sync one-way to-one relationships") {
                    let json: JSONObject = [
                        "name": "Finn",
                        "gender": "male",
                        "birthdate": dateFormatter.string(from: userBirthdate),
                        "crush": [
                            "name": "Luci",
                            "gender": "female",
                            "birthdate": dateFormatter.string(from: userBirthdate)
                        ]
                    ]
                    
                    let finn = User(context: managedObjectContext)
                    finn.sync(withJSON: json, dateFormatter: dateFormatter)
                    
                    expect(finn.crush).toNot(beNil())
                    expect(finn.crush?.primaryKey as? String).to(equal("Luci"))
                    
                    var validationError: Error?
                    do {
                        try finn.validateForInsert()
                        try finn.validateForUpdate()
                        
                        try finn.crush?.validateForInsert()
                        try finn.crush?.validateForUpdate()
                    } catch {
                        validationError = error
                    }
                    
                    expect(validationError).to(beNil())
                }
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
                finn.sync(
                    withJSON: [
                        "name": "Finn",
                        "gender": "male",
                        "birthdate": dateFormatter.string(from: birthdate)
                    ],
                    dateFormatter: dateFormatter
                )
                
                expect(finn.primaryKey as? String).to(equal("Finn"))
                
                let luci = User(context: managedObjectContext)
                luci.sync(
                    withJSON: [
                        "name": "Luci",
                        "gender": "female",
                        "birthdate": dateFormatter.string(from: birthdate)
                    ],
                    dateFormatter: dateFormatter
                )
                
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
