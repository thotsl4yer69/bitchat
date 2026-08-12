import Foundation
import Testing
@testable import bitchat

struct BitNowSignalTests {
    @Test func signalCodecRoundTripsEveryIntent() {
        for intent in BitNowIntent.allCases {
            let encoded = BitNowSignalCodec.encode(intent)
            #expect(BitNowSignalCodec.decode(encoded) == intent)
        }
    }

    @Test func signalCarriesSharedProfileSnapshot() throws {
        let profile = BitNowProfile(
            age: 27,
            headline: "nearby tonight",
            about: "chat first",
            primaryIntent: .tonight,
            visibleNearby: true,
            showAge: true
        )

        let encoded = BitNowSignalCodec.encode(.now, profile: profile)
        let envelope = try #require(BitNowWireCodec.decode(encoded))
        #expect(envelope.kind == .signal)
        #expect(envelope.intent == .now)
        #expect(envelope.profile?.age == 27)
        #expect(envelope.profile?.headline == "nearby tonight")
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

    @Test func profileRequiresAdultAge() {
        var profile = BitNowProfile()
        profile.age = 18
        #expect(profile.isAdult)

        profile.age = 17
        #expect(!profile.isAdult)
    }

    @Test func profilePersistenceRoundTrips() throws {
        let profile = BitNowProfile(
            age: 27,
            headline: "nearby tonight",
            about: "chat first",
            primaryIntent: .tonight,
            visibleNearby: true,
            showAge: false
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(BitNowProfile.self, from: data)
        #expect(decoded == profile)
    }
}
