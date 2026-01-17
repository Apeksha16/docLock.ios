import Foundation

struct SignupResponse: Decodable {
    let message: String
    let token: String
    let user: User?
}
