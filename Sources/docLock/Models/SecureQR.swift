import Foundation

struct SecureQR: Identifiable, Codable {
    let id: String
    let label: String
    let documentIds: [String]
    let qrCodeUrl: String // URL to the generated QR code image
    let createdAt: Date
    let expiresAt: Date?
    let isActive: Bool
    
    init(id: String, label: String, documentIds: [String], qrCodeUrl: String, createdAt: Date, expiresAt: Date? = nil, isActive: Bool = true) {
        self.id = id
        self.label = label
        self.documentIds = documentIds
        self.qrCodeUrl = qrCodeUrl
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
}
