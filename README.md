# Quick Party

[Changelog](changelog.md) · [Roadmap](roadmap.md)

A small Lua addon for **World of Warcraft: Forever**. Select a friendly player
and click **Invite Player**, or click **Thank & Leave** to send
your thank-you message to your party and leave five seconds later.

The window can be dragged and closed. `/qp` or `/quickparty` toggles it;
`/qp show`, `/qp hide`, and `/qp reset` control visibility and position.
Left-click the Quick Party icon at the upper-left edge of the minimap to open
or close the window, including after closing it with its X button.
Drag the minimap icon with the left mouse button to move it around the rim.
Its position is saved across reloads.
Click **Settings** to edit the party message, then **Save Message**. The default
is "Thanks for the party! Take care!"; **Use Default** restores it. Messages
must be nonempty plain text of at most 255 bytes. Position, visibility and the
message are saved, along with the minimap icon position.

Invites are manual and target-only. The addon never scans, sends automatic
greetings, or stores player/group history. Inviting is allowed during combat.
Thank & Leave requires being out of combat; raids and instance groups are
refused for that action. Normal same-faction parties are the
initial supported workflow; the friendly-target check may reject cross-faction
targets even where the client would otherwise allow invitations.

## Install and configure

1. The manifest now uses `## Interface: 16001`, taken from wowlua 0.13.11's
   Forever (`camelot`) flavor table dated 2026-10-29. This replaces the original
   `0` placeholder that caused the addon to be marked incompatible.
2. If your client still marks it incompatible, log into a character and run
   `/dump GetBuildInfo()`. Compare the fourth return value with the manifest;
   your installed client is authoritative after patches.
3. Copy the entire `QuickParty` folder into your client's
   `Interface/AddOns/` directory. The resulting path must be
   `Interface/AddOns/QuickParty/QuickParty.toc`.
4. Enable Quick Party in the addon list, then log in or `/reload`.
5. Enable `/console scriptErrors 1` and complete [client validation](docs/VALIDATION.md).

There are no runtime libraries or external services. In-game loading and the
original invite/leave actions have been confirmed by the user. Combat inviting,
delayed departure, custom messages and the new styling still need testing on
your installed build.

## Feedback and limitations

An invite click reports a **request attempted**, never acceptance. For two minutes
after the latest attempt, the window listens for system, UI error and UI info
messages. It recognizes the client's localized decline and already-in-a-group
messages for that player, and keeps that result visible until another action.
Roster changes do not end this feedback window. Only the latest invited name
is held temporarily; there is no history. The idle status is **Ready to invite**.
Unrecognized game messages, such as loot-setting changes, are ignored by this
window and do not overwrite its status. A new invite replaces the previous attempt.
Original game chat and errors remain visible. Long messages may be clipped by
the compact window; read the original chat/error display for complete text.

Thank & Leave sends the message once, then waits five seconds before requesting
departure. Click **Cancel Leave** during that time to stay; the already-sent
message is not recalled. Closing the window does not cancel the timer. Leaving
the party cancels it, so joining a new group cannot carry over an old timer.
Departure also cancels if the group becomes unsupported, or you are in combat
at the end of the wait. A reload discards the pending timer.

The addon calls `C_PartyInfo.LeaveParty()` only; it does not kick members or
disband them. A party with at least two remaining members can continue, with
leadership handled by the game. A two-person party cannot remain a multi-player
party once one player leaves. Native leave confirmations are respected. The
delay gives chat time to arrive but cannot guarantee delivery by the server.

## Development

Read [the resource list](docs/WOW_API_RESOURCES.md),
[project instructions](docs/AGENTS.md), and [validation notes](docs/VALIDATION.md).
The supplied vision/scope and user-story files were empty at implementation
time; behavior was derived from the resource document's explicit purpose and
implementation guidance.

Run behavioral tests from the repository root with Lua 5.1 or a compatible Lua:

```text
lua tests/QuickParty_spec.lua
```

The tests mock WoW's environment. They check Lua behavior and action ordering,
but cannot establish client compatibility or protected-call permissions.

Optional [wowlua tooling](https://wowlua.dev/docs/guide/install) is configured in
`wowlua.json` for **camelot only**, the tool's name for Forever. The addon source
remains plain Lua. `wowlua.lock` records the tool's interface metadata.

```text
wowlua check --flavor camelot --offline
wowlua test --flavor camelot
wowlua build --flavor camelot
```

The startup test loads Blizzard UI definitions, downloading them on its first
run when no client is available. Dev builds go to `dist/dev/QuickParty` and
include wowlua's `/wl` diagnostics. For ordinary installation, keep using the
small dependency-free `QuickParty` source folder. See
[debugging instructions](docs/DEBUGGING.md) for local tool paths and game checks.
