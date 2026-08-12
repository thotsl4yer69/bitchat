import BitFoundation
import Foundation

extension PeerCapabilities {
    private static let bitNowRadioVisibilityKey = "bitnow.radio-visible.v1"
    private static let bitNowAvailabilityUntilKey = "bitnow.availability-until.v1"

    /// Capabilities this build advertises in its announce packets.
    /// BitNow is intentionally dynamic: supporting the app is not itself
    /// permission to advertise encounter availability to nearby radios.
    /// The time check is repeated here so an expired app cannot keep
    /// advertising BitNow merely because it was suspended before its timer ran.
    static var localSupported: PeerCapabilities {
        var capabilities: PeerCapabilities = [
            .vouch,
            .prekeys,
            .groups,
            .privateMedia,
            .privateMediaReceipts
        ]

        let defaults = UserDefaults.standard
        let radioVisible = defaults.bool(forKey: bitNowRadioVisibilityKey)
        let availabilityUntil = defaults.object(forKey: bitNowAvailabilityUntilKey) as? Date
        if radioVisible, let availabilityUntil, availabilityUntil > Date() {
            capabilities.insert(.bitNow)
        }
        return capabilities
    }
}
