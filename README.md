# Quick Party

[Changelog](changelog.md) · [Roadmap](roadmap.md)

Licensed under the [MIT License](LICENSE).

A small Lua addon for **World of Warcraft: Forever**. Select a friendly player
and click **Invite Player**, or click **Thank & Leave** to send
your thank-you message to your party and leave five seconds later.

## Download and install

1. Download the [QuickParty folder](QuickParty). If you download the whole
   repository using **Code > Download ZIP**, extract the ZIP first.
2. Copy only the `QuickParty` folder into your **WoW Forever** client's
   `Interface/AddOns/` folder. You do not need the repository's docs, tests,
   or development tools.
3. Check that the files are directly inside the addon folder:

   ```text
   Interface/
     AddOns/
       QuickParty/
         QuickParty.toc
         QuickParty.lua
   ```

4. Start or restart WoW Forever. At character selection, open **AddOns** and
   enable **Quick Party**, then enter the game.

No build step or extra libraries are needed. To update, replace the installed
`QuickParty` folder with the latest copy and run `/reload` in-game. Restart the
game if the addon list does not refresh.

## How to use

1. **Open the window:** left-click the Quick Party minimap icon or type `/qp`.
2. **Invite a player:** select a friendly player as your target, then click
   **Invite Player**. This also works during combat. The window shows the invite
   attempt and recognized decline or already-in-a-group responses.
3. **Thank your party and leave:** click **Thank & Leave**, in or out of combat.
   Your message is sent to party chat, then you leave after five seconds.
   Click **Cancel Leave** during the wait if you want to stay. Closing the
   window does not cancel leaving.
4. **Customize your message:** click **Settings**, edit the text, and click
   **Save Message**. **Use Default** restores "Thanks for the party! Take care!"
   Messages must be nonempty plain text of at most 255 bytes.

Drag the window to reposition it. Close it with its X button or the minimap
icon. Left-drag the minimap icon to move it around the minimap rim. Window
position, visibility, icon position, and your saved message persist across sessions.

| Command | Action |
| --- | --- |
| `/qp` or `/quickparty` | Open or close the window |
| `/qp show` | Show the window |
| `/qp hide` | Hide the window |
| `/qp reset` | Return the window to the center of the screen and show it |

Invites are manual and target-only. The addon never scans, sends automatic
greetings, or stores player/group history. Inviting is allowed during combat.
Thank & Leave also works during combat; raids and instance groups are
refused for that action. Normal same-faction parties are the
initial supported workflow; the friendly-target check may reject cross-faction
targets even where the client would otherwise allow invitations.

If the addon is missing from the list, check the folder layout above and that
you copied it into the Forever client. For compatibility issues or Lua errors,
see the [debugging guide](docs/DEBUGGING.md).

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
Departure also cancels if the group becomes unsupported. Combat does not cancel
the pending departure. A reload discards the pending timer.

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
