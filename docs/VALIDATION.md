# Validation and compatibility

## Evidence and unresolved checks

Implementation follows [WOW_API_RESOURCES.md](WOW_API_RESOURCES.md).
No installed Forever client was available to the agent during development.
The user reported that the initial addon was listed as incompatible before
character login. Its TOC still contained Interface: 0. This has been replaced
with 16001 from wowlua 0.13.11's camelot flavor table dated 2026-10-29, also
recorded in wowlua.lock. The user confirmed successful in-game loading and a
visible window on 2026-11-11, then confirmed the original core functions work.
The new refinements (combat inviting, five-second departure, editable message,
and native frame styling) still need in-game validation, as does the user's
installed GetBuildInfo() result.

The supplied Warcraft Wiki pages returned HTTP 403 to direct access. Search
results for its InviteUnit page list Forever 1.60.1 and the name argument;
this is reference evidence, not a client test:
https://warcraft.wiki.gg/wiki/API:C_PartyInfo.InviteUnit

Gethe's [branch listing](https://github.com/Gethe/wow-ui-source/branches)
was inspected, but a matching Forever source branch was not established.
Do not treat the Retail live branch as proof of Forever behavior.

The implementation checks the existence of `C_PartyInfo.InviteUnit` and
`C_PartyInfo.LeaveParty` at action time. Chat prefers
`C_ChatInfo.SendChatMessage` and falls back to `SendChatMessage`. This does not
establish the calls' signatures or permissions. Consult the installed shipped
UI and these supplied references:

- https://warcraft.wiki.gg/wiki/Category:API_systems/PartyInfo
- https://warcraft.wiki.gg/wiki/API:SendChatMessage
- https://warcraft.wiki.gg/wiki/Handling_events
- https://warcraft.wiki.gg/wiki/Viewing_Blizzard%27s_interface_code

Declines and already-in-a-group responses are matched against the client's
localized ERR_DECLINE_GROUP_S and ERR_ALREADY_IN_GROUP_S formats and the latest
invited name. Other system text is ignored by the addon window. UI error/info handlers
accept `(id, message)` and single-message forms. Actual event delivery still
needs client confirmation.

The user reported missing decline feedback on 2026-11-11. Two code paths could
discard it: the old 30-second expiry and clearing on any roster update. The
attempt now remains for 120 seconds across roster/group-left events; no accepted
invitation is inferred. Local cached Forever strings confirm both format globals,
and SystemDocumentation.lua defines UI_INFO_MESSAGE as `(errorType, message)`.
Recognized results remain visible instead of being replaced by generic errors.
Unit checks cover both failure types, delay, roster/group-left ordering, all
three message channels, hyperlinks/color codes, realm names, target changes,
localized positional formats, expiry and latest-attempt-only behavior.
The user clarified that the application restart/cache issue concerned this chat,
not the addon. They separately reported unrelated loot-setting text in the addon.
The generic message fallback has been removed; idle status is "Ready to invite."
Regression checks verify unrelated text cannot overwrite idle, pending-invite,
or recognized failure statuses. Original game chat and errors are untouched.

## Automated behavior checks

Follow-up tooling (2026-11-11): downloaded the official portable Windows
wowlua 0.13.11 release and verified it against the published SHA-256 checksum.
`wowlua check --offline --flavor camelot` passed for the plain Lua addon, and a
camelot development build was generated successfully. This is a tool check,
not proof that every guarded API call works in the actual client.

`tests/Forever.test.wowlua` exercises startup, window creation, slash commands,
and minimap toggling after slash/close controls with the tool's Forever emulator.
It requires Blizzard UI definitions
(`test.blizzard-ui`); the bare emulator lacks the named game font templates.
The tests passed with Blizzard UI definitions loaded on 2026-11-11: 6 passed,
0 failed, 0 skipped. See docs/DEBUGGING.md for running it and collecting actual
client errors. No addon code changes were needed to resolve the bare emulator's
missing-font error. The third test checks saving and validating custom messages
in the native settings UI. The current native frame and settings widgets load
without emulator errors.

`tests/QuickParty_spec.lua` loads the actual addon with mock frames and APIs.
It exercises invalid targets, realm-qualified invitations, click-only actions,
feedback expiry, error payload variants, group restrictions, missing APIs,
chat-before-leave ordering, visibility persistence, and position recovery.
The expanded suite also passed on 2026-11-11: invites during combat; no departure
before five seconds; cancellation without repeat chat; GROUP_LEFT before a
new party; raid/instance checks at timer expiry; missing timer API;
hidden-window departure; custom-message validation, persistence and defaults.
The user subsequently reported that leaving failed in combat. The addon had
explicit guards both on click and at timer expiry; both were removed at the
user's request. Lua checks now cover sending/leaving while already in combat,
entering combat during the wait, and cancelling during combat.
`tests/CombatLeave.test.wowlua` observes calls through to the native emulator
LeaveParty API and checks five-second timing in both combat cases. These two
tests do not assert server membership changes: an initial membership assertion
did not converge in the emulator, so actual departure and chat delivery remain
in-game checks. Cached Forever LeaveParty documentation does not mark the call
protected or restricted to hardware events. No confirmation bypass was added.

