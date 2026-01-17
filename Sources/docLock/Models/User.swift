import Foundation

struct User: Decodable {
    let uid: String
    let mobile: String?
    let name: String
    
    var id: String { return uid }
}
