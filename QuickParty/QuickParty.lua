local addonName = ...
local window, status, leaveButton
local leaveTimer
local pendingUntil
local pendingName, inviteOutcome
local THANK_YOU = "Thanks for the party! Take care!"

local function validMessage(message)
    return type(message) == "string" and #message <= 255
        and message:find("%S") and not message:find("[%c|]")
end

local function toggleWindow()
    if window:IsShown() then window:Hide() else window:Show() end
end

local function createMinimapButton()
    local button = CreateFrame("Button", "QuickPartyMinimapButton", Minimap)
    button:SetSize(32, 32)
    local angle = QuickPartyDB.minimapAngle
    if type(angle) ~= "number" or angle ~= angle or math.abs(angle) > 1000000 then
        angle = 2.677945 -- Original upper-left position, in radians.
    end
    local function place()
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(angle) * (Minimap:GetWidth() / 2 + 8),
            math.sin(angle) * (Minimap:GetHeight() / 2 + 8))
    end
    local function followCursor()
        local x, y = GetCursorPosition()
        local centerX, centerY = Minimap:GetCenter()
        if not centerX or not centerY then return end
        local scale = Minimap:GetEffectiveScale()
        local dx, dy = x / scale - centerX, y / scale - centerY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance == 0 then return end
        angle = math.acos(math.max(-1, math.min(1, dx / distance)))
        if dy < 0 then angle = -angle end
        place()
    end
    place()
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local dragged = false
    button:SetScript("OnMouseDown", function() dragged = false end)
    button:SetScript("OnDragStart", function(self)
        dragged = true
        GameTooltip:Hide()
        self:SetScript("OnUpdate", followCursor)
        followCursor()
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        QuickPartyDB.minimapAngle = angle
    end)
    button:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnClick", function()
        if not dragged then toggleWindow() end
        dragged = false
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Quick Party")
        GameTooltip:AddLine("Left-click to open or close the window.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the minimap.", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function report(message)
    status:SetText(message)
end

local function plainText(message)
    return (message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|H.-|h(.-)|h", "%1"):gsub("%[([^%]]+)%]", "%1"))
end

local function matchesInviteMessage(message, template)
    if not pendingName or type(template) ~= "string" then return false end
    -- Match the client's localized format, not English substrings. Support
    -- positional string placeholders as well as the usual single %s.
    template = plainText(template):gsub("%%(%d+)%$s", "%%s")
    local pattern = template:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    pattern = "^" .. pattern:gsub("%%%%s", "(.-)") .. "$"
    local name = plainText(message):match(pattern)
    if not name then return false end
    local shortName = pendingName:match("^([^-]+)")
    return name:lower() == pendingName:lower() or name:lower() == shortName:lower()
end

local function inviteFeedback(message)
    if type(message) ~= "string" then return end
    if matchesInviteMessage(message, ERR_DECLINE_GROUP_S) then
        inviteOutcome = "Invitation declined: " .. pendingName
    elseif matchesInviteMessage(message, ERR_ALREADY_IN_GROUP_S) then
        inviteOutcome = "Already in a group: " .. pendingName
    else
        return
    end
    -- Only recognized invite responses belong in this window. Loot changes
    -- and other unrelated messages remain in the game's original chat/UI.
    report(inviteOutcome)
end

local function invite()
    pendingUntil = nil
    pendingName, inviteOutcome = nil, nil
    if not UnitExists("target") or not UnitIsPlayer("target") then
        report("Select a player to invite.")
        return
    end
    if UnitIsUnit("target", "player") then
        report("You cannot invite yourself.")
        return
    end
    if UnitInParty("target") or UnitInRaid("target") then
        report("That player is already in your group.")
        return
    end
    if not UnitCanCooperate("player", "target") then
        report("Select a friendly player.")
        return
    end
    if not C_PartyInfo or type(C_PartyInfo.InviteUnit) ~= "function" then
        report("This client does not provide C_PartyInfo.InviteUnit.")
        return
    end
    local name, realm = UnitName("target")
    if not name or name == "" then
        report("The selected player's name is unavailable.")
        return
    end
    if realm and realm ~= "" then name = name .. "-" .. realm end
    report("Invite request attempted: " .. name)
    pendingUntil = GetTime() + 120
    pendingName = name
    -- Forever permits this call in combat; it still requires a manual click.
    C_PartyInfo.InviteUnit(name)
end

local function cancelLeave(message)
    if not leaveTimer then return end
    leaveTimer:Cancel()
    leaveTimer = nil
    leaveButton:SetText("Thank & Leave")
    report(message or "Leaving cancelled.")
end

local function ordinaryParty()
    return IsInGroup() and not IsInRaid()
        and not (LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE))
