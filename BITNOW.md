# BitNow

BitNow is an adults-only, proximity-first encounters app built on the BitChat mesh and encrypted messaging core.

## Product thesis

Most dating and hookup apps begin with a centralized directory and a map-like approximation of who might be nearby. BitNow begins with actual local network presence: compatible devices that are directly connected over Bluetooth or recently reachable through the mesh.

The core question is simple: **who is actually here, right now?**

BitNow keeps transport mechanics out of the normal experience. People see nearby presence, encounter intent, profiles they chose to share, signals, matches and encrypted chat. The existing core chooses direct BLE, multi-hop mesh, courier/store-and-forward or Nostr fallback.

## v1 product flow

1. Adult-only onboarding (18+).
2. User chooses an encounter intent:
   - right now
   - tonight
   - meet first
   - chat first
3. Nearby compatible peers appear from the live mesh roster.
4. A user may request another person's BitNow profile over an encrypted one-to-one message.
5. A visible peer automatically returns only the profile fields they chose to expose.
6. A user can send an expiring BitNow signal or open encrypted chat directly.
7. Signals expire after 45 minutes.
8. A mutual fresh signal becomes a match.
9. Existing BitChat block, verification and panic controls remain underneath the product layer.

## Privacy model

BitNow deliberately avoids an exact public map pin or continuous exact-distance readout. Nearby discovery is based on mesh reachability rather than exposing latitude/longitude to another user.

Encounter profiles are not broadcast in BLE advertisements. In v1 they are exchanged on demand through the existing encrypted private-message path. Signals can carry the sender's intentionally shared profile snapshot so the recipient has useful context without a public profile directory.

The underlying BitChat protocol still has metadata limitations that BitNow should improve over time, especially stable on-air identity and linkability. Those are protocol-hardening priorities, not claims we should paper over in marketing.

### Product rules

- 18+ only.
- Encounter interest is not consent to any other activity.
- Exact location is never required for local discovery.
- A user can become invisible to the encounter layer without shutting down the underlying app.
- Encounter signals are short-lived.
- Blocked peers never appear in BitNow discovery.
- Existing encrypted chat is reused instead of creating a weaker messaging path.
- Shared age is either 18–99 or withheld as `18+`.
- Profile payloads are length-bounded and validated before use.

## Compatibility strategy

BitNow initially preserves the BitChat wire protocol, BLE service identifiers, Noise behavior and routing stack so the project continues to inherit upstream security and transport improvements.

The product layer lives in `bitchat/BitNow/`.

### BitNow v1 control envelope

Signals and profile exchange use versioned structured control data carried inside the existing encrypted private-message transport. This avoids changing BitChat packet framing while keeping BitNow state machine-readable.

The user-visible fallback is ordinary text such as:

```text
⚡ BitNow signal — right now
⚡ BitNow profile request
⚡ BitNow profile shared
```

A U+2063 invisible separator follows that fallback text, then a Base64-encoded JSON envelope:

```text
version
kind: signal | profileRequest | profile
intent?
profile?
sentAt
```

The decoder rejects unknown versions, malformed Base64/JSON, oversized payloads, invalid age/profile fields and semantically invalid kind/payload combinations. The first textual v1 signal format remains readable for backward compatibility.

This is intentionally an application-layer bridge. A future BitNow protocol revision should move encounter control data into a dedicated authenticated capability/payload type while retaining compatibility negotiation with ordinary BitChat peers.

## Architecture

```text
BitNow UI
  ├─ Nearby
  ├─ Signals / matches
  ├─ Chats
  └─ Profile / visibility
        │
        ▼
BitNow encounter layer
  ├─ adult profile
  ├─ on-demand encrypted profile exchange
  ├─ short-lived encounter intent
  ├─ versioned control envelope
  ├─ mutual-match state
  └─ privacy defaults
        │
        ▼
Existing BitChat app models
  ├─ PeerListModel
  ├─ PrivateConversationModel
  ├─ PrivateInboxModel
  └─ ConversationUIModel
        │
        ▼
BitChat transport core
  ├─ BLE mesh
  ├─ Noise encryption
  ├─ courier/store-and-forward
  └─ Nostr fallback
```

## Next engineering passes

### 1. Native BitNow capability and encounter payload

Add a dedicated authenticated BitNow capability and typed encounter payload. Do not put exact coordinates into discovery announcements.

### 2. Rotating encounter identity

Do not expose a permanent encounter identifier to every nearby scanner. Build an epoch-rotating encounter alias bound to the long-term cryptographic identity only after an authenticated exchange.

### 3. Match lifecycle

Add typed cancellation, expiry acknowledgments, receipt state and explicit match teardown so state is consistent across reconnects and multiple devices.

### 4. Profile media

Profile images should be opt-in, size-bounded and exchanged only when a user chooses to make them available. Avoid broadcasting image blobs in BLE advertisements.

### 5. Discovery filters

Add adult profile fields and local filtering for gender/identity, who someone wants to meet, age range and encounter intent without forcing those fields into public BLE metadata.

### 6. Safety / moderation without a central account system

Keep blocking local and immediate. Add optional identity verification, local trust/vouch information, signed report export for users who choose to submit evidence, and abuse-rate limiting without requiring a public location trail.

### 7. Android

Use shared wire fixtures and codec tests so iOS and Android BitNow signals remain compatible.

## Current branch layout

- `main` — original September 2025 fork snapshot.
- `bitnow/core-2026-08` — clean modern upstream baseline.
- `agent/bitnow-v1` — BitNow product implementation branch.
