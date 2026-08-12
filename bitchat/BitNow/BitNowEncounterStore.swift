import BitFoundation
import Combine
import Foundation

@MainActor
final class BitNowEncounterStore: ObservableObject {
    static let signalLifetime: TimeInterval = 45 * 60

    @Published var profile: BitNowProfile {
        didSet { persistProfile() }
    }

    @Published private(set) var outgoingSignals: [String: BitNowOutgoingSignal] = [:] {
        didSet { persistSignals() }
    }

    private let defaults: UserDefaults
    private let profileKey = "bitnow.profile.v1"
    private let signalsKey = "bitnow.outgoing-signals.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(BitNowProfile.self, from: data) {
            profile = decoded
        } else {
            profile = BitNowProfile()
        }

        if let data = defaults.data(forKey: signalsKey),
           let decoded = try? JSONDecoder().decode([String: BitNowOutgoingSignal].self, from: data) {
            outgoingSignals = decoded
        }

        pruneExpiredSignals()
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
                  let intent = BitNowSignalCodec.decode(message.content) else {
                continue
            }
            return BitNowIncomingSignal(
                peerID: peerID,
                intent: intent,
                receivedAt: message.timestamp
            )
        }
        return nil
    }

    func isMatch(with peerID: PeerID, inbox: PrivateInboxModel, now: Date = Date()) -> Bool {
        outgoingSignal(to: peerID, now: now) != nil
            && latestIncomingSignal(from: peerID, inbox: inbox, now: now) != nil
    }

    func clearSignal(for peerID: PeerID) {
        outgoingSignals.removeValue(forKey: peerID.id)
    }

    func clearAllSignals() {
        outgoingSignals.removeAll()
    }

    func pruneExpiredSignals(now: Date = Date()) {
        outgoingSignals = outgoingSignals.filter {
            now.timeIntervalSince($0.value.sentAt) <= Self.signalLifetime
        }
    }

    private func persistProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
    }

    private func persistSignals() {
        guard let data = try? JSONEncoder().encode(outgoingSignals) else { return }
        defaults.set(data, forKey: signalsKey)
    }
}