## Refinement evidence (2026-11-11)

The local wowlua UI cache identifies its source as client 1.60.1.70888, source
revision `4cd0ab752a77`. In its generated `PartyInfoDocumentation.lua`,
InviteUnit has no protected-call restriction and accepts a target name.
LeaveParty accepts an optional category and describes leaving the party,
including possible native confirmation. Neither definition marks the API as
requiring a hardware event. The implementation retains native confirmation,
does not call ConfirmLeaveParty, and never uninvites group members.

`Blizzard_UIPanelTemplates/Mainline/UIPanelTemplates.xml` in that cache provides
BasicFrameTemplateWithInset, its TitleText and CloseButton, rock/marble
backgrounds and native borders. The emulator loads that template for this
addon. Actual appearance should still be inspected in the game.

Only the player leaves. Remaining groups with two or more members can continue;
leadership belongs to the game. A two-player party loses its only partnership
when one player leaves. Verify leader departure with three or more players in
Forever to confirm server behavior; do not promise to preserve a solo party.

Mocks cannot verify protected functions, chat arrival, UI appearance, or event
availability. The runner is a developer tool, never an addon dependency.

Development result (2026-11-11): the behavior suite passed using
`fengari-node-cli` 0.1.0 (Lua 5.3 semantics) on Node 20.20.2. A native Lua 5.1
interpreter was unavailable. The addon uses Lua 5.1-compatible syntax, but
native 5.1 execution and all client checks remain outstanding. The local runner
is installed under ignored `.tools/`; it is not included in the addon folder.

## Required in-game checklist

Record the build, date, actual results, and any Lua error text for each check.
The user has confirmed loading and the original core workflow. The detailed
edge cases and new refinements below remain **not run** in the actual client.

1. Run `/dump GetBuildInfo()`, record all results, and configure the TOC interface
   value. Confirm clean load with `/console scriptErrors 1` and `/reload`.
2. Inspect the shipped UI and `/dump` the chosen invite, leave, and chat functions.
   Confirm exact signatures and whether leave needs a client confirmation flow.
3. Click Invite with no target, NPC, yourself, hostile player, friendly player,
   existing member, full group, and a target on another realm. Confirm only the
   selected player is invited, once per click. Change targets afterward to check
   that no further action occurs.
4. Use `/etrace` while an invite fails, is declined, and is accepted. Record
   `CHAT_MSG_SYSTEM`, `UI_ERROR_MESSAGE`, and roster payloads. Confirm feedback is
   visible, original chat remains, and no text claims acceptance.
   Specifically test a decline after more than 30 seconds and a target already
   in another group. Confirm the explicit result in Quick Party survives an
   unrelated error. Repeat in the client's language and with a realm-qualified
   name. These new failure-feedback cases are pending in-game verification.
5. Test Thank & Leave while solo, in a normal party, in a raid, in an instance
   group, and while belonging to both a home and instance group. Only an ordinary
   party should send thanks and request departure.
6. With a second player, confirm the configured party message arrives, the
   sender stays for five seconds, and Cancel Leave cancels without resending.
   Repeat after closing the window, reloading, and leaving/joining another party.
   With at least three players, confirm that the remaining members stay grouped
   when the leader leaves. Observe native confirmation where applicable.
7. Test both Invite and Thank & Leave during combat while fighting a shared
   elite. Thank & Leave should send once and depart after five seconds. Also
   start combat during the delay and verify departure still occurs. Confirm
   Cancel Leave works in combat. Never bypass game restrictions.
8. Drag to screen edges, close/reopen with `/qp`, reload while hidden and shown,
   change resolution/UI scale, and run `/qp reset`. Check text and saved position.
9. Confirm SavedVariables contains only visibility, window position, minimap
   icon angle and the message.
10. Left-click the minimap icon to hide/show the window, then repeat after using
    the close button and `/qp hide`. Reload while hidden and confirm the icon
    can reopen the window. Check the hover tooltip and icon placement in-game.
    Drag the icon around the rim, release without toggling the window, then
    click normally. Reload and check the saved position, including at a changed
    UI scale. Automated Lua checks cover scaled cursor coordinates, stopping
    updates after dragging, click behavior, saved angle and invalid preferences.
11. Edit/save the message, reload and send it. Check defaults and rejection of
    blank input, links/control characters and text beyond 255 bytes (including
    multibyte text). Check native frame styling and settings at your UI scale.
