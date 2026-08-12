import BitFoundation
import SwiftUI

private enum BitNowTab: Hashable {
    case nearby
    case signals
    case chats
    case me
}

struct BitNowRootView: View {
    @AppStorage("bitnow.onboarding.complete") private var onboardingComplete = false
    @StateObject private var encounterStore = BitNowEncounterStore()

    var body: some View {
        Group {
            if onboardingComplete {
                BitNowMainView(store: encounterStore)
            } else {
                BitNowOnboardingView(
                    store: encounterStore,
                    onboardingComplete: $onboardingComplete
                )
            }
        }
    }
}

private struct BitNowMainView: View {
    @ObservedObject var store: BitNowEncounterStore
    @State private var selectedTab: BitNowTab = .nearby

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                BitNowNearbyView(store: store, selectedTab: $selectedTab)
            }
            .tabItem { Label("nearby", systemImage: "dot.radiowaves.left.and.right") }
            .tag(BitNowTab.nearby)

            NavigationStack {
                BitNowSignalsView(store: store, selectedTab: $selectedTab)
            }
            .tabItem { Label("signals", systemImage: "bolt.heart.fill") }
            .tag(BitNowTab.signals)

            ContentView()
                .tabItem { Label("chats", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(BitNowTab.chats)

            NavigationStack {
                BitNowProfileView(store: store)
            }
            .tabItem { Label("me", systemImage: "person.crop.circle.fill") }
            .tag(BitNowTab.me)
        }
    }
}

private struct BitNowOnboardingView: View {
    @ObservedObject var store: BitNowEncounterStore
    @Binding var onboardingComplete: Bool

    @State private var age = 18
    @State private var confirmedAdult = false
    @State private var acceptedConsentRule = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BITNOW")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                        Text("who's actually here, right now")
                            .font(.title3.weight(.semibold))
                        Text("Adults-only proximity encounters over the BitChat mesh. No public exact-location pin and no account required for local discovery.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Label("18+ only", systemImage: "18.circle.fill")
                            .font(.headline)

                        Stepper("age: \(age)", value: $age, in: 18...99)

                        Toggle("I confirm I am 18 or older", isOn: $confirmedAdult)
                        Toggle("I understand a signal is interest, not consent to anything else", isOn: $acceptedConsentRule)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

                    VStack(alignment: .leading, spacing: 12) {
                        Label("proximity without a map pin", systemImage: "location.slash.fill")
                        Label("encrypted direct chat", systemImage: "lock.fill")
                        Label("signals expire automatically", systemImage: "timer")
                        Label("block and disappear at any time", systemImage: "hand.raised.fill")
                    }
                    .font(.subheadline)

                    Button {
                        store.profile.age = age
                        store.profile.visibleNearby = true
                        onboardingComplete = true
                    } label: {
                        Text("enter bitnow")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!confirmedAdult || !acceptedConsentRule)
                }
                .padding(24)
                .frame(maxWidth: 640)
            }
        }
    }
}

private struct BitNowNearbyView: View {
    @EnvironmentObject private var peerListModel: PeerListModel
    @EnvironmentObject private var privateConversationModel: PrivateConversationModel
    @EnvironmentObject private var conversationUIModel: ConversationUIModel

    @ObservedObject var store: BitNowEncounterStore
    @Binding var selectedTab: BitNowTab

