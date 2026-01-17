import Foundation

struct VerifyMobileResponse: Decodable {
    let exists: Bool
    let message: String?
}
