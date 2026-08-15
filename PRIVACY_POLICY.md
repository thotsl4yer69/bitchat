# BitNow Privacy Policy

*Last updated: 15 August 2026*

## What BitNow Is

BitNow is an adults-only, proximity-first encounter and private messaging app built on the BitChat peer-to-peer transport stack. It is designed to let adults opt in for a short period, discover compatible BitNow users who are locally reachable, request a profile privately, exchange short-lived interest signals, and continue into encrypted private chat when they choose.

BitNow does not require a project-operated account, does not publish an exact map location, and does not operate a centralized dating-profile database.

## Adults Only

BitNow is intended only for people aged 18 or older. The current release uses self-attested age rather than an external identity or age-verification provider. During onboarding, a user must confirm that they are at least 18 and acknowledge that an interest signal is not consent to sexual contact, physical contact, or any other activity.

If you are under 18, do not use BitNow.

## Privacy Summary

- **No BitNow account database.** Core encounter and messaging functions are peer-to-peer or use optional third-party relay infrastructure already provided by the BitChat transport layer.
- **No public exact-location pin.** BitNow does not publish exact latitude or longitude as part of encounter discovery.
- **Short, explicit visibility windows.** Encounter visibility is off by default and can be enabled for 30 minutes, 1 hour, 2 hours, or 4 hours. There is no permanent-visible mode.
- **Minimal proximity advertisement.** A BitNow capability flag indicates only that a compatible adult user has intentionally made BitNow encounter discovery available. It does not broadcast the user's profile, age, identity, pronouns, preferences, encounter intent, or exact location.
- **Profiles are requested one-to-one.** A BitNow profile is sent only through the private messaging transport after a profile request.
- **No advertising or analytics SDK.** The current app does not include advertising, behavioral analytics, or tracking SDKs.
- **No sale of data.** The project does not sell user data or build advertising profiles.
- **Open source.** The relevant storage, networking, encounter, and cryptographic behavior can be inspected in the source code.

## Information You Choose to Store on Your Device

### 1. BitNow encounter profile

BitNow can store the profile information you enter, including:

- self-attested age;
- whether your exact age is shown or only `18+` is shared;
- identity selection;
- optional pronouns;
- headline;
- about, boundaries, or vibe text;
- primary encounter intent;
- identities you indicate you are open to meeting; and
- your current local discovery-filter settings.

These profile and preference values are stored locally on your device so the app can restore your settings. They are not uploaded to a BitNow-operated profile server.

The current profile field limits are deliberately bounded: headline up to 80 characters, about/boundaries up to 280 characters, and pronouns up to 24 characters.

### 2. Encounter availability

BitNow stores whether you have enabled encounter visibility and the expiry time of the current visibility window. Visibility defaults to off. If a stored window has expired, BitNow removes the encounter-availability advertisement rather than silently extending it.

The radio-layer capability check independently verifies the expiry deadline, so suspending the app does not turn a short visibility window into permanent encounter advertising.

### 3. Interest signals and match state

An outgoing BitNow interest signal is stored locally for the active encounter flow and expires after approximately 45 minutes. A mutual fresh signal can be shown as a match. Going invisible or allowing an availability window to expire clears active outgoing encounter signals.

### 4. Identity and cryptographic material

The underlying transport generates cryptographic identity, Noise, signing, group, prekey, and optional Nostr material locally. Secret keys are stored using operating-system protected storage such as the system keychain where supported. Public-key material is shared when required for secure messaging, verification, groups, relay transport, or protocol operation.

Underlying BitChat/Noise identity material can persist across sessions. **BitNow does not claim that your radio identity is anonymous or unlinkable across encounters.** A nearby observer or peer may be able to correlate protocol identifiers or other radio/network metadata over time.

### 5. Private messages and queued delivery

Private messages can remain locally in conversation state or bounded delivery queues according to the underlying BitChat transport behavior. An outgoing private message that has not yet been acknowledged may remain in an encrypted outbox for a bounded period. Devices participating in courier/store-and-forward operation can carry opaque end-to-end encrypted envelopes for other users without being able to read their plaintext.

