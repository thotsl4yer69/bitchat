import BitFoundation
import SwiftUI

private enum BitNowTab: Hashable {
    case nearby, signals, chats, me
}

struct BitNowRootView: View {
    @AppStorage("bitnow.onboarding.complete") private var onboardingComplete = false
    @StateObject private var store = BitNowEncounterStore()

    var body: some View {
        if onboardingComplete {
            BitNowMainView(store: store)
        } else {
            BitNowOnboardingView(store: store, onboardingComplete: $onboardingComplete)
        }
    }
}

private struct BitNowMainView: View {
    @EnvironmentObject private var peerListModel: PeerListModel
    @EnvironmentObject private var privateInboxModel: PrivateInboxModel
    @EnvironmentObject private var privateConversationModel: PrivateConversationModel
    @EnvironmentObject private var conversationUIModel: ConversationUIModel

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
        .onReceive(privateInboxModel.objectWillChange) { _ in
            scheduleProfileRequestScan()
        }
        .onChange(of: peerListModel.renderID) { _ in
            scheduleProfileRequestScan()
        }
        .onAppear {
            scheduleProfileRequestScan()
        }
    }

    private func scheduleProfileRequestScan() {
        Task { @MainActor in
            await Task.yield()
            respondToProfileRequests()
        }
    }

    private func respondToProfileRequests() {
        guard store.profile.visibleNearby, store.profile.isAdult else { return }

        for row in peerListModel.meshRows
            where row.supportsBitNow && !row.isMe && !row.isBlocked {
            for message in privateInboxModel.messages(for: row.peerID).suffix(16) {
                guard message.senderPeerID == row.peerID,
                      let envelope = BitNowWireCodec.decode(message.content),
                      envelope.kind == .profileRequest,
                      store.claimProfileRequest(messageID: message.id) else {
                    continue
                }
                sendControl(BitNowWireCodec.encodeProfile(store.profile), to: row.peerID)
            }
        }
    }

    private func sendControl(_ content: String, to peerID: PeerID) {
        let previousPeer = privateConversationModel.selectedPeerID
        privateConversationModel.startConversation(with: peerID)
        conversationUIModel.sendMessage(content)
        if let previousPeer {
            privateConversationModel.startConversation(with: previousPeer)
        } else {
            privateConversationModel.endConversation()
        }
    }
}

private struct BitNowOnboardingView: View {
    @EnvironmentObject private var peerListModel: PeerListModel
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
                        peerListModel.refreshLocalAdvertisement()
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

private struct BitNowEmptyState: View {
    let title: String
    let systemImage: String
    let detail: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .semibold))
            Text(title).font(.title3.weight(.bold))
            Text(detail)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

private struct BitNowNearbyView: View {
    @EnvironmentObject private var peerListModel: PeerListModel
    @EnvironmentObject private var privateInboxModel: PrivateInboxModel
    @EnvironmentObject private var privateConversationModel: PrivateConversationModel
    @EnvironmentObject private var conversationUIModel: ConversationUIModel

    @ObservedObject var store: BitNowEncounterStore
    @Binding var selectedTab: BitNowTab
    @State private var showingFilters = false

