import BitFoundation
import Foundation

extension PeerCapabilities {
    private static let bitNowRadioVisibilityKey = "bitnow.radio-visible.v1"

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

        if UserDefaults.standard.bool(forKey: bitNowRadioVisibilityKey) {
            capabilities.insert(.bitNow)
        }
        return capabilities
    }
}
