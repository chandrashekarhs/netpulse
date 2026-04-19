import Foundation

enum GatewayDetector {
    static func detect(completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/sbin/route")
            proc.arguments = ["get", "default"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError  = Pipe()
            guard (try? proc.run()) != nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            proc.waitUntilExit()
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                                encoding: .utf8) ?? ""
            let gateway = output.components(separatedBy: "\n")
                .first { $0.trimmingCharacters(in: .whitespaces).hasPrefix("gateway:") }
                .flatMap { $0.components(separatedBy: ":").last }
                .map    { $0.trimmingCharacters(in: .whitespaces) }
                .flatMap { $0.isEmpty ? nil : $0 }
            DispatchQueue.main.async { completion(gateway) }
        }
    }
}
