# Quick Party development instructions

- Before changing code, read root README.md and docs/WOW_API_RESOURCES.md,
  docs/VISION_AND_SCOPE.md, docs/USER_STORIES.md, and docs/VALIDATION.md.
  If a document is empty, say so; do not invent approved requirements.
- Keep the addon minimal, dependency-free, and compatible with the installed
  WoW Forever client. Use Lua 5.1-compatible syntax and native WoW widgets.
- Check API names, signatures, event payloads, protected-call rules, and TOC
  versions against the installed client's shipped UI first, then the supplied
  references. Retail code alone is not evidence of Forever compatibility.
- Never guess an interface number or claim client testing that did not happen.
  The checked-in Interface: 16001 comes from wowlua 0.13.11's camelot flavor
  table (2026-10-29), recorded in wowlua.lock. The installed client's
  GetBuildInfo() result remains authoritative. Keep the plain TOC and tool
  metadata consistent when updating them.
- Invites and thank/leave actions must originate from explicit button clicks.
  Invite only the selected target. No mouseover, scanning, automation, history,
  quest matching, automatic greetings, or protected-function workarounds.
- Do not label an attempted invitation as accepted. Do not attribute generic
  system/error text to an invitation with certainty or suppress original chat.
  Show only recognized invite responses in the addon, not unrelated game chat
  such as loot settings. The idle status is "Ready to invite."
- Save only window position, visibility, minimap icon angle, and the customized thank-you message.
  Keep temporary state in memory. The user authorized message settings and a
  five-second delayed leave on 2026-11-11, extending the original resource scope.
- Allow manual invitations during combat. Keep Thank & Leave out of combat;
  recheck at timer expiry. A delayed departure must be cancellable, send chat
  once, and never carry over after GROUP_LEFT into a newly joined party. Call
  LeaveParty only, never uninvite other members or bypass native confirmation.
- For behavioral changes, run tests/QuickParty_spec.lua using Lua 5.1 or a
  compatible interpreter. Review nil handling, truthiness, varargs, Lua patterns,
  globals, and colon-versus-dot calls carefully. Mocks cannot verify WoW APIs.
- Complete the manual client checklist in docs/VALIDATION.md before claiming
  release readiness. Record actual observations and client build information.
- The optional wowlua tool uses camelot (alias forever), never standard/retail.
  Run wowlua check and the Forever startup test when changing client integration.
  Keep tool binaries and caches under ignored .tools; do not migrate plain Lua
  source or install tooling globally without a reason. Read docs/DEBUGGING.md.
