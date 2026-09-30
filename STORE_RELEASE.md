# BitNow Store Release Gate

This document defines what must be true before BitNow is submitted as a public mobile-store release. It is intentionally stricter than “the project compiles.”

## Product position

The App Store build is an **adults-only proximity dating and meeting app**. It is not marketed or designed as a marketplace for sexual services, prostitution, pornography, trafficking, exploitation, or transactional sex.

The immediate intent remains wire-compatible as `now`, but its user-facing label is `meet now`. Existing intents remain `tonight`, `meet first`, and `chat first`.

A BitNow signal expresses interest only. It does not constitute consent.

## Automated engineering gate

Before submission, the exact release-candidate commit must pass the repository's existing Build & Test and Dead Code workflows. Any code or release-metadata change after a green run requires validation of the new head.

## Physical-device gate

The exact signed release candidate must be installed on at least two physical iPhones and complete this matrix:

1. Fresh install starts encounter visibility off.
2. Both users complete the 18+ acknowledgement.
3. Device A enables a 30-minute window; Device B sees A as a compatible nearby BitNow peer.
4. Device B requests A's profile; A's shared fields arrive through the encrypted private transport.
5. Hidden age is represented as `18+` rather than inferred.
6. A sends a signal to B; B reciprocates; both show a match.
7. Private encrypted chat works after matching.
8. Blocking removes the peer from BitNow discovery and stops automatic profile responses.
9. Availability expiry removes the BitNow capability and clears active outgoing signals.
10. Backgrounding/suspending the app beyond expiry does not extend encounter advertising.
11. The local BitNow privacy reset clears profile/discovery state, availability, and active outgoing signals as designed.
12. BitNow control messages do not create misleading normal-chat UI or unread state in the final release UI.

## Trust and safety gate

Public release requires all of the following:

- published Community Guidelines;
- profile/content filtering appropriate to the app's permitted use;
- in-app ability to block abusive peers;
- a private in-app reporting mechanism;
- a real support/moderation destination controlled by the BitNow operator;
- a documented response process for reports, with urgent handling for minors, credible threats, trafficking/exploitation, and non-consensual intimate material;
- published support/contact information that matches the store listing and privacy policy.

A GitHub public issue tracker is not an acceptable default destination for sensitive abuse reports.

## Privacy gate

The shipping binary, privacy policy, Apple privacy manifest, App Store privacy answers, and store description must describe the same behavior.

BitNow must not claim that:

- exact radio distance is known;
- Bluetooth/protocol identity is unlinkable;
- hidden age can be inferred;
- a block creates a network-wide ban;
- encounter data is never retained when the underlying encrypted message transport can retain delivery/history state; or
- third-party relays can erase data on command.

## Signing and store assets

Before submission:

- use a BitNow-controlled Apple Developer team;
- verify production bundle ID and App Group identifiers;
- archive a Release build with production signing;
- replace/approve final BitNow app icon and store artwork;
- complete age rating and content disclosures;
- provide privacy-policy and support URLs;
- provide review notes explaining the peer-to-peer proximity flow without overclaiming privacy or hiding functionality.

## Android

The current Android repository produces a **protocol-preview APK only**. It deliberately does not transmit BitNow encounter profiles or signals because the old transport was not suitable for sensitive encounter data.

Production Android release is gated on migration to the current encrypted BitChat transport and cross-platform Swift/Kotlin wire fixtures. The preview APK must never be presented as the production Android client.

## Merge policy

The Apple feature PR can be code-review ready when automated validation is green. It must not be tagged or represented as a public production release until the physical-device, trust-and-safety, signing, privacy, and store gates above are complete.
