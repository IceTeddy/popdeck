import Darwin
import Foundation

final class SingleInstanceGuard {
    private var lockFileDescriptor: Int32 = -1

    func acquire() -> Bool {
        // Keep the production lock compatible with installed releases, while
        // allowing independently identified test bundles to run in isolation.
        let bundleID = Bundle.main.bundleIdentifier ?? "com.tangfanx.popdeck"
        let lockName = bundleID == "com.tangfanx.popdeck" ? "PopDeck.lock" : "\(bundleID).lock"
        let path = NSTemporaryDirectory().appending(lockName)
        lockFileDescriptor = open(path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard lockFileDescriptor >= 0 else { return true }

        if flock(lockFileDescriptor, LOCK_EX | LOCK_NB) == 0 {
            return true
        }

        close(lockFileDescriptor)
        lockFileDescriptor = -1
        return false
    }

    deinit {
        if lockFileDescriptor >= 0 {
            flock(lockFileDescriptor, LOCK_UN)
            close(lockFileDescriptor)
        }
    }
}
