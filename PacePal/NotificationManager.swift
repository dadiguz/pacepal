import UserNotifications
import SwiftUI

// MARK: - Delegate (shows notifications while app is in foreground)

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Pet image renderer

@MainActor
func renderPetAttachmentURL(dna: PetDNA, pose: PetPose) -> URL? {
    // Use frame 1 for a mid-stride look
    let grid = buildCharacterGrid(dna: dna, pose: pose, frame: 1)
    let view = PetSpriteView(grid: grid, dna: dna, pixelSize: 18)
        .background(Color.clear)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 3
    guard let uiImage = renderer.uiImage else { return nil }

    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("pet_notif_\(dna.id).png")
    guard let data = uiImage.pngData() else { return nil }
    try? data.write(to: url)
    return url
}

// MARK: - Manager

struct NotificationManager {

    // MARK: - Permission

    static func requestPermission(completion: (() -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.delegate = NotificationDelegate.shared
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            completion?()
        }
    }

    // MARK: - Immediate (threshold just crossed)

    static func fireIfThresholdCrossed(petName: String, oldEnergy: Double, newEnergy: Double, attachmentURL: URL? = nil) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            for (threshold, title, body, id) in notifications(petName: petName) {
                guard oldEnergy > threshold && newEnergy <= threshold else { continue }

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                if let url = attachmentURL,
                   let attachment = try? UNNotificationAttachment(identifier: "pet", url: url) {
                    content.attachments = [attachment]
                }

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
                let request = UNNotificationRequest(identifier: "\(id)_now", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    // MARK: - Background schedule

    static func scheduleEnergyNotifications(petName: String, energyResetDate: Date, decaySeconds: Double, attachmentURL: URL? = nil) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            center.removePendingNotificationRequests(withIdentifiers: thresholdIDs)

            let now = Date()
            let currentEnergy = max(0, min(1, 1.0 - now.timeIntervalSince(energyResetDate) / decaySeconds))

            for (threshold, title, body, id) in notifications(petName: petName) {
                guard currentEnergy > threshold else { continue }
                let secondsUntil = (currentEnergy - threshold) * decaySeconds
                guard secondsUntil > 1 else { continue }

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default
                if let url = attachmentURL,
                   let attachment = try? UNNotificationAttachment(identifier: "pet", url: url) {
                    content.attachments = [attachment]
                }

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: secondsUntil, repeats: false)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: thresholdIDs)
    }

    // MARK: - Private

    private static let thresholdIDs = ["energy_95", "energy_75", "energy_60", "energy_50", "energy_25", "energy_14", "energy_5"]

    static func notifications(petName: String) -> [(threshold: Double, title: String, body: String, id: String)] {
        [
            (0.95, petName,                                    randomPhrase(),                                          "energy_95"),
            (0.75, petName,                                    randomPhrase(),                                          "energy_75"),
            (0.60, petName,                                    randomPhrase(),                                          "energy_60"),
            (0.50, L("notif.demanding_title", petName),        L("notif.demanding_body"),                               "energy_50"),
            (0.25, L("notif.low_energy_title", petName),       L("notif.low_energy_body"),                              "energy_25"),
            (0.14, L("notif.collapsing_title", petName),       L("notif.collapsing_body"),                              "energy_14"),
            (0.05, L("notif.critical_title", petName),         L("notif.critical_body"),                                "energy_5"),
        ]
    }

    private static func randomPhrase() -> String {
        RunningPhrase.all.randomElement()?.localized ?? L("notif.fallback")
    }
}
