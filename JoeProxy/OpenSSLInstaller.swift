import Foundation

class OpenSSLInstaller {
    func installOpenSSL() -> Bool {
        do {
            let brewInstallOutput = try shell("brew install openssl")
            print("OpenSSL installation output: \(brewInstallOutput)")
            return true
        } catch {
            print("Failed to install OpenSSL: \(error)")
            return false
        }
    }

    func shell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh") // Use zsh or /bin/bash for macOS

        try task.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
}
