import AppKit

enum LoginItemManager {
    static var plistPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/LaunchAgents/\(Constants.bundleID).plist"
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    static func toggle() {
        if isEnabled {
            try? FileManager.default.removeItem(atPath: plistPath)
        } else {
            guard let exePath = Bundle.main.executablePath else { return }
            let dir = (plistPath as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? makePlist(executablePath: exePath).write(toFile: plistPath, atomically: true, encoding: .utf8)
            // Intentionally no `launchctl load` — that would start a second instance immediately.
            // launchd picks up plists in ~/Library/LaunchAgents/ automatically at next login.
        }
    }

    private static func makePlist(executablePath: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>             <string>\(Constants.bundleID)</string>
            <key>ProgramArguments</key>
            <array><string>\(executablePath)</string></array>
            <key>RunAtLoad</key>         <true/>
            <key>KeepAlive</key>         <false/>
        </dict>
        </plist>
        """
    }


}