end

local function thankAndLeave()
    if leaveTimer then cancelLeave(); return end
    if not IsInGroup() then
        report("You are not in a party.")
        return
    end
    if IsInRaid() then
        report("Thank & Leave is available in parties only.")
        return
    end
    -- PARTY can address a different group from an instance group. Avoid
    -- sending thanks to one group and leaving another.
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        report("Instance groups are not supported. Use the game group menu.")
        return
    end
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if type(send) ~= "function" or not C_PartyInfo
        or type(C_PartyInfo.LeaveParty) ~= "function" then
        report("This client is missing the chat or leave-party API.")
        return
    end
    if not C_Timer or type(C_Timer.NewTimer) ~= "function" then
        report("This client is missing the timer API.")
        return
    end
    pendingUntil = nil
    send(QuickPartyDB.message, "PARTY")
    leaveButton:SetText("Cancel Leave")
    report("Thanks sent. Leaving in 5 seconds...")
    leaveTimer = C_Timer.NewTimer(5, function()
        if not ordinaryParty() then
            cancelLeave("Leaving cancelled: group changed.")
            return
        end
        leaveTimer = nil
        leaveButton:SetText("Thank & Leave")
        -- Leave only ourselves. Never uninvite members or bypass confirmations.
        C_PartyInfo.LeaveParty()
        report("Leave requested.")
    end)
end

local function savePosition()
    window:StopMovingOrSizing()
    local point, _, relativePoint, x, y = window:GetPoint()
    QuickPartyDB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local anchors = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}

local function resetPosition()
    window:ClearAllPoints()
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    QuickPartyDB.position = nil
end

