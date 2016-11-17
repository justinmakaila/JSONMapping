import XCTest
import CoreData


private let CoreDataStoreURL = {
    return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("RemoteMappingTests.tests")
}()

extension DateFormatter {
    class func ISO8601DateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter
    }
}

func entity(named name: String, inContext managedObjectContext: NSManagedObjectContext) -> NSEntityDescription {
    guard let entity = NSEntityDescription.entity(forEntityName: name, in: managedObjectContext)
    else {
        fatalError("Could not load entity")
    }
    
    return entity
}

func insertEntity<A: NSManagedObject>(named name: String, inContext managedObjectContext: NSManagedObjectContext) -> A {
    guard let object =  NSEntityDescription.insertNewObject(forEntityName: name, into: managedObjectContext) as? A
    else {
        fatalError("Could not insert object for entity \(name)")
    }
    
    return object
}

class RemoteMappingTestCase: XCTestCase {
    var managedObjectContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()

        self.managedObjectContext = setupManagedObjectContext()
    }
    
    func setupManagedObjectContext() -> NSManagedObjectContext {
        // Load the model from `Wellth.xcdatamodeld`
        guard let modelURL = Bundle(for: RemoteMappingTestCase.self).url(forResource: "TestModel", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            fatalError("Model not found")
        }
        
        // Create a persistent store coordinator for the model
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // Add the `NSSQLiteStoreType` to the coordinator
        // !!!: Because there is no feasible way to handle the error, `try!` will result in a runtime error if this operation fails.
        try! persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: CoreDataStoreURL, options: nil)
        
        // Create the `NSManagedObjectContext`
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        
        return context
    }
}
