-- Run from repository root: lua tests/QuickParty_spec.lua
local frames, calls, state
local function equal(actual, expected, label)
    assert(actual == expected, (label or "value") .. ": expected " ..
        tostring(expected) .. ", got " .. tostring(actual))
end
local function contains(actual, expected)
    assert(actual:find(expected, 1, true), actual .. " does not contain " .. expected)
end
local function widget()
    local w = { scripts = {}, events = {}, shown = true }
    for _, method in ipairs({"SetSize", "SetClampedToScreen", "SetMovable",
        "EnableMouse", "RegisterForDrag", "StartMoving", "StopMovingOrSizing",
        "SetAllPoints", "SetColorTexture", "SetJustifyH", "SetJustifyV",
        "SetFrameStrata", "SetFrameLevel", "RegisterForClicks",
        "SetHighlightTexture", "SetTexture", "SetAutoFocus", "SetMaxBytes", "ClearFocus"}) do
        w[method] = function() end
    end
    function w:SetScript(event, fn) self.scripts[event] = fn end
    function w:GetFrameLevel() return 1 end
    function w:GetWidth() return 160 end
    function w:GetHeight() return 160 end
    function w:GetCenter() return 100, 100 end
    function w:GetEffectiveScale() return 0.5 end
    function w:RegisterEvent(event) self.events[event] = true end
    function w:UnregisterEvent(event) self.events[event] = nil end
    function w:SetPoint(...) self.point = {...} end
    function w:GetPoint() return (unpack or table.unpack)(self.point) end
    function w:ClearAllPoints() self.point = nil end
    function w:SetText(text) self.text = text end
    function w:GetText() return self.text end
    function w:IsShown() return self.shown end
    function w:Show()
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function w:Hide()
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function w:CreateTexture() return widget() end
    function w:CreateFontString()
        local font = widget()
        self.lastFont = font
        return font
    end
    return w
