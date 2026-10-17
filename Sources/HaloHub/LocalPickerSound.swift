import Foundation

/// Uses the user's installed Apple runtime for development auditioning only.
/// Build staging amplifies this sample into the Dev bundle, never release assets.
enum LocalPickerSound {
    static let resourceName = "hover-apple-picker"
    static var url: URL? {
        if let bundled = Bundle.main.url(forResource: resourceName, withExtension: "caf") { return bundled }
        #if DEBUG
        let volumes = URL(fileURLWithPath: "/Library/Developer/CoreSimulator/Volumes")
        let manager = FileManager.default
        let roots = (try? manager.contentsOfDirectory(at: volumes, includingPropertiesForKeys: nil)) ?? []
        for volume in roots.sorted(by: { $0.path < $1.path }) {
            let runtimes = volume.appendingPathComponent("Library/Developer/CoreSimulator/Profiles/Runtimes")
            let entries = (try? manager.contentsOfDirectory(at: runtimes, includingPropertiesForKeys: nil)) ?? []
            for runtime in entries.sorted(by: { $0.path < $1.path }) where runtime.pathExtension == "simruntime" {
                let candidate = runtime.appendingPathComponent("Contents/Resources/RuntimeRoot/System/Library/Audio/UISounds/nano/TimerWheelMinutesDetent_Haptic.caf")
                if manager.fileExists(atPath: candidate.path) { return candidate }
            }
        }
        #endif
        return nil
    }
}
