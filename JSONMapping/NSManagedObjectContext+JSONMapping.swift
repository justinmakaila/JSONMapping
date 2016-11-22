import CoreData


extension Sequence where Iterator.Element == JSONObject {
    func indexByPrimaryKey(key: String) -> [(String, Iterator.Element)] {
        return flatMap { json in
            guard let primaryKey = json[key] as? String
            else {
                return nil
            }
            
            return (primaryKey, json)
        }
    }
}

extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}

extension NSManagedObjectContext {
    public func upsert(json: JSONObject, inEntity entity: NSEntityDescription, withPrimaryKey primaryKey: String, dateFormatter: JSONDateFormatter? = nil) -> NSManagedObject {
        guard let entityName = entity.name else { fatalError() }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "%@ == %@", entity.localPrimaryKeyName, primaryKey)
        fetchRequest.fetchLimit = 1
        
        var result: NSManagedObject? = nil
        do {
            result = try fetch(fetchRequest).first
        } catch { }
        
        /// Fetch or create the object
        let object = result
            ?? NSEntityDescription.insertNewObject(forEntityName: entityName, into: self)
        
        object.sync(withJSON: json, dateFormatter: dateFormatter)
        
        return object
    }
    
    public func update(entityNamed entityName: String, withJSON json: [JSONObject], dateFormatter: JSONDateFormatter? = nil, parent: NSManagedObject? = nil, predicate: NSPredicate? = nil) -> [NSManagedObject] {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: self)
        else {
            return []
        }
        
        return update(
            entity: entityDescription,
            withJSON: json,
            dateFormatter: dateFormatter,
            parent: parent,
            predicate: predicate
        )
    }
    
    public func update(entity: NSEntityDescription, withJSON json: [JSONObject], dateFormatter: JSONDateFormatter? = nil, parent: NSManagedObject? = nil, predicate: NSPredicate? = nil) -> [NSManagedObject] {
        let shouldLookForParent = ((parent == nil) && (predicate == nil))
        
        var finalPredicate = predicate
        if let parentRelationship = entity.parentRelationship, shouldLookForParent {
            finalPredicate = NSPredicate(format: "%K = nil", parentRelationship.name)
        }
        
        let (updates, inserts) = detectChanges(
            inEntity: entity.name!,
            withJSON: json,
            localPrimaryKey: entity.localPrimaryKeyName,
            remotePrimaryKey: entity.remotePrimaryKeyName,
            predicate: finalPredicate
        )
        
        var changes: [NSManagedObject] = []
        changes += inserts.map { json in
            let object = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into: self)
            object.sync(withJSON: json, dateFormatter: dateFormatter)
            return object
        }

        changes += updates.map { (object, json) in
            object.sync(withJSON: json, dateFormatter: dateFormatter)
            return object
        }
        
        return changes
    }
}


extension NSManagedObjectContext {
//    /// Returns a dictionary with the keys set to the value of `attributeName`, and the values as the object ID as
//    /// matching `predicate` (if included).
//    /// This should only be invoked on the context's queue.
//    /// This doesn't include pending changes
////    public func objectIDIndex(inEntity entityName: String, byAttribute attributeName: String, matching predicate: NSPredicate? = nil) -> [AnyHashable: NSManagedObjectID] {
////        let expression = NSExpressionDescription()
////        expression.name = "objectID"
////        expression.expression = NSExpression.expressionForEvaluatedObject()
////        expression.expressionResultType = .objectIDAttributeType
////        
////        let request = NSFetchRequest<NSDictionary>(entityName: entityName)
////        request.predicate = predicate
////        request.resultType = .dictionaryResultType
////        request.propertiesToFetch = [expression, attributeName]
////        
////        return objectIDIndex(fetchRequest: request) { (object: NSDictionary) -> AnyHashable? in
////            return object.value(forKey: attributeName) as? AnyHashable
////        }
////    }
//    
//    public func objectIDIndex(inEntity entityName: String, matching predicate: NSPredicate? = nil, byAttribute attribute: (NSManagedObject) -> AnyHashable) -> [AnyHashable: NSManagedObjectID] {
//        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
//        fetchRequest.predicate = predicate
//        fetchRequest.includesPendingChanges = true
//        fetchRequest.returnsDistinctResults = true
//        
//        return objectIDIndex(fetchRequest: fetchRequest, byAttribute: attribute)
//    }
//    
//    public func objectIDIndex<T: NSFetchRequestResult>(fetchRequest: NSFetchRequest<T>, byAttribute attribute: (T) -> AnyHashable?) -> [AnyHashable: NSManagedObjectID] where T: NSObject {
//        do {
//            let objects = try fetch(fetchRequest)
//            return objects.reduce([:]) { memory, object in
//                guard let objectID = object.value(forKeyPath: "objectID") as? NSManagedObjectID,
//                    let key = attribute(object)
//                else {
//                    return memory
//                }
//                
//                var copy = memory
//                copy[key] = objectID
//                return copy
//            }
//        } catch {
//            return [:]
//        }
//    }
//    
    public func objectIDs(inEntity entityName: String, withAttribute attributeName: String, predicate: NSPredicate? = nil) -> [String: NSManagedObjectID] {
//        let expression = NSExpressionDescription()
//        expression.name = "objectID"
//        expression.expression = NSExpression.expressionForEvaluatedObject()
//        expression.expressionResultType = .objectIDAttributeType

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.includesPendingChanges = true
        fetchRequest.returnsDistinctResults = true
        
        do {
            let objects = try fetch(fetchRequest)
            return objects.reduce([String: NSManagedObjectID]()) { objectIDIndex, object in
                guard let fetchedID = object.value(forKeyPath: attributeName) as? String,
                    objectIDIndex[fetchedID] == nil
                else {
                    return objectIDIndex
                }
                
                var objectIDIndexCopy = objectIDIndex
                objectIDIndexCopy[fetchedID] = object.objectID
                return objectIDIndexCopy
            }
        } catch {
            return [:]
        }
    }

    /// Detects changes between the local entity collection and the supplied JSON array based on the local and remote
    /// primary keys. Returns a tuple of updates (an array of `NSManagedObject` and `JSON` tuples), and inserts
    /// (JSON objects that do not have a local counterpart).
    public func detectChanges(inEntity entityName: String, withJSON json: [JSONObject], localPrimaryKey: String, remotePrimaryKey: String, predicate: NSPredicate? = nil) -> (updates: [(NSManagedObject, JSONObject)], inserts: [JSONObject]) {
        let localObjectIDIndex = objectIDs(inEntity: entityName, withAttribute: localPrimaryKey, predicate: predicate)
        let existingRemoteIDs = Set(localObjectIDIndex.keys)
        
        let remoteObjectIDIndex = Dictionary(json.indexByPrimaryKey(key: remotePrimaryKey))
        let remoteObjectIDs = Set(remoteObjectIDIndex.keys)
        
        let newObjectIDs = remoteObjectIDs.subtracting(existingRemoteIDs)
        let updateObjectIDs = existingRemoteIDs.intersection(remoteObjectIDs)
        
        let inserts: [JSONObject] = newObjectIDs.flatMap { remoteObjectIDIndex[$0] }
        let updates: [(NSManagedObject, JSONObject)] = updateObjectIDs.flatMap { remoteID in
            if let json = remoteObjectIDIndex[remoteID],
                let objectID = localObjectIDIndex[remoteID] {
                return (object(with: objectID), json)
            }
            
            return nil
        }
        
        return (updates, inserts)
    }
}