### 6. Media and optional BitChat features

The encrypted chat layer includes existing BitChat functionality such as images, voice notes, groups, public mesh features, optional location channels, bridge/gateway features, and optional internet relay transport. If you use those features, their local storage and network behavior also applies. Media can remain in protected application storage while referenced by the app and is subject to the underlying bounded retention and cleanup behavior.

BitNow v1 does **not** yet define a separate BitNow profile-photo transport. A normal encrypted chat attachment is not the same thing as a BitNow profile image.

## What Nearby People Can Learn

When BitNow encounter visibility is active, compatible nearby peers can learn that your protocol identity currently advertises the BitNow capability. That flag means only that encounter discovery is available.

The BitNow capability does **not** itself reveal:

- your exact age;
- your identity or pronouns;
- who you are interested in meeting;
- your current encounter intent;
- your headline or about text; or
- exact latitude or longitude.

After another BitNow user requests your profile, the profile fields you intentionally share are sent to that peer through the private encrypted transport. If you hide your age, the shared profile represents it as `18+` instead of sending the exact age for display.

When you send an interest signal, the signal can include the intentionally shared profile snapshot needed to give the recipient context for that signal.

## Proximity and Radio Metadata

BitNow discovery is based on local transport reachability rather than a public map of exact coordinates. The user interface uses coarse states such as `HERE NOW` and `NEARBY RECENTLY` rather than exposing continuous precise distance.

This design does not eliminate radio metadata. Bluetooth peers, operating systems, network infrastructure, or third-party observers may be able to observe information such as:

- Bluetooth signal strength;
- protocol identifiers;
- connection timing;
- packet timing and size; and
- network addresses or relay connection metadata when internet transport is used.

Signal strength is not a precise measurement of physical distance and can vary substantially with walls, devices, bodies, antennas, and the environment.

## Private Profile Requests and Control Messages

BitNow profile requests, profile responses, and encounter signals use a versioned, size-bounded BitNow control envelope carried through the existing encrypted private-message delivery path. Malformed, oversized, unsupported, or semantically invalid BitNow control envelopes are rejected by the BitNow decoder.

In the current v1 protocol, these control envelopes use the same encrypted private-message pipeline as ordinary direct messages. They therefore can exist in the local private-message history even when BitNow presents them as encounter controls rather than normal conversation content. A dedicated typed private-control transport is planned as a protocol hardening improvement.

## Blocking

BitNow provides local blocking using the existing private-conversation block controls. A blocked peer is excluded from BitNow discovery and from automatic profile-request responses on that device.

Blocking on your device does not erase information that another person already received, copied, photographed, exported, or stored on another device.

The current release does not operate a centralized moderation/reporting database. Local blocking should not be described as a centralized ban or platform-wide removal.

## Optional Internet and Nostr Relay Features

Some underlying BitChat features can use public or user-selected Nostr relays or gateway/bridge functions. These are optional and are not required to operate a centralized BitNow profile service.

If you use internet-backed transport, third-party relays or gateways may observe metadata such as event timing, size, recipient tags, public keys used by the relevant protocol, IP/network information, or coarse geohash information for location-channel features. Relays are operated by third parties and their retention, logging, availability, and privacy practices are outside BitNow's control.

Encrypted relay content may still remain on third-party infrastructure according to the relay operator's policy even after it is no longer visible in the app.

## Location Services

BitNow encounter discovery itself does not require publishing an exact GPS location to other encounter users.

The inherited BitChat application also contains optional location-channel and place-label functionality. If you deliberately use those features and grant location permission, the app may process device location locally to derive coarse geohash/channel information or request a friendly place label from operating-system services. Exact latitude and longitude are not intentionally included in BitNow encounter profile or signal payloads.

A geohash or coarse location channel is still location information: finer geohash precision can describe a smaller geographic area.

## Microphone, Camera, Photos, and Bluetooth

Depending on the feature you use:

