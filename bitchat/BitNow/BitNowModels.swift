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
    var visibleNearby: Bool = true
    var showAge: Bool = true

    var isAdult: Bool { age >= 18 }
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

    var id: String { peerID.id }
}

enum BitNowSignalCodec {
    static let prefix = "⚡ BitNow • signal • "

    static func encode(_ intent: BitNowIntent) -> String {
        prefix + intent.rawValue
    }

    static func decode(_ content: String) -> BitNowIntent? {
        guard content.hasPrefix(prefix) else { return nil }
        let value = String(content.dropFirst(prefix.count))
        return BitNowIntent(rawValue: value)
    }
}
