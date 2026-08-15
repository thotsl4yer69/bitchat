import BitFoundation
import Foundation
import SwiftUI

enum BitNowReportReason: String, CaseIterable, Identifiable {
    case underage = "under 18 / age concern"
    case harassment = "harassment or unwanted contact"
    case impersonation = "impersonation or deception"
    case exploitation = "sexual services, exploitation or trafficking"
    case nonConsensual = "non-consensual intimate content"
    case threats = "threats or immediate safety concern"
    case other = "other"

    var id: String { rawValue }
}

struct BitNowReportContext: Identifiable {
    let peerID: PeerID
    let displayName: String

    var id: String { peerID.id }
}

enum BitNowSupport {
    static var reportingEmail: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "BitNowReportEmail") as? String else {
            return nil
        }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.contains("@"), !value.contains("$(") else { return nil }
        return value
    }

    static func reportURL(
        context: BitNowReportContext,
        reason: BitNowReportReason,
        details: String
    ) -> URL? {
        guard let reportingEmail else { return nil }

        let peerFingerprint = String(context.peerID.id.prefix(24))
        let body = """
        BitNow safety report

        Reported display name: \(context.displayName)
        Peer identifier prefix: \(peerFingerprint)
        Reason: \(reason.rawValue)
        Reported at: \(ISO8601DateFormatter().string(from: Date()))

        Details:
        \(details.trimmingCharacters(in: .whitespacesAndNewlines))

        Please do not include passwords, financial credentials, exact home addresses, or intimate media in this email.
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = reportingEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "BitNow safety report — \(reason.rawValue)"),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}

struct BitNowReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let context: BitNowReportContext
    let onBlock: () -> Void

    @State private var reason: BitNowReportReason = .harassment
    @State private var details = ""
    @State private var alsoBlock = true
    @State private var showingConfigurationError = false

    var body: some View {
        Form {
            Section("report person") {
                Text(context.displayName)
                    .font(.headline)
                Text("Reports are sent privately to the BitNow support address configured in the signed release build.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("reason") {
                Picker("reason", selection: $reason) {
                    ForEach(BitNowReportReason.allCases) { reason in
                        Text(reason.rawValue).tag(reason)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("details") {
                TextEditor(text: $details)
                    .frame(minHeight: 120)
                Text("Describe what happened. Do not attach intimate media or unnecessary identifying information.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("also block this person on this device", isOn: $alsoBlock)
            }

            Section {
                Button("send private safety report") {
                    sendReport()
                }
                .disabled(details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                if BitNowSupport.reportingEmail == nil {
                    Text("Release configuration is incomplete: BITNOW_REPORT_EMAIL must be set before public distribution.")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("report")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("cancel") { dismiss() }
            }
        }
        .alert("reporting is not configured", isPresented: $showingConfigurationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This build has no moderation address. Public release is blocked until BITNOW_REPORT_EMAIL is configured.")
        }
    }

    private func sendReport() {
        guard let url = BitNowSupport.reportURL(context: context, reason: reason, details: details) else {
            showingConfigurationError = true
            return
        }

        if alsoBlock {
            onBlock()
        }
        openURL(url)
        dismiss()
    }
}