    private var nearbyRows: [MeshPeerRow] {
        guard store.profile.visibleNearby else { return [] }
        return peerListModel.meshRows
            .filter { !$0.isMe && !$0.isBlocked && ($0.isConnected || $0.isReachable) }
            .sorted {
                if $0.isConnected != $1.isConnected { return $0.isConnected }
                return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    var body: some View {
        Group {
            if !store.profile.visibleNearby {
                ContentUnavailableView(
                    "you are invisible",
                    systemImage: "eye.slash.fill",
                    description: Text("Turn nearby visibility back on from Me when you want to appear in the local encounter layer.")
                )
            } else if nearbyRows.isEmpty {
                ContentUnavailableView(
                    "nobody nearby yet",
                    systemImage: "dot.radiowaves.left.and.right",
                    description: Text("BitNow uses the local Bluetooth mesh. Nearby compatible peers appear here without publishing an exact map location.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(nearbyRows) { row in
                            BitNowNearbyCard(
                                row: row,
                                store: store,
                                onSignal: { intent in sendSignal(to: row, intent: intent) },
                                onChat: { openChat(with: row.peerID) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("nearby now")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text("\(nearbyRows.count) here")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sendSignal(to row: MeshPeerRow, intent: BitNowIntent) {
        privateConversationModel.startConversation(with: row.peerID)
        conversationUIModel.sendMessage(BitNowSignalCodec.encode(intent))
        store.recordOutgoingSignal(to: row.peerID, intent: intent)
        privateConversationModel.endConversation()
    }

    private func openChat(with peerID: PeerID) {
        privateConversationModel.startConversation(with: peerID)
        selectedTab = .chats
    }
}

private struct BitNowNearbyCard: View {
    let row: MeshPeerRow
    @ObservedObject var store: BitNowEncounterStore
    let onSignal: (BitNowIntent) -> Void
    let onChat: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.displayName)
                        .font(.title3.weight(.bold))
                    Text(row.isConnected ? "HERE NOW" : "NEARBY RECENTLY")
                        .font(.caption.weight(.black))
                        .foregroundStyle(row.isConnected ? .primary : .secondary)
                }
                Spacer()
                if row.isMutualFavorite {
                    Image(systemName: "checkmark.seal.fill")
                        .accessibilityLabel("mutual trusted contact")
                }
            }

            HStack(spacing: 10) {
                Menu {
                    ForEach(BitNowIntent.allCases) { intent in
                        Button {
                            onSignal(intent)
                        } label: {
                            Label(intent.title, systemImage: intent.systemImage)
                        }
                    }
                } label: {
                    Label(
                        store.outgoingSignal(to: row.peerID) == nil ? "signal" : "signalled",
                        systemImage: "bolt.heart.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onChat) {
                    Label("chat", systemImage: "bubble.left.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct BitNowSignalPerson: Identifiable {
    let row: MeshPeerRow
    let incoming: BitNowIncomingSignal
    let isMatch: Bool

    var id: String { row.id }
}

private struct BitNowSignalsView: View {
    @EnvironmentObject private var peerListModel: PeerListModel
    @EnvironmentObject private var privateInboxModel: PrivateInboxModel
    @EnvironmentObject private var privateConversationModel: PrivateConversationModel

    @ObservedObject var store: BitNowEncounterStore
    @Binding var selectedTab: BitNowTab

    private var incoming: [BitNowSignalPerson] {
        peerListModel.meshRows.compactMap { row in
            guard !row.isMe, !row.isBlocked,
                  let signal = store.latestIncomingSignal(from: row.peerID, inbox: privateInboxModel) else {
                return nil
            }
            return BitNowSignalPerson(
                row: row,
                incoming: signal,
                isMatch: store.isMatch(with: row.peerID, inbox: privateInboxModel)
            )
        }
        .sorted { lhs, rhs in
            if lhs.isMatch != rhs.isMatch { return lhs.isMatch }
            return lhs.incoming.receivedAt > rhs.incoming.receivedAt
        }
    }

    var body: some View {
        List {
            if incoming.isEmpty {
                Section {
                    Text("No fresh incoming signals. Signals expire after 45 minutes.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("incoming") {
                    ForEach(incoming) { item in
                        Button {
                            privateConversationModel.startConversation(with: item.row.peerID)
                            selectedTab = .chats
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.isMatch ? "heart.fill" : "bolt.fill")
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.row.displayName)
                                        .font(.headline)
                                    Text(item.isMatch ? "MATCH • \(item.incoming.intent.title)" : "interested • \(item.incoming.intent.title)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }

            Section("your active signals") {
                if store.outgoingSignals.isEmpty {
                    Text("Nothing active.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.outgoingSignals.values.sorted { $0.sentAt > $1.sentAt }) { signal in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(signal.peerID.prefix(10) + "…")
                                    .font(.subheadline.monospaced())
                                Text(signal.intent.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("clear") {
                                store.outgoingSignals[signal.peerID] = nil
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("signals")
    }
}

private struct BitNowProfileView: View {
    @ObservedObject var store: BitNowEncounterStore

    var body: some View {
        Form {
            Section("availability") {
                Toggle("visible to nearby BitNow peers", isOn: $store.profile.visibleNearby)
                Picker("what I want", selection: $store.profile.primaryIntent) {
                    ForEach(BitNowIntent.allCases) { intent in
                        Text(intent.title).tag(intent)
                    }
                }
            }

            Section("profile") {
                Stepper("age: \(store.profile.age)", value: $store.profile.age, in: 18...99)
                Toggle("show age", isOn: $store.profile.showAge)
                TextField("headline", text: $store.profile.headline)
                TextField("about / boundaries / vibe", text: $store.profile.about, axis: .vertical)
                    .lineLimit(3...7)
            }

            Section("privacy") {
                Text("BitNow nearby discovery is based on mesh reachability. This UI does not publish a precise map pin or continuous exact-distance readout.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("clear active signals", role: .destructive) {
                    store.clearAllSignals()
                }
            }
        }
        .navigationTitle("me")
    }
}
