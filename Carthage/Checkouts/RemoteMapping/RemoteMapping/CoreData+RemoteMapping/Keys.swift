import CoreData

struct RemoteMapping {
    enum Key: String {
        case RemotePrimaryKey = "remotePrimaryKey"
        case LocalPrimaryKey = "localPrimaryKey"
        case DefaultLocalPrimaryKey = "remoteID"
        
        case PropertyMapping = "remotePropertyName"
        case Ignore = "remoteShouldIgnore"
    }
}