    private var nearbyRows: [MeshPeerRow] {
        guard store.profile.visibleNearby else { return [] }
        return peerListModel.meshRows
            .filter {
                $0.supportsBitNow
                    && !$0.isMe
                    && !$0.isBlocked
                    && ($0.isConnected || $0.isReachable)
            }
            .filter { row in
                guard let profile = store.latestSharedProfile(
                    from: row.peerID,
                    inbox: privateInboxModel
                ) else {
                    return true
                }
                return store.discoveryAllows(profile)
            }
            .sorted {
                if $0.isConnected != $1.isConnected { return $0.isConnected }
                return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
    }

    var body: some View {
        Group {
            if !store.profile.visibleNearby {
                BitNowEmptyState(
                    title: "you are invisible",
                    systemImage: "eye.slash.fill",
                    detail: "Turn nearby visibility back on from Me when you want to appear in the local encounter layer."
                )
            } else if nearbyRows.isEmpty {
                BitNowEmptyState(
                    title: "no matching BitNow peers nearby",
                    systemImage: "dot.radiowaves.left.and.right",
                    detail: "Only nearby peers that explicitly advertise BitNow encounter availability appear here. Known profiles also respect your local filters."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(nearbyRows) { row in
                            let profile = store.latestSharedProfile(
                                from: row.peerID,
                                inbox: privateInboxModel
                            )
                            BitNowNearbyCard(
                                row: row,
                                profile: profile,
                                reciprocalFit: reciprocalFit(profile),
                                outgoingSignal: store.outgoingSignal(to: row.peerID),
                                onRequestProfile: { requestProfile(from: row.peerID) },
                                onSignal: { intent in sendSignal(to: row.peerID, intent: intent) },
                                onChat: { openChat(with: row.peerID) },
                                onBlock: { block(row) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("nearby now")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Text("\(nearbyRows.count) here")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("discovery filters")
            }
        }
        .sheet(isPresented: $showingFilters) {
            NavigationStack {
                BitNowFiltersView(store: store)
            }
        }
    }

    private func reciprocalFit(_ remoteProfile: BitNowSharedProfile?) -> Bool {
        guard let localIdentity = store.profile.identity,
              let interests = remoteProfile?.interestedIn,
              !interests.isEmpty else { return false }
        return interests.contains(localIdentity)
    }

    private func sendSignal(to peerID: PeerID, intent: BitNowIntent) {
        sendControl(BitNowSignalCodec.encode(intent, profile: store.profile), to: peerID)
        store.recordOutgoingSignal(to: peerID, intent: intent)
    }

    private func requestProfile(from peerID: PeerID) {
        sendControl(BitNowWireCodec.encodeProfileRequest(), to: peerID)
    }

    private func openChat(with peerID: PeerID) {
        privateConversationModel.startConversation(with: peerID)
        selectedTab = .chats
    }

    private func block(_ row: MeshPeerRow) {
        conversationUIModel.block(peerID: row.peerID, displayName: row.displayName)
        store.clearSignal(for: row.peerID)
    }

    private func sendControl(_ content: String, to peerID: PeerID) {
        let previousPeer = privateConversationModel.selectedPeerID
        privateConversationModel.startConversation(with: peerID)
        conversationUIModel.sendMessage(content)
        if let previousPeer {
            privateConversationModel.startConversation(with: previousPeer)
        } else {
            privateConversationModel.endConversation()
        }
    }
}

private struct BitNowNearbyCard: View {
    let row: MeshPeerRow
    let profile: BitNowSharedProfile?
    let reciprocalFit: Bool
    let outgoingSignal: BitNowOutgoingSignal?
    let onRequestProfile: () -> Void
    let onSignal: (BitNowIntent) -> Void
    let onChat: () -> Void
    let onBlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(row.displayName).font(.title3.weight(.bold))
                        if let profile {
                            Text(profile.ageLabel)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(row.isConnected ? "HERE NOW" : "NEARBY RECENTLY")
                        .font(.caption.weight(.black))
                        .foregroundStyle(row.isConnected ? .primary : .secondary)
                }
                Spacer()
                if row.isMutualFavorite {
                    Image(systemName: "checkmark.seal.fill")
                        .accessibilityLabel("mutual trusted contact")
                }
                Menu {
                    Button(role: .destructive, action: onBlock) {
                        Label("block", systemImage: "hand.raised.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("person options")
            }

            if let profile {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let identity = profile.identityLabel {
                            Text(identity).font(.subheadline.weight(.semibold))
                        }
                        if let pronouns = profile.pronouns, !pronouns.isEmpty {
                            Text("• \(pronouns)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Label(profile.primaryIntent.title, systemImage: profile.primaryIntent.systemImage)
                        .font(.subheadline.weight(.semibold))
                    if reciprocalFit {
                        Label("you fit their stated type", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                    }
                    if !profile.headline.isEmpty {
                        Text(profile.headline).font(.subheadline)
                    }
                    if !profile.about.isEmpty {
                        Text(profile.about)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            } else {
                Button(action: onRequestProfile) {
                    Label("ask for profile", systemImage: "person.text.rectangle")
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 10) {
                Menu {
                    ForEach(BitNowIntent.allCases) { intent in
                        Button { onSignal(intent) } label: {
                            Label(intent.title, systemImage: intent.systemImage)
                        }
                    }
                } label: {
                    Label(
                        outgoingSignal == nil ? "signal" : "signalled",
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
            guard row.supportsBitNow,
                  !row.isMe,
                  !row.isBlocked,
                  let signal = store.latestIncomingSignal(from: row.peerID, inbox: privateInboxModel) else { return nil }
            return BitNowSignalPerson(
                row: row,
                incoming: signal,
                isMatch: store.isMatch(with: row.peerID, inbox: privateInboxModel)
            )
        }
        .sorted {
            if $0.isMatch != $1.isMatch { return $0.isMatch }
            return $0.incoming.receivedAt > $1.incoming.receivedAt
        }
    }

    var body: some View {
        List {
            Section("incoming") {
                if incoming.isEmpty {
                    Text("No fresh incoming signals. Signals expire after 45 minutes.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(incoming) { item in
                        Button {
                            privateConversationModel.startConversation(with: item.row.peerID)
                            selectedTab = .chats
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.isMatch ? "heart.fill" : "bolt.fill")
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(item.row.displayName).font(.headline)
                                        if let age = item.incoming.profile?.ageLabel {
                                            Text(age).font(.caption.monospacedDigit())
                                        }
                                    }
                                    Text(item.isMatch ? "MATCH • \(item.incoming.intent.title)" : "interested • \(item.incoming.intent.title)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    if let headline = item.incoming.profile?.headline, !headline.isEmpty {
                                        Text(headline)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("your active signals") {
                if store.outgoingSignals.isEmpty {
                    Text("Nothing active.").foregroundStyle(.secondary)
                } else {
                    ForEach(store.outgoingSignals.values.sorted { $0.sentAt > $1.sentAt }) { signal in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(String(signal.peerID.prefix(10)) + "…")
                                    .font(.subheadline.monospaced())
                                Text(signal.intent.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("clear") { store.clearSignal(peerIDString: signal.peerID) }
                        }
                    }
                }
            }
        }
        .navigationTitle("signals")
    }
}

private struct BitNowProfileView: View {
    @EnvironmentObject private var peerListModel: PeerListModel
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

            BitNowProfileFields(store: store)

            Section("privacy") {
                Text("Profiles and dating preferences are shared only through encrypted one-to-one BitNow control messages. Nearby discovery itself does not publish a precise map pin or continuous exact-distance readout.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("go invisible now", role: .destructive) {
                    store.profile.visibleNearby = false
                    store.clearAllSignals()
                }
                Button("clear active signals", role: .destructive) {
                    store.clearAllSignals()
                }
            }
        }
        .navigationTitle("me")
        .onChange(of: store.profile.visibleNearby) { _ in
            peerListModel.refreshLocalAdvertisement()
        }
    }
}
