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
