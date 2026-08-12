import BitFoundation
import Combine
import Foundation

@MainActor
final class BitNowEncounterStore: ObservableObject {
    static let signalLifetime: TimeInterval = 45 * 60
    static let advertiseVisibilityKey = "bitnow.radio-visible.v1"
    static let availabilityUntilKey = "bitnow.availability-until.v1"

    @Published var profile: BitNowProfile {
        didSet {
            syncAvailabilityWithProfile()
            persistProfile()
            persistRadioVisibility()
        }
    }

    @Published var discoveryFilter: BitNowDiscoveryFilter {
        didSet { persistDiscoveryFilter() }
    }

    @Published private(set) var availabilityUntil: Date? {
        didSet {
            persistAvailabilityUntil()
            persistRadioVisibility()
            scheduleAvailabilityExpiration()
        }
    }

    @Published private(set) var outgoingSignals: [String: BitNowOutgoingSignal] = [:] {
        didSet { persistSignals() }
    }

    private var handledProfileRequestIDs = Set<String>()
    private var expirationTask: Task<Void, Never>?
    private let defaults: UserDefaults
    private let profileKey = "bitnow.profile.v1"
    private let filterKey = "bitnow.discovery-filter.v1"
    private let signalsKey = "bitnow.outgoing-signals.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        var loadedProfile: BitNowProfile
        if let data = defaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(BitNowProfile.self, from: data) {
            loadedProfile = decoded
        } else {
            loadedProfile = BitNowProfile()
        }

        let storedAvailability = defaults.object(forKey: Self.availabilityUntilKey) as? Date
        if loadedProfile.visibleNearby,
           loadedProfile.isAdult,
           let storedAvailability,
           storedAvailability > Date() {
            availabilityUntil = storedAvailability
        } else {
            loadedProfile.visibleNearby = false
            availabilityUntil = nil
        }
        profile = loadedProfile

        if let data = defaults.data(forKey: filterKey),
           var decoded = try? JSONDecoder().decode(BitNowDiscoveryFilter.self, from: data) {
            decoded.normalize()
            discoveryFilter = decoded
        } else {
            discoveryFilter = BitNowDiscoveryFilter()
        }

        if let data = defaults.data(forKey: signalsKey),
           let decoded = try? JSONDecoder().decode([String: BitNowOutgoingSignal].self, from: data) {
            outgoingSignals = decoded
        }

