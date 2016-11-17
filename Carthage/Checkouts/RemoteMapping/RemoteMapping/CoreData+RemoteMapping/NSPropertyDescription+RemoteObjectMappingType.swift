import CoreData


extension NSPropertyDescription: RemoteObjectMappingType {
    /// The remote property key.
    ///
    /// Defaults to `name`.
    public var remotePropertyName: String {
        return userInfo?[RemoteMapping.Key.PropertyMapping.rawValue] as? String ?? name
    }
    
    /// Whether or not the property should be ignored.
    ///
    /// Checks to see if the "remoteShouldIgnore" key is
    /// present in `userInfo`. If it is, returns true.
    public var remoteShouldIgnore: Bool {
        return userInfo?[RemoteMapping.Key.Ignore.rawValue] != nil
    }
}
