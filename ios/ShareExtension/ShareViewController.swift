//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Segun Daniel Oluwadare on 01/02/2026.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // IMPORTANT: Must match the App Group in Runner.entitlements
    private let appGroupId = "group.com.olvora.shared"
    private let sharedKey = "ShareKey"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Make the view transparent - we process and dismiss immediately
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            completeRequest()
            return
        }

        let group = DispatchGroup()
        var sharedItems: [[String: Any]] = []

        for attachment in attachments {
            group.enter()

            // Handle images (receipts, photos)
            if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                    defer { group.leave() }

                    if let url = item as? URL {
                        if let savedPath = self?.saveFile(from: url, type: "image") {
                            sharedItems.append(["type": "image", "path": savedPath])
                        }
                    } else if let image = item as? UIImage {
                        if let savedPath = self?.saveImage(image) {
                            sharedItems.append(["type": "image", "path": savedPath])
                        }
                    }
                }
            }
            // Handle PDFs (digital receipts)
            else if attachment.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { [weak self] (item, error) in
                    defer { group.leave() }

                    if let url = item as? URL {
                        if let savedPath = self?.saveFile(from: url, type: "pdf") {
                            sharedItems.append(["type": "file", "path": savedPath])
                        }
                    }
                }
            }
            // Handle URLs
            else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
                    defer { group.leave() }

                    if let url = item as? URL {
                        sharedItems.append(["type": "url", "value": url.absoluteString])
                    }
                }
            }
            // Handle text
            else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (item, error) in
                    defer { group.leave() }

                    if let text = item as? String {
                        sharedItems.append(["type": "text", "value": text])
                    }
                }
            }
            else {
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.saveSharedData(sharedItems)
            self?.openMainApp()
        }
    }

    private func saveFile(from url: URL, type: String) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }

        let fileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
        let destinationURL = containerURL.appendingPathComponent(fileName)

        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL.path
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }

    private func saveImage(_ image: UIImage) -> String? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId),
              let imageData = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }

        let fileName = "\(UUID().uuidString).jpg"
        let destinationURL = containerURL.appendingPathComponent(fileName)

        do {
            try imageData.write(to: destinationURL)
            return destinationURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    private func saveSharedData(_ items: [[String: Any]]) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else { return }

        if let jsonData = try? JSONSerialization.data(withJSONObject: items, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            userDefaults.set(jsonString, forKey: sharedKey)
            userDefaults.synchronize()
        }
    }

    private func openMainApp() {
        // Open the main app using the custom URL scheme
        guard let url = URL(string: "olvora-expenses://shared") else {
            completeRequest()
            return
        }

        // Use the responder chain to open URL
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                break
            }
            responder = responder?.next
        }

        // Complete the extension request after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.completeRequest()
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