        persistProfile()
        persistAvailabilityUntil()
        persistRadioVisibility()
        pruneExpiredSignals()
        scheduleAvailabilityExpiration()
    }

    deinit {
        expirationTask?.cancel()
    }

    func startAvailability(
        for window: BitNowAvailabilityWindow = .oneHour,
        now: Date = Date()
    ) {
        availabilityUntil = now.addingTimeInterval(window.duration)
        profile.visibleNearby = true
        persistRadioVisibility()
    }

    func stopAvailability(clearSignals: Bool = true) {
        if profile.visibleNearby {
            profile.visibleNearby = false
        }
        if availabilityUntil != nil {
            availabilityUntil = nil
        }
        if clearSignals {
            clearAllSignals()
        }
        persistRadioVisibility()
    }

    /// Returns true when an active availability window expired and state was
    /// changed. The radio capability independently checks the deadline too, so
    /// suspension cannot extend encounter visibility.
    @discardableResult
    func expireAvailabilityIfNeeded(now: Date = Date()) -> Bool {
        guard profile.visibleNearby else { return false }
        guard let availabilityUntil, availabilityUntil > now else {
            stopAvailability(clearSignals: true)
            return true
        }
        return false
    }

    func recordOutgoingSignal(to peerID: PeerID, intent: BitNowIntent, now: Date = Date()) {
        outgoingSignals[peerID.id] = BitNowOutgoingSignal(
            peerID: peerID.id,
            intent: intent,
            sentAt: now
        )
        pruneExpiredSignals(now: now)
    }

    func outgoingSignal(to peerID: PeerID, now: Date = Date()) -> BitNowOutgoingSignal? {
        guard let signal = outgoingSignals[peerID.id],
              now.timeIntervalSince(signal.sentAt) <= Self.signalLifetime else {
            return nil
        }
        return signal
    }

    func latestIncomingSignal(
        from peerID: PeerID,
        inbox: PrivateInboxModel,
        now: Date = Date()
    ) -> BitNowIncomingSignal? {
        for message in inbox.messages(for: peerID).reversed() {
            guard message.senderPeerID == peerID,
                  now.timeIntervalSince(message.timestamp) <= Self.signalLifetime,
                  let envelope = BitNowWireCodec.decode(message.content),
                  envelope.kind == .signal,
                  let intent = envelope.intent else {
                continue
            }
            return BitNowIncomingSignal(
                peerID: peerID,
                intent: intent,
                receivedAt: message.timestamp,
                profile: envelope.profile
            )
        }
        return nil
    }

    func latestSharedProfile(from peerID: PeerID, inbox: PrivateInboxModel) -> BitNowSharedProfile? {
        for message in inbox.messages(for: peerID).reversed() {
            guard message.senderPeerID == peerID,
                  let envelope = BitNowWireCodec.decode(message.content) else {
                continue
            }
            if let profile = envelope.profile,
               envelope.kind == .profile || envelope.kind == .signal {
                return profile
            }
        }
        return nil
    }

    func discoveryAllows(_ profile: BitNowSharedProfile) -> Bool {
        discoveryFilter.matches(profile)
    }

    func isMatch(with peerID: PeerID, inbox: PrivateInboxModel, now: Date = Date()) -> Bool {
        outgoingSignal(to: peerID, now: now) != nil
            && latestIncomingSignal(from: peerID, inbox: inbox, now: now) != nil
    }

    /// Returns true exactly once for a profile-request message ID in this app
    /// session. This prevents duplicate automatic responses on SwiftUI refreshes.
    func claimProfileRequest(messageID: String) -> Bool {
        handledProfileRequestIDs.insert(messageID).inserted
    }

    func clearSignal(for peerID: PeerID) {
        outgoingSignals.removeValue(forKey: peerID.id)
    }

    func clearSignal(peerIDString: String) {
        outgoingSignals.removeValue(forKey: peerIDString)
    }

    func clearAllSignals() {
        outgoingSignals.removeAll()
    }

    func clearLocalEncounterData() {
        stopAvailability(clearSignals: true)
        profile = BitNowProfile()
        discoveryFilter = BitNowDiscoveryFilter()
        handledProfileRequestIDs.removeAll()
    }

    func pruneExpiredSignals(now: Date = Date()) {
        outgoingSignals = outgoingSignals.filter {
            now.timeIntervalSince($0.value.sentAt) <= Self.signalLifetime
        }
    }

    private func syncAvailabilityWithProfile(now: Date = Date()) {
        if profile.visibleNearby && profile.isAdult {
            if availabilityUntil == nil || (availabilityUntil ?? .distantPast) <= now {
                availabilityUntil = now.addingTimeInterval(BitNowAvailabilityWindow.oneHour.duration)
            }
        } else if availabilityUntil != nil {
            availabilityUntil = nil
        }
    }

    private func scheduleAvailabilityExpiration() {
        expirationTask?.cancel()
        expirationTask = nil

        guard profile.visibleNearby,
              let availabilityUntil else { return }
        let delay = availabilityUntil.timeIntervalSinceNow
        guard delay > 0 else {
            _ = expireAvailabilityIfNeeded()
            return
        }

        let nanoseconds = UInt64(min(delay, 24 * 60 * 60) * 1_000_000_000)
        expirationTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            _ = self?.expireAvailabilityIfNeeded()
        }
    }

    private func persistProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }

    private func persistDiscoveryFilter() {
        guard let data = try? JSONEncoder().encode(discoveryFilter) else { return }
        defaults.set(data, forKey: filterKey)
    }

    private func persistAvailabilityUntil() {
        if let availabilityUntil {
            defaults.set(availabilityUntil, forKey: Self.availabilityUntilKey)
        } else {
            defaults.removeObject(forKey: Self.availabilityUntilKey)
        }
    }

    private func persistRadioVisibility() {
        let active = profile.visibleNearby
            && profile.isAdult
            && (availabilityUntil?.timeIntervalSinceNow ?? -1) > 0
        defaults.set(active, forKey: Self.advertiseVisibilityKey)
    }

    private func persistSignals() {
        guard let data = try? JSONEncoder().encode(outgoingSignals) else { return }
        defaults.set(data, forKey: signalsKey)
    }
}
