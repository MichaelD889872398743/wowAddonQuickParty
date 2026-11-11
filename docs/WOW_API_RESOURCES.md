# Quick Party — WoW Addon API Resources

## Purpose
Reference document for Codex implementing **Quick Party**, a minimal addon targeting **World of Warcraft: Forever**. The addon has a small movable window with two user-initiated buttons: **Invite Player** (currently selected player only) and **Thank & Leave** (send a party message, then leave). It displays available invite failures/declines. No mouseover, proximity scanning, quest matching, automatic invites, group history, or automatic greetings.

## Source priority and version compatibility
1. Confirm behavior in the installed **WoW Forever** client and its shipped UI code.
2. Use Warcraft Wiki API pages, checking the **Game Types / Forever** compatibility entry and version.
3. Use the matching branch/version of Blizzard UI source, not an arbitrary Retail implementation.
4. Use third-party guides for background, not as proof of Forever-specific behavior.

**Do not assume** a Retail API, event payload, or `## Interface` number is correct for Forever. Retrieve the current client TOC/interface number with `GetBuildInfo()` or inspect installed addon manifests. Confirm function existence and permitted calls in-game. Treat an invitation request as *attempted*, not *accepted*.

## Core documentation

| Resource | URL | Purpose |
|---|---|---|
| Warcraft Wiki — interface customization hub | https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization | Central index for API, widgets, events, Lua and addon topics |
| Warcraft Wiki — WoW API | https://warcraft.wiki.gg/wiki/World_of_Warcraft_API | Main API reference |
| Warcraft Wiki — Addon tutorial | https://warcraft.wiki.gg/wiki/AddOn_programming_tutorial/Introduction | TOC, Lua, first addon, testing |
| Warcraft Wiki — Handling events | https://warcraft.wiki.gg/wiki/Handling_events | `CreateFrame`, `RegisterEvent`, `SetScript` |
| Warcraft Wiki — AddOn loading | https://warcraft.wiki.gg/wiki/AddOn_loading_process | Load order, `ADDON_LOADED` |
| Warcraft Wiki — Saved variables | https://warcraft.wiki.gg/wiki/Saved_variables | Persist only window position/visibility if needed |
| Warcraft Wiki — XML | https://warcraft.wiki.gg/wiki/XML | Optional XML UI; Lua-only UI is sufficient |
| Warcraft Wiki — Viewing Blizzard interface code | https://warcraft.wiki.gg/wiki/Viewing_Blizzard%27s_interface_code | How to inspect UI implementation |
| Gethe's WoW UI source mirror | https://github.com/Gethe/wow-ui-source | Search Blizzard UI implementation; select matching branch |
| WoW Addon Development Guide — resources | https://www.better-addons.com/resources/ | Supplementary learning and reference links |

## APIs relevant to Quick Party

| Function / concept | Documentation | Intended use / checks |
|---|---|---|
| `C_PartyInfo.InviteUnit(name)` | https://warcraft.wiki.gg/wiki/API:C_PartyInfo.InviteUnit | Invite the **selected** player's name, on explicit click; listed as Forever-compatible |
| PartyInfo API system | https://warcraft.wiki.gg/wiki/Category:API_systems/PartyInfo | Locate leave-party and invite-related functions/events; verify exact signatures |
| `C_ChatInfo.SendChatMessage` / `SendChatMessage` | https://warcraft.wiki.gg/wiki/API:SendChatMessage | Send a predefined `PARTY` message before leaving; verify correct namespace in Forever |
| `UnitExists`, `UnitIsPlayer`, `UnitName`, `UnitCanCooperate` / faction checks | https://warcraft.wiki.gg/wiki/World_of_Warcraft_API | Validate `target`; verify available functions and limitations before using |
| `CreateFrame`, button widget and frame scripts | https://warcraft.wiki.gg/wiki/Handling_events | Create small movable window and click handlers |
| `CHAT_MSG_SYSTEM`, `UI_ERROR_MESSAGE` | https://warcraft.wiki.gg/wiki/Handling_events | Investigate invitation decline/error notifications; inspect real payloads in-game |
| `GROUP_ROSTER_UPDATE` | https://warcraft.wiki.gg/wiki/Handling_events | Optional current group-state validation; no history or tracking |
| `ADDON_LOADED` | https://warcraft.wiki.gg/wiki/AddOn_loading_process | Initialize UI preferences if saved variables are used |

**Important:** The generic API index is a starting point, not proof that every named function is available in Forever. For the actual implementation, locate the exact per-function pages and verify the installed client.

## Implementation guidance for Codex

**User-authorized refinements (2026-11-11):** manual invites must work during
combat; Thank & Leave sends a configurable saved message, then waits five
seconds before leaving. Provide cancellation, cancel stale departures on
GROUP_LEFT, and use native frame styling. These instructions supersede the
original predefined-message, window-only settings, and delay guidance below.
Do not uninvite other members to leave. Thank & Leave remains out of combat.

- Write minimal Lua and a matching `.toc` manifest; no external runtime, network requests or dependencies.
- Create the UI with native WoW widgets, preferably entirely in Lua unless XML adds clear value.
- Invite **only** `target`, not `mouseover`. Do not automatically choose targets or issue invites.
- On Invite click: validate that the selected unit exists, is a player and is a plausible invite target; call the supported invite API; show *request attempted* rather than *invitation accepted*.
- Listen for relevant system/error events and surface supported failure text in the window **without suppressing original chat**. Do not assume all failures expose a unique structured event or that every system message belongs to this addon's invite.
- On Thank & Leave click: verify the player is in a party, send the predefined message, then call the verified leave-party API. Test whether the message arrives before departure; add timing only if tests demonstrate a problem.
- Keep the window compact, movable, and hideable. Save only optional window preferences.
- Avoid unnecessary state, background polling, invitation history, quest checks, and automatic group management.
- Respect protected-function, combat and hardware-event restrictions. Never bypass them.

## In-game verification checklist

1. Inspect `GetBuildInfo()` and the correct TOC `## Interface` value.
2. Enable Lua errors: `/console scriptErrors 1`; reload with `/reload`.
3. Use `/etrace` to inspect actual events when an invite is declined, fails, or is accepted.
4. Use `/dump` and the shipped UI source to verify available APIs and signatures.
5. Test: no target, NPC target, friendly player, invalid invite, decline, successful join, not in group, and Thank & Leave.
6. Check that party chat arrives before leaving and that original game errors remain visible.
7. Test in and out of combat for restrictions.

## Additional Forever tooling

- [wowlua](https://wowlua.dev/) provides an optional checker, builder and client
  emulator. Its Forever flavor is `camelot` (alias `forever`).
- [Manifest reference](https://wowlua.dev/docs/reference/manifest) describes
  flavor/interface pinning. Version 0.13.11 supplies interface 16001 for camelot
  in its flavor table dated 2026-10-29; see the repository's wowlua.lock.
- [Testing guide](https://wowlua.dev/docs/guide/testing) and
  [debugging guide](https://wowlua.dev/docs/guide/debugging) describe optional
  developer diagnostics. Emulator behavior is not proof of server behavior.
- Keep the installed client's build and shipped UI as the source of truth.

## Open technical questions (do not invent answers)

- Exact Forever leave-party API and any required confirmation behavior.
- Which events/system messages distinguish invitation decline from other group errors.
- Whether invitation failures can be reliably attributed to the last manually invited target without keeping history.
- Whether sequential chat-send then leave reliably delivers the message in Forever.
- Current Forever TOC interface number and exact supported chat API alias.

Codex should resolve these from the matching client/API documentation and actual in-game tests, documenting the observed results.
