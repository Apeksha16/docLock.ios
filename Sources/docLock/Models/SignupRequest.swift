import Foundation

struct SignupRequest: Encodable {
    let mobile: String
    let mpin: String
    let name: String
    let deviceId: String
}