local function createWindow()
    QuickPartyDB = type(QuickPartyDB) == "table" and QuickPartyDB or {}
    if not validMessage(QuickPartyDB.message) then QuickPartyDB.message = THANK_YOU end
    window = CreateFrame("Frame", "QuickPartyWindow", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(300, 204)
    window.TitleText:SetText("Quick Party")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", savePosition)
    window:SetScript("OnHide", function(self)
        self:StopMovingOrSizing()
        QuickPartyDB.hidden = true
    end)
    window:SetScript("OnShow", function() QuickPartyDB.hidden = false end)

    window.CloseButton:SetScript("OnClick", function() window:Hide() end)

    local inviteButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    inviteButton:SetSize(276, 26)
    inviteButton:SetPoint("TOPLEFT", 12, -40)
    inviteButton:SetText("Invite Player")
    inviteButton:SetScript("OnClick", invite)
    leaveButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    leaveButton:SetSize(276, 26)
    leaveButton:SetPoint("TOPLEFT", 12, -72)
    leaveButton:SetText("Thank & Leave")
    leaveButton:SetScript("OnClick", thankAndLeave)
    status = window:CreateFontString("QuickPartyStatus", "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", 12, -140)
    status:SetSize(276, 50)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    report("Ready to invite.")

    local settings = CreateFrame("Frame", nil, window)
    settings:SetPoint("TOPLEFT", 12, -198)
    settings:SetSize(276, 110)
    local label = settings:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT")
    label:SetText("Party thank-you message")
    local edit = CreateFrame("EditBox", "QuickPartyMessageEdit", settings, "InputBoxTemplate")
    edit:SetSize(264, 26)
    edit:SetPoint("TOPLEFT", 6, -22)
    edit:SetAutoFocus(false)
    edit:SetMaxBytes(255)
    edit:SetText(QuickPartyDB.message)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local save = CreateFrame("Button", "QuickPartyMessageSave", settings, "UIPanelButtonTemplate")
    save:SetSize(130, 26)
    save:SetPoint("TOPLEFT", 0, -58)
    save:SetText("Save Message")
    save:SetScript("OnClick", function()
        local message = edit:GetText():match("^%s*(.-)%s*$")
        if not validMessage(message) then
            report("Enter 1-255 bytes of plain text (no links or control characters).")
            return
        end
        QuickPartyDB.message = message
        edit:SetText(message)
        edit:ClearFocus()
        report("Thank-you message saved.")
    end)
    local defaults = CreateFrame("Button", nil, settings, "UIPanelButtonTemplate")
    defaults:SetSize(130, 26)
    defaults:SetPoint("TOPRIGHT", 0, -58)
    defaults:SetText("Use Default")
    defaults:SetScript("OnClick", function()
        QuickPartyDB.message = THANK_YOU
        edit:SetText(THANK_YOU)
        edit:ClearFocus()
        report("Default thank-you message restored.")
    end)
    settings:Hide()
    local settingsButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    settingsButton:SetSize(276, 26)
    settingsButton:SetPoint("TOPLEFT", 12, -104)
    settingsButton:SetText("Settings")
    settingsButton:SetScript("OnClick", function()
        if settings:IsShown() then
            settings:Hide()
            edit:ClearFocus()
            window:SetSize(300, 204)
        else
            edit:SetText(QuickPartyDB.message)
            settings:Show()
            window:SetSize(300, 318)
        end
    end)

    local p = QuickPartyDB.position
    if type(p) == "table" and anchors[p.point] and anchors[p.relativePoint]
        and type(p.x) == "number" and type(p.y) == "number"
        and p.x == p.x and p.y == p.y
        and math.abs(p.x) < 100000 and math.abs(p.y) < 100000 then
        window:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    else
        resetPosition()
    end
    if QuickPartyDB.hidden then window:Hide() else window:Show() end
    createMinimapButton()

    SLASH_QUICKPARTY1 = "/qp"
    SLASH_QUICKPARTY2 = "/quickparty"
    SlashCmdList.QUICKPARTY = function(input)
        local command = (input or ""):match("^%s*(.-)%s*$"):lower()
        if command == "reset" then
            resetPosition()
            window:Show()
        elseif command == "show" then
            window:Show()
        elseif command == "hide" then
            window:Hide()
        elseif command == "" then
            toggleWindow()
        else
            print("Quick Party: /qp [show | hide | reset]")
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if (...) ~= addonName then return end
        createWindow()
        self:UnregisterEvent("ADDON_LOADED")
        self:RegisterEvent("CHAT_MSG_SYSTEM")
        self:RegisterEvent("UI_ERROR_MESSAGE")
        self:RegisterEvent("UI_INFO_MESSAGE")
        self:RegisterEvent("GROUP_ROSTER_UPDATE")
        self:RegisterEvent("GROUP_LEFT")
    elseif event == "GROUP_LEFT" then
        cancelLeave("Leaving cancelled: you left the party.")
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Invite/decline processing can change the roster before its feedback
        -- arrives. A roster update neither accepts nor cancels our attempt.
        if not ordinaryParty() then cancelLeave("Leaving cancelled: group changed.") end
    elseif pendingUntil and GetTime() <= pendingUntil then
        local first, second = ...
        local message = event == "CHAT_MSG_SYSTEM" and first or (second or first)
        inviteFeedback(message)
    end
end)
