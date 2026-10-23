import AppKit
import OSLog

/// Activation is asynchronous. Recheck after presentation and after activation,
/// but never let work queued for an old panel presentation take focus back.
@MainActor
final class HaloPanelFocusRecovery: NSObject {
    typealias Operation = @MainActor () -> Void
    typealias Scheduler = (@escaping Operation) -> Void
    #if DEBUG
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.tangfanx.popdeck", category: "PanelFocus")
    #endif

    static func record(_ phase: String, panel: NSPanel) {
        #if DEBUG
        logger.debug("Panel \(phase, privacy: .public): visible=\(panel.isVisible), key=\(panel.isKeyWindow), active=\(NSApp.isActive)")
        #endif
    }

    private let center: NotificationCenter
    private let schedule: Scheduler
    private var generation = 0
    private var queued = false
    private var isCurrent: (() -> Bool)?
    private var repair: Operation?

    init(center: NotificationCenter = .default, schedule: @escaping Scheduler = { operation in
        DispatchQueue.main.async { operation() }
    }) {
        self.center = center
        self.schedule = schedule
        super.init()
    }

    func begin(isCurrent: @escaping () -> Bool, repair: @escaping Operation) {
        cancel()
        self.isCurrent = isCurrent
        self.repair = repair
        center.addObserver(self, selector: #selector(applicationBecameActive),
                           name: NSApplication.didBecomeActiveNotification, object: nil)
        enqueueRepair()
    }

    func cancel() {
        generation += 1
        queued = false
        isCurrent = nil
        repair = nil
        center.removeObserver(self, name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func applicationBecameActive(_ notification: Notification) { enqueueRepair() }

    private func enqueueRepair() {
        guard repair != nil, !queued else { return }
        queued = true
        let ticket = generation
        schedule { [weak self] in
            guard let self, self.generation == ticket else { return }
            self.queued = false
            guard self.isCurrent?() == true else { self.cancel(); return }
            self.repair?()
        }
    }
}
