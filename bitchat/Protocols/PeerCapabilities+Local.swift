import BitFoundation
import Foundation

extension PeerCapabilities {
    /// Capabilities this build advertises in its announce packets.
    /// BitNow is intentionally dynamic: supporting the app is not itself
    /// permission to advertise encounter availability to nearby radios.
    static var localSupported: PeerCapabilities {
        var capabilities: PeerCapabilities = [
            .vouch,
            .prekeys,
            .groups,
            .privateMedia,
            .privateMediaReceipts
        ]

        if UserDefaults.standard.bool(forKey: BitNowEncounterStore.advertiseVisibilityKey) {
            capabilities.insert(.bitNow)
        }
        return capabilities
    }
}
