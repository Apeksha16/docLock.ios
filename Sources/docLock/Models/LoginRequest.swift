import Foundation

struct LoginRequest: Encodable {
    let mobile: String
    let mpin: String
    let deviceId: String
}
