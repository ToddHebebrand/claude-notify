import Foundation
import UserNotifications
import AppKit

final class Delegate: NSObject, UNUserNotificationCenterDelegate {
    let clickCommand: String?
    init(clickCommand: String?) { self.clickCommand = clickCommand }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           let cmd = clickCommand, !cmd.isEmpty {
            let task = Process()
            task.launchPath = "/bin/sh"
            task.arguments = ["-c", cmd]
            try? task.run()
        }
        DispatchQueue.main.async { NSApp.terminate(nil) }
    }
}

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: ClaudeNotify <title> <body> [click-shell-cmd] [sound]\n".data(using: .utf8)!)
    exit(64)
}
let title = args[1]
let body = args[2]
let clickCmd: String? = args.count >= 4 ? args[3] : nil
let soundName: String = args.count >= 5 ? args[4] : "Glass"

NSApplication.shared.setActivationPolicy(.accessory)

let center = UNUserNotificationCenter.current()
let delegate = Delegate(clickCommand: clickCmd)
center.delegate = delegate

let sema = DispatchSemaphore(value: 0)
center.requestAuthorization(options: [.alert, .sound]) { _, _ in sema.signal() }
_ = sema.wait(timeout: .now() + 5)

let content = UNMutableNotificationContent()
content.title = title
content.body = body
content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundName).aiff"))

let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
let added = DispatchSemaphore(value: 0)
center.add(req) { _ in added.signal() }
_ = added.wait(timeout: .now() + 5)

let timeoutSec: TimeInterval = 300
DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSec) { NSApp.terminate(nil) }
NSApp.run()
