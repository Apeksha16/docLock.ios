import SwiftUI
import VisionKit
import Vision

#if os(iOS)
@available(iOS 16.0, *)
struct CardScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onScan: (String, String?, String?) -> Void // number, expiry, name
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scannerViewController = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scannerViewController.delegate = context.coordinator
        
        // Add Close Button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(context.coordinator, action: #selector(Coordinator.closeScanner), for: .touchUpInside)
        
        scannerViewController.view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: scannerViewController.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: scannerViewController.view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: CardScannerView
        var scannedNumber: String?
        var scannedExpiry: String?
        var scannedName: String?
        
        init(_ parent: CardScannerView) {
            self.parent = parent
        }
        
        @objc func closeScanner() {
            parent.isPresented = false
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Optional: Handle invalid tap
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }
        
        func processItems(_ items: [RecognizedItem]) {
            for item in items {
                switch item {
                case .text(let text):
                    let content = text.transcript
                    
                    // 1. Detect Card Number (13-19 digits, possibly with spaces)
                    if scannedNumber == nil {
                        let potentialNumber = content.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                        if potentialNumber.allSatisfy({ $0.isNumber }) && potentialNumber.count >= 13 && potentialNumber.count <= 19 {
                            scannedNumber = potentialNumber
                        }
                    }
                    
                    // 2. Detect Expiry (MM/YY or MM/YYYY)
                    if scannedExpiry == nil {
                        if let expiry = extractExpiry(from: content) {
                            scannedExpiry = expiry
                        }
                    }
                    
                    // 3. Detect Name (Hard logic, skipping specifically for now as it's error prone without ML)
                    
                default:
                    break
                }
            }
            
            // If we found at least a number, or better yet, num + expiry
            if let number = scannedNumber { // Strict: Needs number at least
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.parent.onScan(number, self.scannedExpiry, self.scannedName)
                    self.parent.isPresented = false
                }
            }
        }
        
        func extractExpiry(from text: String) -> String? {
            // Regex for MM/YY
            let pattern = #"\b(0[1-9]|1[0-2])/([0-9]{2})\b"#
            if let range = text.range(of: pattern, options: .regularExpression) {
                return String(text[range])
            }
            return nil
        }
    }
}
#endif
