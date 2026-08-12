import Foundation
import Testing
@testable import BitFoundation
@testable import bitchat

struct BitNowSignalTests {
    @Test func signalCodecRoundTripsEveryIntent() {
        for intent in BitNowIntent.allCases {
            let encoded = BitNowSignalCodec.encode(intent)
            #expect(BitNowSignalCodec.decode(encoded) == intent)
        }
    }

    @Test func signalCarriesSharedProfileSnapshot() throws {
        var profile = BitNowProfile(
            age: 27,
            headline: "nearby tonight",
            about: "chat first",
            primaryIntent: .tonight,
            visibleNearby: true,
            showAge: true
        )
        profile.identity = .woman
        profile.interestedIn = [.man, .woman]
        profile.pronouns = "she/her"

        let encoded = BitNowSignalCodec.encode(.now, profile: profile)
        let envelope = try #require(BitNowWireCodec.decode(encoded))
        #expect(envelope.kind == .signal)
        #expect(envelope.intent == .now)
        #expect(envelope.profile?.age == 27)
        #expect(envelope.profile?.headline == "nearby tonight")
        #expect(envelope.profile?.identity == .woman)
        #expect(envelope.profile?.interestedIn == [.man, .woman])
        #expect(envelope.profile?.pronouns == "she/her")
    }

    @Test func profileRequestRoundTrips() throws {
        let envelope = try #require(BitNowWireCodec.decode(BitNowWireCodec.encodeProfileRequest()))
        #expect(envelope.kind == .profileRequest)
        #expect(envelope.profile == nil)
    }

    @Test func hiddenAgeStaysHiddenInSharedProfile() throws {
        var profile = BitNowProfile()
        profile.age = 31
        profile.showAge = false

        let envelope = try #require(BitNowWireCodec.decode(BitNowWireCodec.encodeProfile(profile)))
        #expect(envelope.kind == .profile)
        #expect(envelope.profile?.age == nil)
        #expect(envelope.profile?.ageLabel == "18+")
    }

    @Test func ordinaryChatIsNotTreatedAsSignal() {
        #expect(BitNowSignalCodec.decode("hey, are you around?") == nil)
        #expect(BitNowSignalCodec.decode("⚡ BitNow") == nil)
    }

    @Test func profileRequiresAdultAgeAndDefaultsInvisible() {
        var profile = BitNowProfile()
        #expect(!profile.visibleNearby)

        profile.age = 18
        #expect(profile.isAdult)

        profile.age = 17
        #expect(!profile.isAdult)
    }

    @Test func profilePersistenceRoundTrips() throws {
        var profile = BitNowProfile(
            age: 27,
            headline: "nearby tonight",
            about: "chat first",
            primaryIntent: .tonight,
            visibleNearby: true,
            showAge: false
        )
        profile.identity = .nonBinary
        profile.interestedIn = [.woman, .nonBinary]
        profile.pronouns = "they/them"

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(BitNowProfile.self, from: data)
        #expect(decoded == profile)
    }

    @Test func oldV1ProfileWithoutIdentityFieldsStillDecodes() throws {
        let json = Data("""
        {
          "age": 29,
          "headline": "hello",
          "about": "nearby",
          "primaryIntent": "now",
          "visibleNearby": true,
          "showAge": true
        }
        """.utf8)

        let profile = try JSONDecoder().decode(BitNowProfile.self, from: json)
        #expect(profile.age == 29)
        #expect(profile.identity == nil)
        #expect(profile.interestedIn == nil)
        #expect(profile.pronouns == nil)
    }

    @Test func discoveryFilterRespectsKnownAgeIdentityAndIntent() {
        var local = BitNowProfile()
        local.identity = .man

        var remote = BitNowProfile()
        remote.age = 30
        remote.showAge = true
        remote.identity = .woman
        remote.primaryIntent = .tonight
        remote.interestedIn = [.man]
        let shared = BitNowSharedProfile(profile: remote)

        var filter = BitNowDiscoveryFilter()
        filter.minimumAge = 25
        filter.maximumAge = 35
        filter.identities = [.woman]
        filter.intents = [.tonight]

        #expect(filter.matches(shared))
        #expect(shared.appearsInterestedIn(local.identity))

        filter.intents = [.chatFirst]
        #expect(!filter.matches(shared))
    }

    @Test func restrictiveAgeFilterDoesNotInferHiddenAge() {
        var remote = BitNowProfile()
        remote.age = 30
        remote.showAge = false
        let shared = BitNowSharedProfile(profile: remote)

        var filter = BitNowDiscoveryFilter()
        #expect(filter.matches(shared))

        filter.minimumAge = 25
        #expect(!filter.matches(shared))
    }

    @MainActor
    @Test func encounterStorePersistsRadioVisibilityGate() {
        let suiteName = "BitNowSignalTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = BitNowEncounterStore(defaults: defaults)
        #expect(defaults.bool(forKey: BitNowEncounterStore.advertiseVisibilityKey) == false)

        store.profile.visibleNearby = true
        #expect(store.availabilityUntil != nil)
        #expect(defaults.bool(forKey: BitNowEncounterStore.advertiseVisibilityKey))

        store.profile.visibleNearby = false
        #expect(defaults.bool(forKey: BitNowEncounterStore.advertiseVisibilityKey) == false)
    }

    @MainActor
    @Test func availabilityWindowExpiresAndClearsSignals() {
        let suiteName = "BitNowSignalTests.expiry.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = BitNowEncounterStore(defaults: defaults)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        store.startAvailability(for: .thirtyMinutes, now: now)
        #expect(store.profile.visibleNearby)
        #expect(store.availabilityUntil == now.addingTimeInterval(30 * 60))

        let peer = PeerID(str: "0011223344556677")
        store.recordOutgoingSignal(to: peer, intent: .now, now: now)
        #expect(!store.outgoingSignals.isEmpty)

        let expired = store.expireAvailabilityIfNeeded(now: now.addingTimeInterval(30 * 60 + 1))
        #expect(expired)
        #expect(!store.profile.visibleNearby)
        #expect(store.availabilityUntil == nil)
        #expect(store.outgoingSignals.isEmpty)
        #expect(defaults.bool(forKey: BitNowEncounterStore.advertiseVisibilityKey) == false)
    }

    @MainActor
    @Test func clearingLocalEncounterDataRestoresPrivateDefaults() {
        let suiteName = "BitNowSignalTests.clear.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = BitNowEncounterStore(defaults: defaults)
        store.profile.age = 29
        store.profile.headline = "private headline"
        store.profile.about = "private preferences"
        store.profile.identity = .woman
        store.profile.interestedIn = [.man]
        store.startAvailability(for: .oneHour)
        store.recordOutgoingSignal(
            to: PeerID(str: "0011223344556677"),
            intent: .now
        )

        store.clearLocalEncounterData()

        #expect(store.profile == BitNowProfile())
        #expect(store.discoveryFilter == BitNowDiscoveryFilter())
        #expect(store.availabilityUntil == nil)
        #expect(store.outgoingSignals.isEmpty)
        #expect(defaults.bool(forKey: BitNowEncounterStore.advertiseVisibilityKey) == false)
    }
}
