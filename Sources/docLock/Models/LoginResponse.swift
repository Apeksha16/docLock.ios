import Foundation

struct LoginResponse: Decodable {
    let message: String
    let token: String
    let user: User?
}