- **Bluetooth** is used for local peer discovery and mesh transport.
- **Microphone** access is used for voice-note or live-audio features when you activate those controls.
- **Camera** access can be used by existing peer-verification QR functionality.
- **Photo-library/media access** is used when you choose media to send.
- **Location** is used only by optional functionality that requests it, such as inherited location-channel/place-label features.

BitNow does not need to continuously record microphone or camera input for encounter discovery.

## Cryptography

The underlying transport uses different protections for different features, including Noise-based private mesh sessions and authenticated/encrypted private-message formats. Optional Nostr-backed transport uses its own signing, key-agreement, and encrypted-envelope mechanisms.

Cryptography protects data in transit only within its threat model. It cannot prevent a recipient from reading, copying, screenshotting, photographing, exporting, or redistributing information after receiving it. It also does not make Bluetooth or network metadata invisible.

## Retention

BitNow-specific encounter state is intentionally short-lived where possible:

- **Encounter availability:** until the selected 30-minute, 1-hour, 2-hour, or 4-hour window expires, or until you stop availability sooner.
- **Active outgoing encounter signals:** approximately 45 minutes, and cleared when availability is stopped or expires.
- **Profile and discovery preferences:** stored locally until changed, reset, app data is removed, or the relevant privacy/purge control clears them.
- **Underlying encrypted message/outbox/courier/media/public stores:** subject to the bounded retention behavior of the BitChat transport and the specific feature used.
- **Third-party relay data:** subject to the relay operator's own retention policy and may not be recallable after publication.

## Your Controls

BitNow provides or inherits controls that can reduce retained or shared information:

- keep encounter visibility off unless you actively want to be discoverable;
- choose a short availability window;
- stop availability early;
- hide exact age so the shared profile shows `18+`;
- use local discovery filters;
- block a peer;
- clear active encounter state using BitNow's privacy/reset controls;
- clear conversations or use inherited BitChat privacy/panic-wipe controls where available;
- revoke Bluetooth, location, microphone, camera, or photo access through operating-system settings; and
- disable optional internet/location/bridge features you do not want to use.

Some information already delivered to another device or published to a third-party relay cannot be remotely recalled.

## What BitNow Does Not Do

The current BitNow release does not:

- operate a centralized BitNow account or dating-profile database;
- sell user data;
- include advertising or behavioral-tracking SDKs;
- broadcast your full encounter profile in the BitNow availability capability;
- intentionally publish exact GPS coordinates in BitNow profile or signal payloads;
- provide a permanent encounter-visible mode;
- claim that a signal or match constitutes consent;
- claim that the underlying Bluetooth/protocol identity is unlinkable;
- provide centralized moderation/reporting; or
- provide external identity or age verification in v1.

## Safety, Consent, and Sensitive Information

BitNow can involve sensitive personal information, including sexual or relationship preferences, identity information, age, and encounter intent. Share only information you are comfortable providing to another adult.

A profile, signal, match, message, prior interaction, or physical proximity does not establish consent. Consent must be specific, voluntary, informed, ongoing, and can be withdrawn.

## Children's Privacy

BitNow is an adults-only product and is not intended for children or anyone under 18. The current release does not use a third-party age-verification service, so the age gate depends on the user's attestation. If BitNow becomes aware through a future project-operated reporting or account system that it holds information relating to a minor, the applicable removal and legal process will be documented for that system.

## No Sale or Advertising Profile

The project does not sell BitNow user data, rent encounter profiles to advertisers, or build behavioral advertising profiles. The current app does not include an advertising SDK.

## Changes to This Policy

Material changes to BitNow's data handling will be reflected in this policy and its `Last updated` date. A policy update cannot retroactively retrieve information that remained only on a user's device or recall information already received by another peer or third-party relay.

## Contact and Source

BitNow is currently developed in the public source repository at:

- `https://github.com/thotsl4yer69/bitchat`

Privacy and security issues can be raised through the repository's issue/security channels while a dedicated BitNow support contact is being established for public release.

---

This document describes the current application's implemented behavior. Store-specific disclosures and legally required notices must remain consistent with the shipping binary and any later backend, analytics, moderation, verification, payment, or account features that are added.