end
local function setup(db)
    frames, calls = {}, {}
    state = { exists = true, player = true, friendly = true, name = "Friend", now = 1 }
    QuickPartyDB = db
    UIParent = widget()
    Minimap = widget()
    GameTooltip = { Hide = function() end }
    function GetCursorPosition() return state.cursorX or 50, state.cursorY or 50 end
    SlashCmdList = {}
    ERR_DECLINE_GROUP_S = "%s declines your group invitation."
    ERR_ALREADY_IN_GROUP_S = "%s is already in a group."
    LE_PARTY_CATEGORY_INSTANCE = 2
    function CreateFrame(_, name, parent, template)
        local w = widget()
        if template == "BasicFrameTemplateWithInset" then
            w.TitleText, w.CloseButton = widget(), widget()
        end
        w.name, w.parent = name, parent
        frames[#frames + 1] = w
        if name then _G[name] = w end
        return w
    end
    function UnitExists(unit) equal(unit, "target"); return state.exists end
    function UnitIsPlayer(unit) equal(unit, "target"); return state.player end
    function UnitIsUnit(a, b) equal(a, "target"); equal(b, "player"); return state.self end
    function UnitInParty() return state.member end
    function UnitInRaid() return state.raidMember end
    function UnitCanCooperate() return state.friendly end
    function UnitName(unit) equal(unit, "target"); return state.name, state.realm end
    function InCombatLockdown() return state.combat end
    function GetTime() return state.now end
    function IsInGroup(category)
        if category == LE_PARTY_CATEGORY_INSTANCE then return state.instance end
        return state.group
    end
    function IsInRaid() return state.raid end
    C_PartyInfo = {
        InviteUnit = function(name) calls[#calls + 1] = "invite:" .. name end,
        LeaveParty = function() calls[#calls + 1] = "leave" end,
    }
    C_ChatInfo = { SendChatMessage = function(message, channel)
        equal(message, state.expectedMessage or "Thanks for the party! Take care!")
        equal(channel, "PARTY")
        calls[#calls + 1] = "chat"
    end }
    state.timers = {}
    C_Timer = { NewTimer = function(delay, callback)
        local timer = { due = state.now + delay, callback = callback }
        function timer:Cancel() self.cancelled = true end
        state.timers[#state.timers + 1] = timer
        return timer
    end }
    SendChatMessage = nil
    assert(loadfile("QuickParty/QuickParty.lua"))("QuickParty")
    frames[1].scripts.OnEvent(frames[1], "ADDON_LOADED", "OtherAddon")
    equal(#frames, 1, "ignore other addons")
    frames[1].scripts.OnEvent(frames[1], "ADDON_LOADED", "QuickParty")
end
local function click(text)
    for _, frame in ipairs(frames) do
        if frame.text == text then frame.scripts.OnClick(frame); return end
    end
    error("Missing button " .. text)
end
local function event(name, ...)
    frames[1].scripts.OnEvent(frames[1], name, ...)
end
local function message() return QuickPartyWindow.lastFont.text end
local function advance(seconds)
    state.now = state.now + seconds
    for _, timer in ipairs(state.timers) do
        if not timer.cancelled and not timer.fired and timer.due <= state.now then
            timer.fired = true
            timer.callback()
        end
    end
end

setup()
equal(#calls, 0, "loading never acts")
equal(message(), "Ready to invite.", "idle status")
event("CHAT_MSG_SYSTEM", "Loot threshold set to Uncommon.")
equal(message(), "Ready to invite.", "idle ignores game chatter")
for _, key in ipairs({"exists", "player", "friendly"}) do
    setup(); state[key] = false; click("Invite Player"); equal(#calls, 0, key)
end
for _, key in ipairs({"self", "member", "raidMember"}) do
    setup(); state[key] = true; click("Invite Player"); equal(#calls, 0, key)
end
setup(); state.combat = true; click("Invite Player")
equal(calls[1], "invite:Friend", "combat invite allowed")
setup(); state.name = nil; click("Invite Player"); equal(#calls, 0)
setup(); C_PartyInfo = nil; click("Invite Player"); equal(#calls, 0)
setup(); state.realm = "OtherRealm"; click("Invite Player")
equal(calls[1], "invite:Friend-OtherRealm"); contains(message(), "attempted")
state.name = "SomeoneElse"
local attempt = message()
event("CHAT_MSG_SYSTEM", "Invite declined.")
equal(message(), attempt, "unrecognized text ignored")
event("UI_ERROR_MESSAGE", 99, "Unrelated error"); equal(message(), attempt)
event("UI_ERROR_MESSAGE", "Legacy error"); equal(message(), attempt)
event("CHAT_MSG_SYSTEM", "Loot threshold set to Uncommon."); equal(message(), attempt)
local previous = message()
state.now = 122; event("CHAT_MSG_SYSTEM", "Unrelated")
equal(message(), previous, "feedback expires")
equal(#calls, 1, "events never invite")
setup(); click("Invite Player"); event("GROUP_ROSTER_UPDATE")
event("GROUP_LEFT")
state.now = 65
event("CHAT_MSG_SYSTEM", "Friend declines your group invitation.")
equal(message(), "Invitation declined: Friend", "decline survives roster and delayed response")
event("UI_ERROR_MESSAGE", 3, "Unrelated error")
equal(message(), "Invitation declined: Friend", "result remains visible")
setup(); state.realm = "OtherRealm"; click("Invite Player")
state.name = "DifferentTarget"
event("CHAT_MSG_SYSTEM", "|cffffffff|Hplayer:Friend-OtherRealm|h[Friend]|h|r is already in a group.")
equal(message(), "Already in a group: Friend-OtherRealm", "realm target and player link")
for _, channel in ipairs({"CHAT_MSG_SYSTEM", "UI_ERROR_MESSAGE", "UI_INFO_MESSAGE"}) do
    setup(); click("Invite Player")
    if channel == "CHAT_MSG_SYSTEM" then
        event(channel, "Friend is already in a group.")
    else
        event(channel, 123, "Friend is already in a group.")
    end
    equal(message(), "Already in a group: Friend", channel)
end
setup(); click("Invite Player")
previous = message()
event("CHAT_MSG_SYSTEM", "SomeoneElse declines your group invitation.")
equal(message(), previous, "other player's result ignored")
ERR_DECLINE_GROUP_S = "%1$s lehnt Eure Gruppeneinladung ab."
event("CHAT_MSG_SYSTEM", "Friend lehnt Eure Gruppeneinladung ab.")
equal(message(), "Invitation declined: Friend", "localized positional format")
setup(); click("Invite Player"); state.name = "NextPlayer"; click("Invite Player")
previous = message()
event("CHAT_MSG_SYSTEM", "Friend declines your group invitation.")
equal(message(), previous, "old attempt ignored")
event("CHAT_MSG_SYSTEM", "NextPlayer declines your group invitation.")
equal(message(), "Invitation declined: NextPlayer", "only latest attempt")

setup(); click("Thank & Leave"); equal(#calls, 0, "solo")
for _, key in ipairs({"raid", "instance", "combat"}) do
    setup(); state.group = true; state[key] = true
    click("Thank & Leave"); equal(#calls, 0, key)
end
setup(); state.group = true; C_PartyInfo.LeaveParty = nil
click("Thank & Leave"); equal(#calls, 0, "check leave before chat")
setup(); state.group = true; C_ChatInfo = nil
click("Thank & Leave"); equal(#calls, 0, "missing chat")
setup(); state.group = true; click("Thank & Leave")
equal(table.concat(calls, ","), "chat", "no immediate leave")
advance(4.9); equal(#calls, 1, "wait five seconds")
advance(0.1)
equal(table.concat(calls, ","), "chat,leave", "chat precedes leave")
setup(); state.group = true
SendChatMessage = C_ChatInfo.SendChatMessage; C_ChatInfo = nil
click("Thank & Leave"); advance(5)
equal(table.concat(calls, ","), "chat,leave", "legacy chat")

setup(); state.group = true; click("Thank & Leave"); click("Cancel Leave")
advance(5); equal(#calls, 1, "cancel never leaves or repeats chat")
setup(); state.group = true; click("Thank & Leave")
event("GROUP_LEFT"); state.group = true; advance(5)
equal(#calls, 1, "never leave a new party")
for _, key in ipairs({"raid", "instance", "combat"}) do
    setup(); state.group = true; click("Thank & Leave"); state[key] = true
    advance(5); equal(#calls, 1, "recheck " .. key)
end
setup(); state.group = true; click("Thank & Leave"); state.group = false
event("GROUP_ROSTER_UPDATE"); advance(5); equal(#calls, 1, "party dissolved")
setup(); state.group = true; C_Timer = nil
click("Thank & Leave"); equal(#calls, 0, "missing timer does not send")
setup(); state.group = true; click("Thank & Leave"); QuickPartyWindow:Hide()
advance(5); equal(#calls, 2, "hiding does not silently cancel leave")

setup(); QuickPartyMessageEdit:SetText("  Good luck with the quest!  ")
click("Save Message"); equal(QuickPartyDB.message, "Good luck with the quest!")
state.expectedMessage = QuickPartyDB.message; state.group = true
click("Thank & Leave"); advance(5); equal(#calls, 2, "custom message sent")
local custom = QuickPartyDB.message
for _, invalid in ipairs({"   ", "text|Hlink", "bad\ntext", string.rep("a", 256)}) do
    QuickPartyMessageEdit:SetText(invalid); click("Save Message")
    equal(QuickPartyDB.message, custom, "invalid edit preserves saved message")
end
setup({message = custom}); equal(QuickPartyMessageEdit:GetText(), custom, "restore message")
click("Use Default"); equal(QuickPartyDB.message, "Thanks for the party! Take care!")

setup({ hidden = true, position = { point = "INVALID" } })
equal(QuickPartyWindow:IsShown(), false)
equal(QuickPartyWindow.point[1], "CENTER", "bad position resets")
SlashCmdList.QUICKPARTY("show"); equal(QuickPartyDB.hidden, false)
QuickPartyWindow:SetPoint("TOP", UIParent, "TOP", 12, -18)
QuickPartyWindow.scripts.OnDragStop()
local saved = QuickPartyDB
setup(saved); equal(QuickPartyWindow.point[4], 12, "restore x")
equal(QuickPartyWindow.point[5], -18, "restore y")
SlashCmdList.QUICKPARTY("hide"); equal(QuickPartyDB.hidden, true)
SlashCmdList.QUICKPARTY(" reset "); equal(QuickPartyDB.position, nil)
equal(QuickPartyWindow:IsShown(), true)
setup("corrupt"); equal(type(QuickPartyDB), "table")

setup()
local launcher = QuickPartyMinimapButton
state.cursorX, state.cursorY = 100, 50 -- right of minimap at scale 0.5
launcher.scripts.OnMouseDown(launcher)
launcher.scripts.OnDragStart(launcher)
launcher.scripts.OnUpdate(launcher)
equal(math.floor(launcher.point[4] + 0.5), 88, "drag to right rim")
equal(launcher.point[5], 0, "scaled cursor y")
launcher.scripts.OnDragStop(launcher)
equal(launcher.scripts.OnUpdate, nil, "drag stops updating")
equal(QuickPartyDB.minimapAngle, 0, "save minimap angle")
launcher.scripts.OnClick(launcher)
equal(QuickPartyWindow:IsShown(), true, "drag never toggles window")
launcher.scripts.OnMouseDown(launcher)
launcher.scripts.OnClick(launcher)
equal(QuickPartyWindow:IsShown(), false, "next click toggles")
saved = QuickPartyDB; setup(saved)
equal(math.floor(QuickPartyMinimapButton.point[4] + 0.5), 88, "restore minimap angle")
setup({minimapAngle = math.huge})
assert(QuickPartyMinimapButton.point[4] < 0, "invalid angle returns to default")
print("Quick Party behavior checks passed.")
