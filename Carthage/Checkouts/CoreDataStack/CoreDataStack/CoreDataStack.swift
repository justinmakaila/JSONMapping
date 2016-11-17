import Foundation
import CoreData


open class CoreDataStack {
    public enum StoreType {
        case inMemory
        case sqLite
    }
    
    // MARK: - Variables
    
    let storeType: StoreType
    let storeName: String?
    let modelName: String
    let modelBundle: Bundle
    
    /// The context for the main queue
    fileprivate var _mainContext: NSManagedObjectContext?
    open var mainContext: NSManagedObjectContext {
        get {
            if _mainContext == nil {
                let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                context.undoManager = nil
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                context.parent = self.writerContext
                context.name = "CoreDataStack Main Context"
                
                _mainContext = context
            }
            
            return _mainContext!
        }
    }
    
    /// The writer context
    fileprivate var _writerContext: NSManagedObjectContext?
    fileprivate var writerContext: NSManagedObjectContext {
        get {
            if _writerContext == nil {
                let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                context.undoManager = nil
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                context.persistentStoreCoordinator = self.persistentStoreCoordinator
                context.name = "CoreDataStack Writer Context"
                
                _writerContext = context
            }
            
            return _writerContext!
        }
    }
    
    /// The persistent store coordinator shared across all `NSManagedObjectContext` instances
    /// created by this instance
    fileprivate var _persistentStoreCoordinator: NSPersistentStoreCoordinator?
    fileprivate var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        get {
            if _persistentStoreCoordinator == nil {
                let filePath = (self.storeName ?? self.modelName) + ".sqlite"
                
                var model: NSManagedObjectModel?
                
                if let momdModelURL = self.modelBundle.url(forResource: self.modelName, withExtension: "momd") {
                    model = NSManagedObjectModel(contentsOf: momdModelURL)
                }
                
                if let momModelURL = self.modelBundle.url(forResource: self.modelName, withExtension: "mom") {
                    model = NSManagedObjectModel(contentsOf: momModelURL)
                }
                
                guard let unwrappedModel = model else { fatalError("Model with model name \(self.modelName) not found in bundle \(self.modelBundle)") }
                let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: unwrappedModel)
                
                switch self.storeType {
                case .inMemory:
                    do {
                        try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
                    } catch let error as NSError {
                        fatalError("There was an error creating the persistentStoreCoordinator: \(error)")
                    }
                    
                    break
                case .sqLite:
                    let storeURL = self.applicationDocumentsDirectory().appendingPathComponent(filePath)
                    let storePath = storeURL.path
                    
                    let shouldPreloadDatabase = !FileManager.default.fileExists(atPath: storePath)
                    if shouldPreloadDatabase {
                        if let preloadedPath = self.modelBundle.path(forResource: self.modelName, ofType: "sqlite") {
                            let preloadURL = URL(fileURLWithPath: preloadedPath)
                            
                            do {
                                try FileManager.default.copyItem(at: preloadURL, to: storeURL)
                            } catch let error as NSError {
                                fatalError("Oops, could not copy preloaded data. Error: \(error)")
                            }
                        }
                    }
                    
                    do {
                        try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])
                    } catch {
                        print("Error encountered while reading the database. Please allow all the data to download again.")
                        
                        do {
                            try FileManager.default.removeItem(atPath: storePath)
                            
                            do {
                                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])
                            } catch let addPersistentError as NSError {
                                fatalError("There was an error creating the persistentStoreCoordinator: \(addPersistentError)")
                            }
                        } catch let removingError as NSError {
                            fatalError("There was an error removing the persistentStoreCoordinator: \(removingError)")
                        }
                    }
                    
                    let shouldExcludeSQLiteFromBackup = self.storeType == .sqLite
                    if shouldExcludeSQLiteFromBackup {
                        do {
                            try (storeURL as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
                        } catch let excludingError as NSError {
                            fatalError("Excluding SQLite file from backup caused an error: \(excludingError)")
                        }
                    }
                    
                    break
                }
                
                _persistentStoreCoordinator = persistentStoreCoordinator
            }
            
            return _persistentStoreCoordinator!
        }
    }
    
    fileprivate lazy var disposablePersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        guard let modelURL = self.modelBundle.url(forResource: self.modelName, withExtension: "momd"), let model = NSManagedObjectModel(contentsOf: modelURL)
            else { fatalError("Model named \(self.modelName) not found in bundle \(self.modelBundle)") }
        
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch let error as NSError {
            fatalError("There was an error creating the disposablePersistentStoreCoordinator: \(error)")
        }
        
        return persistentStoreCoordinator
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextWillSave, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
    }
    
    // MARK: - Initalizers
    
    public convenience init?() {
        let bundle = Bundle.main
        if let bundleName = bundle.infoDictionary?["CFBundleName"] as? String {
            self.init(modelName: bundleName)
        } else {
            return nil
        }
    }
    
    public init(modelName: String, bundle: Bundle = Bundle.main, storeType: StoreType = .sqLite, storeName: String? = nil) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType
        self.storeName = storeName
    }
    
    // MARK: - Observers
    @objc
    internal func newDisposableMainContextWillSave(_ notification: Notification) {
        if let context = notification.object as? NSManagedObjectContext {
            context.reset()
        }
    }
    
    @objc
    internal func backgroundContextDidSave(_ notification: Notification) {
        if Thread.isMainThread {
            fatalError("Background context saved in the main thread. Use context's `performBlock`")
        } else {
            mainContext.perform {
                self.mainContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }
    
    // MARK: - Public
    
    /// Creates a new disposable main context.
    open func newDisposableMainContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.disposablePersistentStoreCoordinator
        context.undoManager = nil
        
        NotificationCenter.default.addObserver(self, selector: #selector(CoreDataStack.newDisposableMainContextWillSave(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: context)
        
        return context
    }
    
    /// Creates a new private context.
    open func newBackgroundContext(_ name: String? = nil, parentContext: NSManagedObjectContext? = nil, mergeChanges: Bool = false) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        if let parentContext = parentContext {
            context.parent = parentContext
        } else {
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
        }
        
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.name = name
        
        if mergeChanges {
            NotificationCenter.default.addObserver(self, selector: #selector(CoreDataStack.backgroundContextDidSave(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
        }
        
        return context
    }
    
    /// Creates a new background context, performs `operation` within the context.
    open func performInNewBackgroundContext(_ operation: @escaping (_ backgroundContext: NSManagedObjectContext) -> ()) {
        let context = newBackgroundContext()
        
        context.perform {
            operation(context)
        }
    }
    
    /// Persists the stack. Calls `completion` with an error if something fails.
    /// This will not save child context's. They must be saved before invoking this method
    /// for their changes to persist.
    open func persistWithCompletion(_ completion: ((Error?) -> Void)? = nil) {
        let saveWriterContext: (Void) -> Void = {
            self.writerContext.perform {
                do {
                    try self.writerContext.save()
                    DispatchQueue.main.async {
                        completion?(nil)
                    }
                } catch {
                    completion?(error)
                }
            }
        }
        
        mainContext.perform {
            do {
                try self.mainContext.save()
                saveWriterContext()
            } catch {
                completion?(error)
            }
        }
    }
    
    /// Drops the entire stack.
    open func drop() {
        guard let store = self.persistentStoreCoordinator.persistentStores.last,
            let storeURL = store.url
            else {
                fatalError("Persistent store coordinator not found")
        }
        
        let storePath = storeURL.path
        let sqliteFile = (storePath as NSString).deletingPathExtension
        let fileManager = FileManager.default
        
        self._writerContext = nil
        self._mainContext = nil
        self._persistentStoreCoordinator = nil
        
        let shm = sqliteFile + ".sqlite-shm"
        if fileManager.fileExists(atPath: shm) {
            do {
                try fileManager.removeItem(at: URL(fileURLWithPath: shm))
            } catch let error as NSError {
                print("Could not delete persistent store shm: \(error)")
            }
        }
        
        let wal = sqliteFile + ".sqlite-wal"
        if fileManager.fileExists(atPath: wal) {
            do {
                try fileManager.removeItem(at: URL(fileURLWithPath: wal))
            } catch let error as NSError {
                print("Could not delete persistent store wal: \(error)")
            }
        }
        
        if fileManager.fileExists(atPath: storePath) {
            do {
                try fileManager.removeItem(at: storeURL)
            } catch let error as NSError {
                print("Could not delete sqlite file: \(error)")
            }
        }
    }
    
    fileprivate func applicationDocumentsDirectory() -> URL {
        #if os(tvOS)
            return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
        #else
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        #endif
    }
}
