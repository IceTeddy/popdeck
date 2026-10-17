import AVFoundation
import Foundation

struct HoverSoundGate {
    private(set) var currentID: String?
    private var lastTick = -Double.infinity
    mutating func enter(_ id: String?, at time: TimeInterval, enabled: Bool) -> Bool {
        guard currentID != id else { return false }
        currentID = id
        guard enabled, id != nil, time - lastTick >= 0.045 else { return false }
        lastTick = time
        return true
    }
    mutating func reset() { currentID = nil; lastTick = -Double.infinity }
}

enum HoverSoundStyle: String, CaseIterable, Identifiable {
    case ratchet, soft, wood, bright, picker
    var id: String { rawValue }
    static let preferenceKey = "hoverSoundStyle"
    var assetName: String { self == .ratchet ? "hover-tick" : "hover-" + rawValue }
    var title: String { L10n.t("settings.sound." + rawValue) }
    static var availableStyles: [Self] { allCases.filter { $0 != .picker || LocalPickerSound.url != nil } }
    static func selected(in defaults: UserDefaults = .standard) -> Self {
        let style = Self(rawValue: defaults.string(forKey: preferenceKey) ?? "") ?? .ratchet
        return style == .picker && LocalPickerSound.url == nil ? .ratchet : style
    }
}

@MainActor
final class HoverSoundPlayer {
    static let shared = HoverSoundPlayer()
    static var assetURL: URL? { assetURL(for: .ratchet) }
    static func assetURL(for style: HoverSoundStyle) -> URL? {
        if style == .picker { return LocalPickerSound.url }
        return Bundle.main.url(forResource: style.assetName, withExtension: "wav")
            ?? Bundle.module.url(forResource: style.assetName, withExtension: "wav")
    }
    private var gate = HoverSoundGate()
    private var players: [HoverSoundStyle: AVAudioPlayer] = [:]
    private init() {
        for style in HoverSoundStyle.availableStyles {
            if let url = Self.assetURL(for: style), let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = style == .picker ? 0.65 : 0.22
                player.prepareToPlay()
                players[style] = player
            }
        }
    }
    func hover(_ id: String?) {
        let defaults = UserDefaults.standard
        let enabled = defaults.object(forKey: AppPreferences.hoverSoundKey) == nil || defaults.bool(forKey: AppPreferences.hoverSoundKey)
        if gate.enter(id, at: ProcessInfo.processInfo.systemUptime, enabled: enabled) { play() }
    }
    func leave(_ id: String) { if gate.currentID == id { hover(nil) } }
    func reset() { gate.reset() }
    func stop() { players.values.forEach { $0.stop() }; gate.reset() }
    func preview() { play() }
    private func play() {
        let player = players[HoverSoundStyle.selected()]
        players.values.forEach { $0.stop() }
        player?.currentTime = 0
        player?.play()
    }
}
