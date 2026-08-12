# BitNow

BitNow is an adults-only, proximity-first encounters app built on the modern BitChat mesh and encrypted messaging core.

## Product thesis

Most dating and hookup apps begin with a centralized directory and an approximate map. BitNow begins with **actual nearby network presence**: compatible devices directly connected over Bluetooth or recently reachable through the mesh.

The core question is simple: **who is actually here, right now?**

The user sees nearby people, deliberately shared profiles, encounter intent, signals, matches and encrypted chat. The transport core decides whether delivery is direct BLE, multi-hop mesh, courier/store-and-forward or Nostr fallback.

## Implemented v1 flow

1. **18+ onboarding.** The user confirms adulthood and explicitly acknowledges that an interest signal is not consent to anything else.
2. **Opt-in availability.** Encounter visibility defaults off. Turning it on creates a time-limited availability window.
3. **Expiring visibility.** The default window is one hour; the user can choose 30 minutes, 1 hour, 2 hours or 4 hours. There is no permanent-visible mode.
4. **BitNow-only discovery.** Ordinary BitChat users never enter the encounter roster. A BitNow capability bit is advertised only while the user is actively visible.
5. **Local discovery.** Nearby BitNow peers appear as `HERE NOW` or `NEARBY RECENTLY`; no precise map pin or continuous distance is displayed.
6. **Encrypted profile exchange.** A user can request a nearby peer's profile. A visible, unblocked BitNow peer replies through the existing encrypted one-to-one path.
7. **Adult profile.** Age may be shared or withheld as `18+`; identity, pronouns, headline, boundaries/about text, encounter intent and who someone is open to meeting are optional profile fields.
8. **Local filters.** Age range, identity and intent filtering happens on-device after a profile is received. Hidden values are not inferred.
9. **Interest signal.** Signals carry intent plus only the sender's intentionally shared profile snapshot and expire after 45 minutes.
10. **Match.** A fresh outgoing signal plus a fresh incoming signal from the same peer becomes a match.
11. **Encrypted chat.** Matching is not required to start a conversation; the existing private-chat transport remains available.
12. **Block / disappear.** Blocking is immediate. Going invisible clears active signals. Expiry also clears active signals.

## Privacy model

BitNow deliberately does **not** publish an exact encounter-location pin or a continuous exact-distance readout.

The BLE announce carries only BitNow encounter **availability support** through capability bit 11. It does not carry age, identity, pronouns, sexual/dating preferences, encounter intent, profile text or coordinates.

The BitNow capability itself is dynamic:

- before onboarding: off;
- while invisible: off;
- while an active availability window exists: on;
- after the deadline: off, even if the app was suspended before its UI timer could run.

Profiles and signals use the existing encrypted private-message routing path. Profile text is bounded before sending and validated after decoding. Malformed/oversized control envelopes and invalid adult ages are rejected.

The underlying BitChat protocol still has a known metadata limitation: its base radio identity is stable enough to permit correlation by a capable local observer. BitNow does not claim that this is solved. Rotating on-air encounter identity remains protocol-hardening work.

## Structured profile

Current optional profile fields:

```text
age / hidden as 18+
identity
pronouns
headline
about / boundaries / vibe
primary encounter intent
open-to-meeting identities
```

Current encounter intents:

```text
right now
tonight
meet first
chat first
```

Local filters:

```text
minimum / maximum age
identity
encounter intent
```

A restrictive age filter excludes profiles that withheld age rather than trying to infer it. The same principle applies to identity filtering.

## Compatibility strategy

BitNow keeps the modern BitChat transport/security core intact:

- BLE packet framing and service identifiers;
- Noise private sessions;
- message routing;
- courier/store-and-forward;
- Nostr fallback;
- panic wipe and existing trust/block mechanisms.

That separation lets BitNow continue to import upstream protocol and security improvements without coupling every product feature to the transport layer.

### BitNow capability

`PeerCapabilities.bitNow = 1 << 11`

This bit means only: **the peer is currently advertising BitNow encounter availability and understands the BitNow encounter layer**.

It is intentionally not a profile bitfield.

### BitNow v1 control envelope

Signals and profile exchange currently use versioned structured control data carried inside the existing encrypted private-message transport.

