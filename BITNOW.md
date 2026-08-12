# BitNow

BitNow is an adults-only, proximity-first encounters app built on the BitChat mesh and encrypted messaging core.

## Product thesis

Most dating and hookup apps begin with a centralized directory and a map-like approximation of who might be nearby. BitNow begins with actual local network presence: compatible devices that are directly connected over Bluetooth or recently reachable through the mesh.

The core question is simple: **who is actually here, right now?**

BitNow keeps the underlying transport intelligence out of the normal user experience. People see nearby presence, encounter intent, signals, matches and encrypted chat. The app decides whether delivery is direct BLE, multi-hop mesh, courier/store-and-forward or Nostr fallback.

## v1 product flow

1. Adult-only onboarding (18+).
2. User chooses a simple encounter intent:
   - right now
   - tonight
   - meet first
   - chat first
3. Nearby compatible peers appear from the mesh roster.
4. A user can send an expiring BitNow signal or open encrypted chat directly.
5. Signals expire after 45 minutes.
6. A mutual fresh signal becomes a match.
7. Blocking and existing BitChat privacy/panic controls remain available in chat.

## Privacy model

BitNow deliberately avoids an exact public map pin or continuous exact-distance readout. Nearby discovery is based on mesh reachability rather than exposing latitude/longitude to other users.

The underlying BitChat protocol still has metadata limitations that BitNow should improve over time, especially stable on-air identity and linkability. Those are protocol-hardening priorities, not claims we should paper over in marketing.

### Product rules

- 18+ only.
- Encounter interest is not consent to any other activity.
- Exact location is never required for local discovery.
- A user can become invisible to the encounter layer without shutting down the underlying app.
- Encounter signals are short-lived.
- Blocked peers never appear in BitNow discovery.
- Existing encrypted chat is reused instead of creating a weaker messaging path.

## Compatibility strategy

BitNow initially preserves the BitChat wire protocol, BLE service identifiers, Noise behavior and routing stack so the project continues to inherit upstream security and transport improvements.

The product layer lives in `bitchat/BitNow/`.

Current v1 signals use a reserved human-readable private-message control form:

```text
⚡ BitNow • signal • now
⚡ BitNow • signal • tonight
⚡ BitNow • signal • meetFirst
⚡ BitNow • signal • chatFirst
```

This lets two BitNow clients match immediately without changing the BitChat packet format. It is intentionally versionable and replaceable. A later protocol revision should move BitNow profile/intent exchange into an authenticated capability extension rather than ordinary chat content.

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
  ├─ short-lived intent
  ├─ signal codec
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

### 1. Native BitNow presence packet

Add an authenticated BitNow capability/profile envelope carrying only intentionally public encounter metadata. Do not put exact coordinates in it.

Suggested fields:

- version
- visibility epoch
- age/display-age policy
- short headline
- primary intent
- optional profile digest
- expiry

### 2. Rotating encounter identity

Do not expose a permanent encounter identifier to every nearby scanner. Build an epoch-rotating encounter alias bound to the long-term cryptographic identity only after an authenticated exchange.

### 3. Better matches

Move signals from reserved chat text to a typed encrypted payload. Add explicit cancellation, expiry acknowledgments and receipt state.

### 4. Profile media

Profile images should be opt-in, size-bounded and exchanged only when a user chooses to make them available. Avoid broadcasting image blobs in BLE advertisements.

### 5. Safety / moderation without a central account system

Keep blocking local and immediate. Add optional identity verification, local trust/vouch information, signed report export for users who choose to submit evidence, and abuse-rate limiting without requiring a public location trail.

### 6. Android

Use shared wire fixtures and codec tests so iOS and Android BitNow signals remain compatible.

## Current branch layout

- `main` — original September 2025 fork snapshot.
- `bitnow/core-2026-08` — clean modern upstream baseline.
- `agent/bitnow-v1` — BitNow product implementation branch.
