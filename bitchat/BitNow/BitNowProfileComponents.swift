import Foundation
import SwiftUI

struct BitNowProfileFields: View {
    @EnvironmentObject private var peerListModel: PeerListModel
    @ObservedObject var store: BitNowEncounterStore

    var body: some View {
        Section("availability window") {
            if let until = store.availabilityUntil, store.profile.visibleNearby {
                HStack {
                    Label("visible until", systemImage: "timer")
                    Spacer()
                    Text(until.formatted(date: .omitted, time: .shortened))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } else {
                Text("not advertising encounter availability")
                    .foregroundStyle(.secondary)
            }

            ForEach(BitNowAvailabilityWindow.allCases) { window in
                Button {
                    store.startAvailability(for: window)
                    peerListModel.refreshLocalAdvertisement()
                } label: {
                    HStack {
                        Text("visible for \(window.title)")
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }

            Text("BitNow has no permanent-visible mode. When the window expires, encounter advertising and active signals stop automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section("profile") {
            Stepper("age: \(store.profile.age)", value: $store.profile.age, in: 18...99)
            Toggle("show age", isOn: $store.profile.showAge)

            Picker("I am", selection: $store.profile.identity) {
                Text("not set").tag(BitNowIdentity?.none)
                ForEach(BitNowIdentity.allCases) { identity in
                    Text(identity.title).tag(Optional(identity))
                }
            }

            TextField(
                "pronouns (optional)",
                text: Binding(
                    get: { store.profile.pronouns ?? "" },
                    set: { value in
                        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.profile.pronouns = trimmed.isEmpty
                            ? nil
                            : String(trimmed.prefix(BitNowSharedProfile.maxPronounsLength))
                    }
                )
            )

            TextField("headline", text: $store.profile.headline)
            TextField("about / boundaries / vibe", text: $store.profile.about, axis: .vertical)
                .lineLimit(3...7)
        }

        Section("open to meeting") {
            Text("Shared only in your encrypted BitNow profile.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(BitNowIdentity.allCases) { identity in
                Button {
                    toggleInterest(identity)
                } label: {
                    HStack {
                        Text(identity.title)
                        Spacer()
                        if store.profile.interestedInSet.contains(identity) {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }

            if !store.profile.interestedInSet.isEmpty {
                Button("clear preferences") {
                    store.profile.interestedIn = []
                }
            }
        }
    }

    private func toggleInterest(_ identity: BitNowIdentity) {
        var interests = store.profile.interestedInSet
        if interests.contains(identity) {
            interests.remove(identity)
        } else {
            interests.insert(identity)
        }
        store.profile.interestedIn = interests
    }
}

struct BitNowFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: BitNowEncounterStore

    var body: some View {
        Form {
            Section("age") {
                Stepper(
                    "minimum: \(store.discoveryFilter.minimumAge)",
                    value: minimumAgeBinding,
                    in: 18...99
                )
                Stepper(
                    "maximum: \(store.discoveryFilter.maximumAge)",
                    value: maximumAgeBinding,
                    in: 18...99
                )
                Text("Profiles that hide age remain visible only when your age filter is the full 18–99 range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("show me") {
                ForEach(BitNowIdentity.allCases) { identity in
                    Button {
                        toggleIdentity(identity)
                    } label: {
                        HStack {
                            Text(identity.title)
                            Spacer()
                            if store.discoveryFilter.identities.contains(identity) {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                Button("select all") {
                    store.discoveryFilter.identities = Set(BitNowIdentity.allCases)
                }
            }

            Section("intent") {
                ForEach(BitNowIntent.allCases) { intent in
                    Button {
                        toggleIntent(intent)
                    } label: {
                        HStack {
                            Label(intent.title, systemImage: intent.systemImage)
                            Spacer()
                            if store.discoveryFilter.intents.contains(intent) {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
                Button("select all") {
                    store.discoveryFilter.intents = Set(BitNowIntent.allCases)
                }
            }

            Section {
                Button("reset filters") {
                    store.discoveryFilter = BitNowDiscoveryFilter()
                }
            }
        }
        .navigationTitle("filters")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("done") { dismiss() }
            }
        }
    }

    private var minimumAgeBinding: Binding<Int> {
        Binding(
            get: { store.discoveryFilter.minimumAge },
            set: { newValue in
                store.discoveryFilter.minimumAge = min(newValue, store.discoveryFilter.maximumAge)
                store.discoveryFilter.normalize()
            }
        )
    }

    private var maximumAgeBinding: Binding<Int> {
        Binding(
            get: { store.discoveryFilter.maximumAge },
            set: { newValue in
                store.discoveryFilter.maximumAge = max(newValue, store.discoveryFilter.minimumAge)
                store.discoveryFilter.normalize()
            }
        )
    }

    private func toggleIdentity(_ identity: BitNowIdentity) {
        if store.discoveryFilter.identities.contains(identity) {
            store.discoveryFilter.identities.remove(identity)
        } else {
            store.discoveryFilter.identities.insert(identity)
        }
    }

    private func toggleIntent(_ intent: BitNowIntent) {
        if store.discoveryFilter.intents.contains(intent) {
            store.discoveryFilter.intents.remove(intent)
        } else {
            store.discoveryFilter.intents.insert(intent)
        }
    }
}
