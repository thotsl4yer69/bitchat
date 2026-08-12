import BitFoundation
import Foundation

enum BitNowIntent: String, Codable, CaseIterable, Identifiable {
    case now
    case tonight
    case meetFirst
    case chatFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .now: return "right now"
        case .tonight: return "tonight"
        case .meetFirst: return "meet first"
        case .chatFirst: return "chat first"
        }
    }

    var systemImage: String {
        switch self {
        case .now: return "bolt.fill"
        case .tonight: return "moon.stars.fill"
        case .meetFirst: return "cup.and.saucer.fill"
        case .chatFirst: return "bubble.left.and.bubble.right.fill"
        }
    }
}

struct BitNowProfile: Codable, Equatable {
    var age: Int = 18
    var headline: String = ""
    var about: String = ""
    var primaryIntent: BitNowIntent = .now
    var visibleNearby: Bool = false
    var showAge: Bool = true

    var isAdult: Bool { (18...99).contains(age) }
}

struct BitNowSharedProfile: Codable, Equatable {
    static let maxHeadlineLength = 80
    static let maxAboutLength = 280

    let age: Int?
    let headline: String
    let about: String
    let primaryIntent: BitNowIntent

    init(profile: BitNowProfile) {
        age = profile.showAge && profile.isAdult ? profile.age : nil
        headline = String(profile.headline.prefix(Self.maxHeadlineLength))
        about = String(profile.about.prefix(Self.maxAboutLength))
        primaryIntent = profile.primaryIntent
    }

    var ageLabel: String {
        age.map { String($0) } ?? "18+"
    }

    var isValid: Bool {
        let ageIsValid = age.map { (18...99).contains($0) } ?? true
        return ageIsValid
            && headline.count <= Self.maxHeadlineLength
            && about.count <= Self.maxAboutLength
    }
}

struct BitNowOutgoingSignal: Codable, Equatable, Identifiable {
    let peerID: String
    let intent: BitNowIntent
    let sentAt: Date

    var id: String { peerID }
}

struct BitNowIncomingSignal: Equatable, Identifiable {
    let peerID: PeerID
    let intent: BitNowIntent
    let receivedAt: Date
    let profile: BitNowSharedProfile?

    var id: String { peerID.id }
}

enum BitNowWireKind: String, Codable {
    case signal
    case profileRequest
    case profile
}

struct BitNowWireEnvelope: Codable, Equatable {
    static let currentVersion = 1

    let version: Int
    let kind: BitNowWireKind
    let intent: BitNowIntent?
    let profile: BitNowSharedProfile?
    let sentAt: Date

    init(
        kind: BitNowWireKind,
        intent: BitNowIntent? = nil,
        profile: BitNowSharedProfile? = nil,
        sentAt: Date = Date()
    ) {
        self.version = Self.currentVersion
        self.kind = kind
        self.intent = intent
        self.profile = profile
        self.sentAt = sentAt
    }

    var isValid: Bool {
        guard version == Self.currentVersion,
              profile?.isValid != false else { return false }

        switch kind {
        case .signal:
            return intent != nil
        case .profileRequest:
            return intent == nil && profile == nil
        case .profile:
            return intent == nil && profile != nil
        }
    }
}

enum BitNowWireCodec {
    private static let separator = "\u{2063}"
    private static let legacySignalPrefix = "⚡ BitNow • signal • "
    private static let maxEncodedPayloadLength = 8_192

    static func encodeSignal(_ intent: BitNowIntent, profile: BitNowProfile? = nil) -> String {
        let envelope = BitNowWireEnvelope(
            kind: .signal,
            intent: intent,
            profile: profile.map { BitNowSharedProfile(profile: $0) }
        )
        return encode(envelope, visibleText: "⚡ BitNow signal — \(intent.title)")
    }

    static func encodeProfileRequest() -> String {
        encode(BitNowWireEnvelope(kind: .profileRequest), visibleText: "⚡ BitNow profile request")
    }

    static func encodeProfile(_ profile: BitNowProfile) -> String {
        encode(
            BitNowWireEnvelope(kind: .profile, profile: BitNowSharedProfile(profile: profile)),
            visibleText: "⚡ BitNow profile shared"
        )
    }

    static func decode(_ content: String) -> BitNowWireEnvelope? {
        if let separatorRange = content.range(of: separator) {
            let payload = String(content[separatorRange.upperBound...])
            guard !payload.isEmpty,
                  payload.count <= maxEncodedPayloadLength,
                  let data = Data(base64Encoded: payload),
                  let envelope = try? JSONDecoder().decode(BitNowWireEnvelope.self, from: data),
                  envelope.isValid else {
                return nil
            }
            return envelope
        }

        if content.hasPrefix(legacySignalPrefix) {
            let raw = String(content.dropFirst(legacySignalPrefix.count))
            guard let intent = BitNowIntent(rawValue: raw) else { return nil }
            return BitNowWireEnvelope(kind: .signal, intent: intent)
        }

        return nil
    }

    private static func encode(_ envelope: BitNowWireEnvelope, visibleText: String) -> String {
        guard envelope.isValid,
              let data = try? JSONEncoder().encode(envelope) else { return visibleText }
        return visibleText + separator + data.base64EncodedString()
    }
}

enum BitNowSignalCodec {
    static func encode(_ intent: BitNowIntent) -> String {
        BitNowWireCodec.encodeSignal(intent)
    }

    static func encode(_ intent: BitNowIntent, profile: BitNowProfile) -> String {
        BitNowWireCodec.encodeSignal(intent, profile: profile)
    }

    static func decode(_ content: String) -> BitNowIntent? {
        guard let envelope = BitNowWireCodec.decode(content), envelope.kind == .signal else { return nil }
        return envelope.intent
    }
}
