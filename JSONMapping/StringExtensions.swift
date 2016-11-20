import Foundation

internal extension String {
    func capitalizingFirstLetter() -> String {
        let firstLetter = String(characters.prefix(1)).capitalized
        let remainder = String(characters.dropFirst())
        
        return firstLetter + remainder
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
