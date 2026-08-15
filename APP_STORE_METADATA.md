# BitNow — App Store Metadata Draft

This file is the canonical draft for App Store Connect. Store copy must stay consistent with the shipping binary, `PRIVACY_POLICY.md`, `COMMUNITY_GUIDELINES.md`, and `STORE_RELEASE.md`.

## Name

**BitNow**

## Subtitle

**Meet nearby. Stay in control.**

## Promotional text

BitNow is adults-only proximity dating built around short visibility windows, private profile exchange, and encrypted direct chat — without a public exact-location map.

## Description

**See who is actually nearby — only when you choose to be visible.**

BitNow is an adults-only proximity dating and meeting app built on peer-to-peer local connectivity. Instead of publishing an exact map pin or keeping you permanently discoverable, BitNow lets you open a short nearby-visibility window and connect with other compatible adults who are locally reachable.

**Nearby on your terms**

Choose a 30-minute, 1-hour, 2-hour, or 4-hour visibility window. There is no permanent-visible mode. When the window expires, BitNow stops advertising dating availability and clears active outgoing signals.

**Profiles are not broadcast**

Nearby discovery advertises only that a compatible BitNow user is available. Profile details, dating preferences, identity, pronouns, age display, headline, and about/boundaries text are exchanged privately on request through the encrypted direct-message transport.

**Signal interest, then chat**

Choose `meet now`, `tonight`, `meet first`, or `chat first`. Signals expire automatically. A mutual fresh signal becomes a match, and encrypted private chat is available when you choose to continue.

**Privacy without impossible promises**

BitNow does not publish an exact encounter map or continuous precise-distance readout. Bluetooth and network systems can still expose technical metadata such as signal strength, timing, and protocol identifiers, so BitNow does not claim that radio presence is anonymous or unlinkable.

**Safety controls**

BitNow is 18+ only. Interest is not consent. Profiles that indicate under-18 use, transactional sexual services, or explicit-content solicitation are blocked from dating-profile sharing. You can block another peer locally and submit a private safety report to the configured BitNow moderation contact.

BitNow is built on the open-source BitChat transport stack. Optional inherited BitChat functions may have additional privacy behavior described in the BitNow Privacy Policy.

## Keywords draft

proximity, dating, nearby, private chat, bluetooth, mesh, meet, local, encrypted, adults

Do not use store keywords such as `hookup`, `sex`, `escort`, `prostitution`, or pornography terms. This is not a keyword-hiding tactic; those uses are outside the permitted product design and Community Guidelines.

## Review notes

BitNow's core flow is:

1. User completes an 18+ acknowledgement. The app remains invisible after onboarding.
2. User deliberately starts a short nearby-visibility window from the Me tab.
3. Compatible nearby BitNow peers are discovered using the existing Bluetooth mesh transport. The UI does not show exact GPS coordinates or a continuous exact-distance value.
4. A peer may request the user's profile. Profile information is returned one-to-one over the encrypted private transport, not broadcast in BLE discovery metadata.
5. A user may send a short-lived interest signal. Mutual fresh signals are presented as a match.
6. Users may continue with the existing encrypted private chat.
7. Users may block locally or open the private report flow from the person's options menu.
8. Visibility expires automatically. App suspension does not intentionally extend the radio capability past the stored expiry deadline.

### Review setup requirements

The review build must be signed with a real `BITNOW_REPORT_EMAIL` value so the Report action has a valid operator-controlled destination. Do not submit a build showing the release-configuration error for reporting.

Because the primary proximity feature uses Bluetooth discovery between separate devices, meaningful end-to-end testing requires two physical compatible Apple devices with Bluetooth enabled and the required permissions granted. Provide the review team with two-device instructions if requested.

### Important privacy disclosure for review

BitNow does **not** claim that the underlying persistent cryptographic/radio peer identity is unlinkable across sessions. The product minimizes profile broadcasting and exact-location presentation, but nearby peers or infrastructure can still observe protocol/radio/network metadata.

## Support URL

Set an operator-controlled public HTTPS support page before submission. It should publish:

- BitNow support contact;
- private safety-report contact/process;
- Community Guidelines;
- Privacy Policy; and
- instructions for blocking, privacy reset, and urgent safety concerns.

Do not use a public GitHub issue as the primary safety-report destination.

## Privacy Policy URL

Publish `PRIVACY_POLICY.md` at a stable public HTTPS URL controlled for the BitNow release and use that URL in App Store Connect.

## Final metadata checks

Before submission, verify screenshots and copy do not promise exact distance, anonymous/unlinkable presence, centralized moderation that does not exist, external age verification that is not implemented, or remote deletion from recipient devices/third-party relays.
