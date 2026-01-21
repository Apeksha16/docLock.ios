import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit
import CoreImage

// MARK: - Secure QR Service
class SecureQRService: ObservableObject {
    @Published var secureQRs: [SecureQR] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // Start listening to user's QR codes
    func startListening(userId: String) {
        listener?.remove()
        print("🔐 SecureQRService: Starting listener for user \(userId)")
        
        listener = db.collection("users").document(userId).collection("secureQRs")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("🔴 SecureQRService Error: \(error.localizedDescription)")
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.secureQRs = documents.compactMap { doc -> SecureQR? in
                    let data = doc.data()
                    guard let label = data["label"] as? String,
                          let documentIds = data["documentIds"] as? [String],
                          let qrCodeUrl = data["qrCodeUrl"] as? String,
                          let createdAtTimestamp = data["createdAt"] as? Timestamp,
                          let isActive = data["isActive"] as? Bool else {
                        return nil
                    }
                    
                    let expiresAtTimestamp = data["expiresAt"] as? Timestamp
                    
                    return SecureQR(
                        id: doc.documentID,
                        label: label,
                        documentIds: documentIds,
                        qrCodeUrl: qrCodeUrl,
                        createdAt: createdAtTimestamp.dateValue(),
                        expiresAt: expiresAtTimestamp?.dateValue(),
                        isActive: isActive
                    )
                }
                
                print("🟢 SecureQRService: Loaded \(self?.secureQRs.count ?? 0) QR codes")
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // Generate QR code
    func generateQR(userId: String, label: String, documentIds: [String], completion: @escaping (Bool, String?) -> Void) {
        print("🔐 SecureQRService: Generating QR for label '\(label)' with \(documentIds.count) documents")
        
        isLoading = true
        error = nil
        
        // Create QR data
        let qrId = UUID().uuidString
        let qrData = [
            "qrId": qrId,
            "userId": userId,
            "documentIds": documentIds
        ] as [String : Any]
        
        // Convert to JSON string
        guard let jsonData = try? JSONSerialization.data(withJSONObject: qrData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.isLoading = false
                completion(false, "Failed to encode QR data")
            }
            return
        }
        
        // Generate QR code image
        let qrImage = generateQRCode(from: jsonString)
        
        // Upload QR image to Firebase Storage
        uploadQRImage(userId: userId, qrId: qrId, image: qrImage) { [weak self] qrCodeUrl, uploadError in
            guard let self = self else { return }
            
            if let uploadError = uploadError {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, uploadError)
                }
                return
            }
            
            guard let qrCodeUrl = qrCodeUrl else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, "Failed to get QR code URL")
                }
                return
            }
            
            // Save QR metadata to Firestore
            let qrMetadata: [String: Any] = [
                "label": label,
                "documentIds": documentIds,
                "qrCodeUrl": qrCodeUrl,
                "createdAt": FieldValue.serverTimestamp(),
                "isActive": true
            ]
            
            self.db.collection("users").document(userId).collection("secureQRs").document(qrId)
                .setData(qrMetadata) { error in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let error = error {
                            print("🔴 SecureQRService: Failed to save QR metadata: \(error.localizedDescription)")
                            completion(false, error.localizedDescription)
                        } else {
                            print("🟢 SecureQRService: QR generated successfully")
                            completion(true, nil)
                        }
                    }
                }
        }
    }
    
    // Delete QR code
    func deleteQR(userId: String, qrId: String, completion: @escaping (Bool, String?) -> Void) {
        print("🔐 SecureQRService: Deleting QR \(qrId)")
        
        // First, get the QR to retrieve the image URL for deletion
        db.collection("users").document(userId).collection("secureQRs").document(qrId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            // Delete from Firestore
            self.db.collection("users").document(userId).collection("secureQRs").document(qrId).delete { error in
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    // Delete image from Storage (optional, can be done in background)
                    if let data = snapshot?.data(),
                       let qrCodeUrl = data["qrCodeUrl"] as? String {
                        self.deleteQRImage(from: qrCodeUrl)
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func generateQRCode(from string: String) -> UIImage {
        let data = Data(string.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("H", forKey: "inputCorrectionLevel")
            
            if let qrCodeImage = filter.outputImage {
                // Scale up the QR code
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = qrCodeImage.transformed(by: transform)
                
                let context = CIContext()
                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        // Return placeholder if generation fails
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
    
    private func uploadQRImage(userId: String, qrId: String, image: UIImage, completion: @escaping (String?, String?) -> Void) {
        guard let imageData = image.pngData() else {
            completion(nil, "Failed to convert image to data")
            return
        }
        
        let path = "users/\(userId)/qr_codes/\(qrId).png"
        let storageRef = storage.reference().child(path)
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(nil, error.localizedDescription)
                } else {
                    completion(url?.absoluteString, nil)
                }
            }
        }
    }
    
    private func deleteQRImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let storageRef = storage.reference(forURL: url.absoluteString)
        
        storageRef.delete { error in
            if let error = error {
                print("⚠️ SecureQRService: Failed to delete QR image: \(error.localizedDescription)")
            } else {
                print("🟢 SecureQRService: QR image deleted")
            }
        }
    }
}
