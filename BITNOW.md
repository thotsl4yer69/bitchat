# BitNow

BitNow is an adults-only, proximity-first **dating and meeting** app built on the modern BitChat mesh and encrypted messaging core.

## Product thesis

Most dating apps begin with a centralized directory. BitNow begins with **actual nearby network presence**: compatible devices directly connected over Bluetooth or recently reachable through the mesh.

The core question is: **who is actually nearby, now?**

The user chooses when to become discoverable, sees compatible nearby adults, requests deliberately shared profiles, sends short-lived interest signals, matches, and continues into encrypted private chat. The transport core decides whether delivery is direct BLE, multi-hop mesh, courier/store-and-forward, or optional Nostr fallback.

## Implemented v1 flow

1. **18+ onboarding.** The user confirms adulthood and acknowledges that an interest signal is not consent. Finishing onboarding leaves nearby visibility off.
2. **Explicit availability.** The user chooses a 30-minute, 1-hour, 2-hour, or 4-hour visibility window. There is no permanent-visible mode.
3. **BitNow-only discovery.** Ordinary BitChat users never enter the dating roster. Capability bit 11 is advertised only during valid BitNow availability.
4. **Coarse proximity UI.** Peers appear as `HERE NOW` or `NEARBY RECENTLY`; BitNow does not expose a public exact-location pin or continuous exact-distance readout.
5. **Encrypted profile exchange.** A user can request a nearby peer's profile. A visible, unblocked, policy-valid BitNow peer replies over the encrypted one-to-one path.
6. **Adult profile.** Age may be shared or represented as `18+`; identity, pronouns, headline, boundaries/about text, dating intent, and who someone is open to meeting are optional.
7. **Local filtering.** Age range, identity, and intent filtering happens on-device after a profile is received. Hidden values are not inferred.
8. **Interest signals.** Signals carry intent plus the sender's intentionally shared profile snapshot and expire after 45 minutes.
9. **Match.** A fresh outgoing signal plus a fresh incoming signal from the same peer becomes a match.
10. **Encrypted chat.** Existing private chat remains the conversation layer.
11. **Block and report.** A nearby peer can be blocked locally or reported through the private safety-report flow configured for the signed release.
12. **Automatic expiry.** Going invisible or reaching the availability deadline clears active outgoing signals and removes BitNow advertising.

## Dating intents

The wire values remain stable for compatibility:

```text
now        -> meet now
tonight    -> tonight
meetFirst  -> meet first
chatFirst  -> chat first
```

Changing `now` to the user-facing label `meet now` does not change the v1 protocol value.

## Trust and safety

BitNow's public product rules are defined in `COMMUNITY_GUIDELINES.md` and its public-release gate in `STORE_RELEASE.md`.

The current app:

- is 18+ only;
- treats signals as interest, never consent;
- blocks dating-profile sharing when profile text indicates under-18 use, transactional sexual services, or explicit-content solicitation patterns;
- turns nearby availability off if a currently visible profile becomes unshareable;
- supports local blocking;
- supports a private report flow to the operator-controlled `BITNOW_REPORT_EMAIL` configured in the signed release; and
- deliberately fails the reporting flow closed when no moderation contact is configured.

A public issue tracker is not the intended destination for sensitive safety reports.

## Privacy model

BitNow deliberately does **not** publish an exact dating-location pin or continuous exact-distance readout.

BLE capability bit 11 advertises only that the peer is currently available to the BitNow dating layer. It does not contain age, identity, pronouns, dating preferences, intent, profile text, or coordinates.

The capability is dynamic:

- before the user enables availability: off;
- during a valid availability window: on;
- after going invisible: off;
- after the stored deadline: off, even if app UI work was suspended.

Profiles and signals use the existing encrypted private-message routing path. Profile data is bounded and validated before it is accepted as BitNow control data.

The underlying BitChat protocol still has a metadata limitation: its base radio/cryptographic identity can be stable enough to permit correlation by a capable observer. BitNow does not claim that this is solved. Rotating on-air identity remains later protocol-hardening work.

## Control messages versus normal chat

BitNow v1 uses a versioned structured control envelope over the existing encrypted private-message transport for signals, profile requests, and profile replies.

The raw private inbox retains those messages so BitNow can process them, but the normal `MessageListView` filters valid BitNow control envelopes out of the visible direct-message timeline, unread-count path, and private-chat scroll targets. Users therefore do not see profile requests or signals as ordinary chat rows.

A future dedicated typed private payload would further separate control data at the transport layer rather than only at the presentation/lifecycle layer.

## Wire envelope

Readable fallback plus a U+2063 separator and Base64 JSON carries:

```text
version
kind: signal | profileRequest | profile
intent?
profile?
sentAt
```

The decoder rejects unknown versions, malformed Base64/JSON, oversized payloads, invalid ages, invalid field lengths, prohibited shared-profile content, and invalid kind/payload combinations.

## Compatibility strategy

BitNow keeps the modern BitChat transport/security core intact:

- BLE packet framing and service identifiers;
- Noise private sessions;
- message routing;
- courier/store-and-forward;
- optional Nostr fallback;
- existing trust/block mechanisms; and
- existing media/chat capabilities.

That separation allows upstream protocol/security improvements to continue without coupling every BitNow product feature to the transport layer.

## Product identity

Apple release defaults:

```text
Display name: BitNow
Version: 0.1.0
Bundle ID: app.bitnow.mesh
App Group: group.app.bitnow.mesh
```

The upstream developer signing team is not inherited. `Configs/Local.xcconfig.example` documents developer-specific signing identifiers and the required private moderation email configuration.

## Tests

BitNow regression coverage includes:

- every signal intent round-trip;
- stable `now` wire value with `meet now` display copy;
- profile snapshot round-trip;
- hidden age;
- profile-request envelope;
- ordinary chat not being parsed as BitNow control traffic;
- 18+ profile validation;
- prohibited-profile filtering;
- fail-closed visibility when a profile becomes unshareable;
- old v1 profile migration;
- age / identity / intent filters;
- reciprocal preference logic;
- radio visibility gating;
- availability expiry and signal clearing; and
- BitNow peer-capability encoding.

## Android status

The current `thotsl4yer69/bitchat-android` repository is an older independent implementation rather than the modern encrypted Android BitChat core.

Its BitNow branch is intentionally a **protocol-preview build**. The insecure legacy BLE/private-message service was removed from the preview build, and no BitNow dating profile or signal data is transmitted. The preview APK CI is green.

Production Android remains gated on migration to the current encrypted transport plus Swift/Kotlin interoperability fixtures.

## Public-release status

The Apple feature branch is a release candidate, not a public production release. Before public distribution, the exact head must pass automated CI and the external release gates in `STORE_RELEASE.md`, including:

- real moderation/support contact configuration;
- production Apple signing;
- two-physical-iPhone BLE end-to-end testing;
- final app icon/store artwork;
- stable privacy/support URLs; and
- App Store metadata, privacy, content, and review submission.

`APP_STORE_METADATA.md` contains the current truthful submission copy and reviewer flow.

## Branches

```text
Apple
bitnow/core-2026-08   clean modern upstream baseline
agent/bitnow-v1       BitNow release-candidate work

Android
main                    old independent implementation
agent/bitnow-android-v1 fail-closed protocol preview
```
