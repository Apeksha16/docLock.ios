import Foundation

struct User: Decodable, Identifiable {
    let uid: String
    let mobile: String?
    let name: String
    let profileImageUrl: String?
    let storageUsed: Int64? // In bytes
    let addedAt: Date? // Timestamp when friend was added
    
    var id: String { return uid }
}