Readable fallback:

```text
⚡ BitNow signal — right now
⚡ BitNow profile request
⚡ BitNow profile shared
```

A U+2063 invisible separator follows the fallback, then Base64 JSON:

```text
version
kind: signal | profileRequest | profile
intent?
profile?
sentAt
```

The decoder rejects unknown versions, malformed Base64/JSON, oversized payloads, invalid profile fields and invalid kind/payload combinations. The first textual signal form remains readable for early-v1 compatibility.

This bridge is deliberately versioned so it can later be replaced with a dedicated typed encrypted BitNow payload.

## Product identity

Apple release defaults:

```text
Display name: BitNow
Version: 0.1.0
Bundle ID: app.bitnow.mesh
App Group: group.app.bitnow.mesh
```

The upstream developer signing team is not inherited. A developer copies `Configs/Local.xcconfig.example` and supplies their own Apple Team ID / local identifiers.

## Architecture

```text
BitNow UI
  ├─ Nearby
  ├─ Filters
  ├─ Signals / matches
  ├─ Chats
  └─ Profile / availability
        │
        ▼
BitNow encounter layer
  ├─ adult profile
  ├─ expiring radio visibility
  ├─ encrypted profile exchange
  ├─ versioned signal/profile envelope
  ├─ local discovery filters
  ├─ match state
  └─ block / privacy defaults
        │
        ▼
Existing BitChat app models
  ├─ PeerListModel
  ├─ PrivateConversationModel
  ├─ PrivateInboxModel
  └─ ConversationUIModel
        │
        ▼
Modern BitChat transport core
  ├─ BLE mesh
  ├─ Noise encryption
  ├─ courier/store-and-forward
  └─ Nostr fallback
```

## Tests added

The BitNow branch adds regression coverage for:

- every signal intent round-trip;
- profile snapshot round-trip;
- hidden age;
- profile-request envelope;
- ordinary chat not being parsed as BitNow control traffic;
- 18+ profile validation;
- old v1 profile migration after new optional fields were added;
- age / identity / intent filters;
- reciprocal preference logic;
- radio visibility gate;
- availability expiry and signal clearing;
- BitNow peer-capability encoding.

## Android status

The current `thotsl4yer69/bitchat-android` repository is a separate July-2025 implementation with no common Git ancestry with the modern Android upstream and an unimplemented private-message decryption path.

A separate branch/PR now contains the matching BitNow v1 Kotlin codec, profile model, tests and BitNow application identity, but **encounter transmission is intentionally disabled until that repository is moved to the modern encrypted Android transport**. BitNow will not ship sensitive encounter data over a plaintext legacy private-message path.

## Remaining release work

### 1. CI must be green

The Apple PR stays draft until the repository's existing SwiftPM, iOS/macOS Xcode, performance and dead-code jobs complete successfully. At the time this document was updated, GitHub's macOS jobs were queued rather than failed.

### 2. Dedicated typed BitNow private payload

The v1 control envelope currently rides through the normal encrypted DM pipeline. This preserves security/routing but means its readable fallback can exist in conversation history. Move BitNow control traffic to a dedicated typed encrypted payload so encounter protocol traffic and user chat have independent lifecycle/unread semantics.

### 3. Rotating on-air encounter identity

Design an epoch-rotating alias/recognition scheme so encounter presence is less linkable over time without breaking authenticated peer identity after connection.

### 4. Profile media

Add explicit, opt-in, size-bounded profile media over the encrypted private-media path. Never broadcast profile images in BLE advertisements.

### 5. Android transport migration

Move the BitNow Kotlin layer onto current `permissionlesstech/bitchat-android`, then prove Swift ↔ Kotlin behavior with shared fixtures before release.

### 6. Release/legal packaging

Finalize app icon/brand assets, privacy policy, age rating/distribution requirements, signing identifiers and beta/release packaging.

## Branches / pull requests

Apple:

```text
main                  original September-2025 fork snapshot
bitnow/core-2026-08   clean modern upstream baseline
agent/bitnow-v1       BitNow implementation
```

Android:

```text
main                    old July-2025 implementation
agent/bitnow-android-v1 protocol/product preparation only
```
