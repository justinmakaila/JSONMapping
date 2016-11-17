/// Represents an entity and it's primary keys
public protocol RemoteEntityType {
    /// The remote primary key name.
    var remotePrimaryKeyName: String { get }
    /// The local primary key name.
    var localPrimaryKeyName: String { get }
}
