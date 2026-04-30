-- =============================================================
-- Synapse/Config.lua  |  WoW Midnight 12.0.1+  |  Interface: 120001
-- =============================================================
-- ElesmereUI-inspired modern settings window.
-- Opened via /syn config or ESC > Settings > AddOns > Synapse.
-- All changes apply immediately; no Apply button needed.
-- =============================================================

local ADDON_NAME, SynapseNS = ...

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  COLOUR PALETTE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local C = {
    bg          = { 0.05,  0.07,  0.08,  0.97 },
    bgSection   = { 0.04,  0.06,  0.07,  1.00 },
    border      = { 0.00,  0.78,  0.63,  0.55 },
    accent      = { 0.00,  0.78,  0.63,  1.00 },
    accentDim   = { 0.00,  0.45,  0.37,  1.00 },
    toggleOn    = { 0.00,  0.78,  0.50,  1.00 },
    toggleOff   = { 0.35,  0.38,  0.41,  1.00 },
    title       = { 1.00,  1.00,  1.00,  1.00 },
    label       = { 0.85,  0.88,  0.90,  1.00 },
    sectionLbl  = { 0.40,  0.75,  0.65,  1.00 },
    hint        = { 0.55,  0.60,  0.62,  1.00 },
    closeBtn    = { 0.75,  0.20,  0.18,  1.00 },
    sliderFill  = { 0.00,  0.78,  0.63,  1.00 },
    sliderTrack = { 0.32,  0.35,  0.38,  1.00 },
    rowAlt      = { 0.08,  0.10,  0.12,  0.40 },
}

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  LAYOUT CONSTANTS
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local WIN_W     = 640
local WIN_H     = 700
local HEADER_H  = 64
local FOOTER_H  = 44
local COL_W     = 288
local COL_GAP   = 20
local COL1_X    = 18
local COL2_X    = COL1_X + COL_W + COL_GAP
local ROW_H     = 36
local TOGGLE_W  = 44
local TOGGLE_H  = 22
local SLIDER_W        = 120
local ROT_ROW_H       = 28   -- height of each spell row in the rotation list
local ROT_SB_W        = 8    -- scrollbar track width
local ROT_INNER_W     = WIN_W - 36 - ROT_SB_W - 4  -- list content width (leaves room for scrollbar)
local CFG_SB_W        = 8    -- main config window scrollbar width
local SRCH_ROW_H      = 28   -- height of each spell row in search results
local MAX_SEARCH_RESULTS = 20 -- max spell search results shown at once

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  STATE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local initialized = false
local configFrame
local pickBtn
local pickOverlay
local pendingSlot  = 0   -- slot active when pick mode was opened (for cancel restore)
local togCooldown
local togClickThrough, togLocked
local sliderScale, sliderCombat, sliderNoCombat

-- Rotation section UI refs
local togPlayback
local recordBtn
local recordStatusLbl
local rotListAnchor
local rotEmptyLbl
local rotRows         = {}
local rotUpdateScrollbar  -- function set during InitConfig to sync the thumb
local cfgUpdateScrollbar  -- function set during InitConfig to sync the main window scrollbar
local searchBox
local searchResultsAnchor
local searchEmptyLbl
local searchRows      = {}

-- Profile section UI refs
local profileSelected    = nil   -- currently chosen profile name
local profileDropdownTxt         -- label inside the dropdown button
local profileDropdownPopup       -- popup list frame
local profileNameBox             -- EditBox for typing a new profile name
local RefreshProfileDropdown     -- forward declaration

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  DRAW HELPERS
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function FillColor(tex, c)
    tex:SetColorTexture(c[1], c[2], c[3], c[4])
end

local function MakeRect(parent, layer, c)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    FillColor(t, c)
    return t
end

local function MakeText(parent, text, fontObj, c, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY", fontObj or "GameFontNormal")
    if text then fs:SetText(text) end
    if c    then fs:SetTextColor(c[1], c[2], c[3], c[4]) end
    return fs
end

-- Safe icon lookup used by rotation / search lists
local function GetSpellIcon(spellID)
    if not spellID then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if ok and info and info.iconID then return info.iconID end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  PILL TOGGLE  â€” returns frame with :SetChecked / :GetChecked
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function MakeToggle(parent, x, y, onChange)
    local track = CreateFrame("Frame", nil, parent)
    track:SetSize(TOGGLE_W, TOGGLE_H)
    track:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local trackBg = MakeRect(track, "ARTWORK", C.toggleOff)
    trackBg:SetAllPoints()

    local thumb = CreateFrame("Frame", nil, track)
    thumb:SetSize(TOGGLE_H - 6, TOGGLE_H - 6)
    thumb:SetPoint("LEFT", track, "LEFT", 2, 0)
    local thumbTex = MakeRect(thumb, "ARTWORK", C.title)
    thumbTex:SetAllPoints()

    local checked = false

    local function Refresh()
        if checked then
            FillColor(trackBg, C.toggleOn)
            thumb:ClearAllPoints()
            thumb:SetPoint("RIGHT", track, "RIGHT", -2, 0)
        else
            FillColor(trackBg, C.toggleOff)
            thumb:ClearAllPoints()
            thumb:SetPoint("LEFT", track, "LEFT", 2, 0)
        end
    end

    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function()
        if not SynapseNS.cfg then return end
        checked = not checked
        Refresh()
        if onChange then onChange(checked) end
    end)
    track:SetScript("OnEnter", function(self) self:SetAlpha(0.80) end)
    track:SetScript("OnLeave", function(self) self:SetAlpha(1.00) end)

    function track:SetChecked(v) checked = v and true or false; Refresh() end
    function track:GetChecked() return checked end

    Refresh()
    return track
end

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  FLAT SLIDER  â€” returns frame with :SetValue / :GetValue
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function MakeSlider(parent, x, y, minV, maxV, step, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(SLIDER_W + 36, 16)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local track = CreateFrame("Frame", nil, container)
    track:SetSize(SLIDER_W, 4)
    track:SetPoint("LEFT", container, "LEFT", 0, 0)
    local trackBg = MakeRect(track, "ARTWORK", C.sliderTrack)
    trackBg:SetAllPoints()

    local fill = MakeRect(track, "ARTWORK", C.sliderFill)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetHeight(4)
    fill:SetWidth(0)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetSize(10, 16)
    local thumbTex = MakeRect(thumb, "ARTWORK", C.title)
    thumbTex:SetAllPoints()

    local valLbl = MakeText(container, "0", "GameFontNormalSmall", C.label, "OVERLAY")
    valLbl:SetPoint("LEFT", track, "RIGHT", 6, 0)
    valLbl:SetWidth(30)
    valLbl:SetJustifyH("LEFT")

    local value    = minV
    local dragging = false

    local function Apply(v, fire)
        local steps = math.floor((v - minV) / step + 0.5)
        v = math.max(minV, math.min(maxV, minV + steps * step))
        value = v
        local frac = (maxV == minV) and 0 or (v - minV) / (maxV - minV)
        fill:SetWidth(math.max(0, frac * SLIDER_W))
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", track, "LEFT", frac * SLIDER_W, 0)
        valLbl:SetText(step < 1 and string.format("%.2f", v) or tostring(math.floor(v + 0.5)))
        if fire and onChange then onChange(v) end
    end

    local function FromCursor()
        local cx = GetCursorPosition() / UIParent:GetEffectiveScale()
        local tx = track:GetLeft()
        Apply(minV + math.max(0, math.min(1, (cx - tx) / SLIDER_W)) * (maxV - minV), true)
    end

    thumb:SetScript("OnMouseDown", function(self, b) if b == "LeftButton" then dragging = true end end)
    thumb:SetScript("OnMouseUp",   function()          dragging = false end)
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(self, b)
        if b == "LeftButton" then dragging = true; FromCursor() end
    end)
    track:SetScript("OnMouseUp", function() dragging = false end)
    container:SetScript("OnUpdate", function() if dragging then FromCursor() end end)

    function container:SetValue(v) Apply(v, false) end
    function container:GetValue() return value end

    Apply(minV, false)
    return container
end

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  SECTION HEADER STRIP
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function MakeSectionHeader(parent, text, x, y)
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetSize(WIN_W - 36, 20)
    strip:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local bg = MakeRect(strip, "BACKGROUND", C.bgSection)
    bg:SetAllPoints()
    local accent = MakeRect(strip, "ARTWORK", C.accent)
    accent:SetSize(2, 14)
    accent:SetPoint("LEFT", strip, "LEFT", 4, 0)
    local lbl = MakeText(strip, text, "GameFontNormalSmall", C.sectionLbl, "OVERLAY")
    lbl:SetPoint("LEFT", strip, "LEFT", 12, 0)
    return strip
end

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  ROW  â€” label left, control anchors RIGHT inside it
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local function MakeRow(parent, labelText, x, y, w)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(w or COL_W, ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local bg = MakeRect(row, "BACKGROUND", C.rowAlt)
    bg:SetAllPoints()
    local lbl = MakeText(row, labelText, "GameFontNormal", C.label, "OVERLAY")
    lbl:SetPoint("LEFT",  row, "LEFT", 8, 0)
    lbl:SetWidth((w or COL_W) * 0.54)
    lbl:SetJustifyH("LEFT")
    return row
end

local function ToggleRow(parent, label, x, y, w, onChange)
    local row = MakeRow(parent, label, x, y, w)
    local tog = MakeToggle(row, (w or COL_W) - TOGGLE_W - 8, -(ROW_H - TOGGLE_H) / 2, onChange)
    return row, tog
end

local function SliderRow(parent, label, x, y, w, minV, maxV, step, onChange)
    local row  = MakeRow(parent, label, x, y, w)
    local sldr = MakeSlider(row, (w or COL_W) - SLIDER_W - 36 - 6, -(ROW_H - 16) / 2, minV, maxV, step, onChange)
    return row, sldr
end

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  SyncFromConfig
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- ─────────────────────────────────────────────────────────────
--  PICK MODE
--  Strategy: pickOverlay covers the full screen and captures ALL
--  mouse input.  A separate TOOLTIP-strata highlight frame shows
--  which slot the cursor is over (purely visual, no mouse handling).
--  OnUpdate detects the hovered slot by comparing the cursor position
--  against each visible action bar button's screen rect.  OnMouseDown
--  on the overlay confirms the selection.  This avoids the secure-
--  frame click-interception problem that child overlay buttons have.
-- ─────────────────────────────────────────────────────────────
local BARS = {
    { prefix = "ActionButton",              offset = 0  },
    { prefix = "MultiBar5Button",           offset = 12 },
    { prefix = "MultiBarBottomLeftButton",  offset = 24 },
    { prefix = "MultiBarBottomRightButton", offset = 36 },
    { prefix = "MultiBarRightButton",       offset = 48 },
    { prefix = "MultiBarLeftButton",        offset = 60 },
}

local ExitPickMode       -- forward declaration
local pickHighlight      -- single reused highlight frame (TOOLTIP strata)
local pickHoveredSlot = 0

-- Returns (slotNumber, srcFrame) of whichever action bar button
-- the cursor is currently inside, or (0, nil) if none.
local function GetSlotAtCursor()
    local cx, cy = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cx = cx / uiScale
    cy = cy / uiScale
    for _, bar in ipairs(BARS) do
        for i = 1, 12 do
            local src = _G[bar.prefix .. i]
            if src and src:IsVisible() then
                local l = src:GetLeft()
                local b = src:GetBottom()
                local r = src:GetRight()
                local t = src:GetTop()
                if l and cx >= l and cx <= r and cy >= b and cy <= t then
                    return bar.offset + i, src
                end
            end
        end
    end
    return 0, nil
end

local function EnterPickMode()
    pendingSlot = (SynapseNS.cfg and SynapseNS.cfg.mirrorSlot) or 0
    if pendingSlot > 0 then
        -- Tear down the mirrorButton so it cannot intercept clicks
        -- while the pick overlay is active.
        SynapseNS.SetMirrorSlot(0)
    end

    -- Reusable highlight frame (created once, TOOLTIP strata, no mouse).
    if not pickHighlight then
        pickHighlight = CreateFrame("Frame", nil, UIParent)
        pickHighlight:SetFrameStrata("TOOLTIP")
        pickHighlight:SetFrameLevel(60)
        local hlTex = pickHighlight:CreateTexture(nil, "ARTWORK")
        hlTex:SetAllPoints()
        hlTex:SetColorTexture(0, 0.78, 0.63, 0.60)
        pickHighlight.label = pickHighlight:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pickHighlight.label:SetAllPoints()
        pickHighlight.label:SetJustifyH("CENTER")
        pickHighlight.label:SetJustifyV("MIDDLE")
    end
    pickHighlight:Hide()
    pickHoveredSlot = 0

    if not pickOverlay then
        pickOverlay = CreateFrame("Frame", nil, UIParent)
        pickOverlay:SetAllPoints(UIParent)
        pickOverlay:SetFrameStrata("FULLSCREEN_DIALOG")
        pickOverlay:SetFrameLevel(10)
        local dim = pickOverlay:CreateTexture(nil, "BACKGROUND")
        dim:SetAllPoints()
        dim:SetColorTexture(0, 0, 0, 0.60)
        local msg = pickOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        msg:SetPoint("TOP", pickOverlay, "TOP", 0, -90)
        msg:SetWidth(600)
        msg:SetJustifyH("CENTER")
        msg:SetText(
            "|cFF00C8A0Hover over an action bar button and click to select it.|r\n"
         .. "|cFFAAAAAARRight-click or Escape to cancel.|r")
        pickOverlay:EnableMouse(true)
        pickOverlay:EnableKeyboard(true)
        pickOverlay:SetPropagateKeyboardInput(false)
        pickOverlay:SetScript("OnKeyDown", function(_, k)
            if k == "ESCAPE" then ExitPickMode(nil) end
        end)
    end

    -- Re-assign per-session handlers (safe to re-set each enter).
    pickOverlay:SetScript("OnUpdate", function()
        local slot, src = GetSlotAtCursor()
        pickHoveredSlot = slot
        if slot > 0 and src then
            pickHighlight:ClearAllPoints()
            pickHighlight:SetAllPoints(src)
            pickHighlight.label:SetText(tostring(slot))
            pickHighlight:Show()
        else
            pickHighlight:Hide()
        end
    end)

    pickOverlay:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then
            if pickHoveredSlot > 0 then
                ExitPickMode(pickHoveredSlot)
            end
        elseif btn == "RightButton" then
            ExitPickMode(nil)
        end
    end)

    pickOverlay:Show()
end

ExitPickMode = function(selectedSlot)
    if pickOverlay then
        pickOverlay:Hide()
        pickOverlay:SetScript("OnUpdate",    nil)
        pickOverlay:SetScript("OnMouseDown", nil)
    end
    if pickHighlight then pickHighlight:Hide() end
    pickHoveredSlot = 0
    if selectedSlot then
        SynapseNS.cfg.mirrorSlot = selectedSlot
        SynapseNS.SetMirrorSlot(selectedSlot)
        SynapseNS.RefreshDisplay()
    else
        -- Cancelled: restore whatever slot was active before pick mode.
        SynapseNS.SetMirrorSlot(pendingSlot)
    end
    configFrame:Show()  -- triggers OnShow -> SyncFromConfig
end

-- -------------------------------------------------------------
--  PROFILE DROPDOWN
-- -------------------------------------------------------------
RefreshProfileDropdown = function()
    if profileDropdownTxt then
        profileDropdownTxt:SetText(profileSelected or "-- select profile --")
    end
    -- If the selected profile was deleted, clear the selection
    if profileSelected then
        local found = false
        for _, n in ipairs(SynapseNS.GetProfiles()) do
            if n == profileSelected then found = true; break end
        end
        if not found then
            profileSelected = nil
            if profileDropdownTxt then profileDropdownTxt:SetText("-- select profile --") end
        end
    end
end

-- -------------------------------------------------------------
--  ROTATION LIST  (populated on open / on record state change)
-- -------------------------------------------------------------
local function RefreshRotationList()
    if not rotListAnchor then return end
    local charCfg = SynapseNS.charCfg
    if not charCfg then
        rotEmptyLbl:SetShown(true)
        for _, r in ipairs(rotRows) do r:Hide() end
        return
    end
    local rotation = charCfg.rotation or {}
    local count    = #rotation

    rotEmptyLbl:SetShown(count == 0)

    for i, spellID in ipairs(rotation) do
        local row = rotRows[i]
        if not row then
            row = CreateFrame("Frame", nil, rotListAnchor)
            row:SetSize(ROT_INNER_W, ROT_ROW_H)
            row:SetPoint("TOPLEFT", rotListAnchor, "TOPLEFT", 0, -(i - 1) * ROT_ROW_H)
            local bg = MakeRect(row, "BACKGROUND", (i % 2 == 0) and C.rowAlt or {0,0,0,0.0})
            bg:SetAllPoints()
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", row, "LEFT", 4, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.icon = icon
            local lbl = MakeText(row, "", "GameFontNormal", C.label, "OVERLAY")
            lbl:SetPoint("LEFT", row, "LEFT", 30, 0)
            lbl:SetWidth(ROT_INNER_W - 30 - 22 - 22 - 54 - 14)
            lbl:SetJustifyH("LEFT")
            row.lbl = lbl
            -- Up button
            local upBtn = CreateFrame("Button", nil, row)
            upBtn:SetSize(22, 20)
            upBtn:SetPoint("RIGHT", row, "RIGHT", -78, 0)
            upBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
            upBtn:SetHighlightTexture("Interface\\Buttons\\Arrow-Up-Down")
            upBtn:SetPushedTexture("Interface\\Buttons\\Arrow-Up-Down")
            row.upBtn = upBtn
            -- Down button
            local dnBtn = CreateFrame("Button", nil, row)
            dnBtn:SetSize(22, 20)
            dnBtn:SetPoint("RIGHT", row, "RIGHT", -54, 0)
            dnBtn:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
            dnBtn:SetHighlightTexture("Interface\\Buttons\\Arrow-Down-Down")
            dnBtn:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")
            row.dnBtn = dnBtn
            -- Remove button
            local rmBtn = CreateFrame("Button", nil, row)
            rmBtn:SetSize(46, 20)
            rmBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            local rmBg  = MakeRect(rmBtn, "ARTWORK", { 0.45, 0.12, 0.10, 1.0 })
            rmBg:SetAllPoints()
            local rmTxt = MakeText(rmBtn, "Remove", "GameFontNormalSmall", C.title, "OVERLAY")
            rmTxt:SetAllPoints(); rmTxt:SetJustifyH("CENTER"); rmTxt:SetJustifyV("MIDDLE")
            rmBtn:SetScript("OnEnter", function() rmBg:SetAlpha(0.70) end)
            rmBtn:SetScript("OnLeave", function() rmBg:SetAlpha(1.00) end)
            row.rmBtn = rmBtn
            rotRows[i] = row
        end

        -- Always reposition (row index may have shifted after a swap/remove)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", rotListAnchor, "TOPLEFT", 0, -(i - 1) * ROT_ROW_H)

        row.icon:SetTexture(GetSpellIcon(spellID))
        row.lbl:SetText(C_Spell.GetSpellName(spellID) or ("Spell " .. spellID))

        -- Up: disabled on first row
        if i == 1 then
            row.upBtn:SetScript("OnClick", nil)
            row.upBtn:SetAlpha(0.3)
        else
            row.upBtn:SetAlpha(1.0)
            row.upBtn:SetScript("OnClick", function()
                rotation[i], rotation[i-1] = rotation[i-1], rotation[i]
                if charCfg.playback then SynapseNS.EnablePlayback(true) end
                RefreshRotationList()
                RefreshSearchResults()
            end)
        end

        -- Down: disabled on last row
        if i == count then
            row.dnBtn:SetScript("OnClick", nil)
            row.dnBtn:SetAlpha(0.3)
        else
            row.dnBtn:SetAlpha(1.0)
            row.dnBtn:SetScript("OnClick", function()
                rotation[i], rotation[i+1] = rotation[i+1], rotation[i]
                if charCfg.playback then SynapseNS.EnablePlayback(true) end
                RefreshRotationList()
                RefreshSearchResults()
            end)
        end

        -- Remove
        row.rmBtn:SetScript("OnClick", function()
            table.remove(rotation, i)
            if charCfg.playback then SynapseNS.EnablePlayback(true) end
            RefreshRotationList()
            RefreshSearchResults()
        end)

        row:Show()
    end

    for i = count + 1, #rotRows do rotRows[i]:Hide() end
    rotListAnchor:SetHeight(math.max(ROT_ROW_H, count * ROT_ROW_H))
    if rotUpdateScrollbar then rotUpdateScrollbar() end
end

-- -------------------------------------------------------------
--  SPELL SEARCH RESULTS
-- -------------------------------------------------------------
local function RefreshSearchResults()
    if not searchResultsAnchor then return end
    local query = (searchBox and searchBox:GetText() or ""):lower()
    if query == "" then
        searchEmptyLbl:SetText("Type to search your character\226\128\153s spells.")
        searchEmptyLbl:Show()
        for _, r in ipairs(searchRows) do r:Hide() end
        searchResultsAnchor:SetHeight(SRCH_ROW_H)
        return
    end

    local charCfg = SynapseNS.charCfg
    local rotation = charCfg and (charCfg.rotation or {}) or {}

    -- Build a lookup set for O(1) "already in rotation" checks
    local inRotation = {}
    for _, id in ipairs(rotation) do inRotation[id] = true end

    -- Enumerate spellbook (same pattern as blizzkili GetAvailableSpells)
    local results = {}
    local numLines = C_SpellBook.GetNumSpellBookSkillLines()
    for i = 1, numLines do
        local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)
        if lineInfo then
            local offset   = lineInfo.itemIndexOffset
            local numSlots = lineInfo.numSpellBookItems
            for j = offset + 1, offset + numSlots do
                local itemInfo = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
                if itemInfo
                   and itemInfo.itemType == Enum.SpellBookItemType.Spell
                   and not itemInfo.isPassive
                   and not itemInfo.isOffSpec then
                    local id   = itemInfo.spellID
                    local name = C_Spell.GetSpellName(id)
                    if name and name:lower():find(query, 1, true) then
                        results[#results + 1] = { id = id, name = name }
                        if #results >= MAX_SEARCH_RESULTS then break end
                    end
                end
            end
        end
        if #results >= MAX_SEARCH_RESULTS then break end
    end

    searchEmptyLbl:SetShown(#results == 0)
    if #results == 0 then
        searchEmptyLbl:SetText("No spells found.")
    end

    for i, entry in ipairs(results) do
        local row = searchRows[i]
        if not row then
            row = CreateFrame("Frame", nil, searchResultsAnchor)
            row:SetSize(WIN_W - 36, SRCH_ROW_H)
            row:SetPoint("TOPLEFT", searchResultsAnchor, "TOPLEFT", 0, -(i - 1) * SRCH_ROW_H)
            local bg = MakeRect(row, "BACKGROUND", (i % 2 == 0) and C.rowAlt or {0,0,0,0.0})
            bg:SetAllPoints()
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT", row, "LEFT", 4, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.icon = icon
            local lbl = MakeText(row, "", "GameFontNormal", C.label, "OVERLAY")
            lbl:SetPoint("LEFT", row, "LEFT", 30, 0)
            lbl:SetWidth(WIN_W - 36 - 30 - 92)
            lbl:SetJustifyH("LEFT")
            row.lbl = lbl
            local btn = CreateFrame("Button", nil, row)
            btn:SetSize(84, 20)
            btn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            local btnBg  = MakeRect(btn, "ARTWORK", C.accentDim)
            btnBg:SetAllPoints()
            local btnTxt = MakeText(btn, "", "GameFontNormalSmall", C.title, "OVERLAY")
            btnTxt:SetAllPoints()
            btnTxt:SetJustifyH("CENTER")
            btnTxt:SetJustifyV("MIDDLE")
            btn:SetScript("OnEnter", function() btnBg:SetAlpha(0.70) end)
            btn:SetScript("OnLeave", function() btnBg:SetAlpha(1.00) end)
            row.btn    = btn
            row.btnBg  = btnBg
            row.btnTxt = btnTxt
            searchRows[i] = row
        end

        local spellID   = entry.id
        local alreadyIn = inRotation[spellID]
        row.icon:SetTexture(GetSpellIcon(spellID))
        row.lbl:SetText(entry.name)
        if alreadyIn then
            row.btnTxt:SetText("\226\156\147 Added")
            FillColor(row.btnBg, { 0.15, 0.40, 0.25, 1.0 })
            row.btn:SetScript("OnClick", nil)  -- already in list, no action
        else
            row.btnTxt:SetText("+ Add")
            FillColor(row.btnBg, C.accentDim)
            row.btn:SetScript("OnClick", function()
                if charCfg then
                    charCfg.rotation = charCfg.rotation or {}
                    charCfg.rotation[#charCfg.rotation + 1] = spellID
                end
                RefreshSearchResults()
                RefreshRotationList()
            end)
        end
        row:Show()
    end

    for i = #results + 1, #searchRows do searchRows[i]:Hide() end
    searchResultsAnchor:SetHeight(math.max(SRCH_ROW_H, #results * SRCH_ROW_H))
end

local function SyncFromConfig()
    local cfg = SynapseNS.cfg
    if not cfg then return end
    local slot = cfg.mirrorSlot or 0
    pickBtn:SetText(slot > 0 and ("Slot " .. slot .. "  \226\128\148  click to change") or "Click to pick action bar slot...")
    -- togCooldown is frozen (in development) — always stays unchecked
    togClickThrough:SetChecked(cfg.clickThrough)
    togLocked:SetChecked(cfg.locked)
    sliderScale:SetValue(cfg.scale or 1.0)
    sliderCombat:SetValue(cfg.opacityCombat or 1.0)
    sliderNoCombat:SetValue(cfg.opacityNoCombat or 0.8)
    if togPlayback and SynapseNS.charCfg then
        togPlayback:SetChecked(SynapseNS.charCfg.playback or false)
    end
    RefreshRotationList()
    RefreshProfileDropdown()
end

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  InitConfig
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function SynapseNS.InitConfig()
    if initialized then return end
    initialized = true

    -- Outer frame (fully custom â€” no Blizzard template)
    configFrame = CreateFrame("Frame", "SynapseConfigFrame", UIParent)
    configFrame:SetSize(WIN_W, WIN_H)
    configFrame:SetFrameStrata("HIGH")
    configFrame:SetFrameLevel(50)
    configFrame:SetMovable(true)
    configFrame:SetClampedToScreen(true)
    configFrame:SetPoint("CENTER")
    configFrame:Hide()
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop",  configFrame.StopMovingOrSizing)
    configFrame:SetScript("OnShow", function()
        if SynapseNS.cfg then SyncFromConfig() end
    end)

    -- Register with UISpecialFrames so ESC closes it like any native panel
    table.insert(UISpecialFrames, "SynapseConfigFrame")

    -- Background
    local mainBg = MakeRect(configFrame, "BACKGROUND", C.bg)
    mainBg:SetAllPoints()

    -- Teal 1-px border
    local function BorderEdge(point, w, h)
        local t = configFrame:CreateTexture(nil, "BORDER")
        FillColor(t, C.border)
        t:SetSize(w, h)
        t:SetPoint(point, configFrame, point, 0, 0)
    end
    BorderEdge("TOPLEFT",    WIN_W, 1)
    BorderEdge("BOTTOMLEFT", WIN_W, 1)
    BorderEdge("TOPLEFT",    1, WIN_H)
    BorderEdge("TOPRIGHT",   1, WIN_H)

    -- â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local header = CreateFrame("Frame", nil, configFrame)
    header:SetSize(WIN_W, HEADER_H)
    header:SetPoint("TOPLEFT")
    MakeRect(header, "BACKGROUND", { 0.03, 0.05, 0.06, 1.0 }):SetAllPoints()

    -- Bottom accent line + glow
    local hLine = MakeRect(header, "ARTWORK", C.accent)
    hLine:SetSize(WIN_W, 1)
    hLine:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    local hGlow = header:CreateTexture(nil, "BACKGROUND")
    hGlow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.07)
    hGlow:SetSize(WIN_W, 18)
    hGlow:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)

    -- Logo dot
    local dot = MakeRect(header, "ARTWORK", C.accent)
    dot:SetSize(8, 8)
    dot:SetPoint("LEFT", header, "LEFT", 18, 4)
    local dotRing = header:CreateTexture(nil, "BORDER")
    dotRing:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.28)
    dotRing:SetSize(18, 18)
    dotRing:SetPoint("CENTER", dot, "CENTER")

    -- Title + subtitle
    local titleTxt = MakeText(header, "Synapse", "GameFontNormalLarge", C.title, "OVERLAY")
    titleTxt:SetPoint("LEFT", header, "LEFT", 36, 8)
    titleTxt:SetFont(titleTxt:GetFont(), 20, "")
    local subTxt = MakeText(header, "Settings", "GameFontNormalSmall", C.hint, "OVERLAY")
    subTxt:SetPoint("TOPLEFT", titleTxt, "BOTTOMLEFT", 0, -2)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, configFrame)
    closeBtn:SetSize(22, 22)
    closeBtn:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -8, -8)
    local closeBg = MakeRect(closeBtn, "ARTWORK", C.closeBtn)
    closeBg:SetAllPoints()
    local closeTxt = MakeText(closeBtn, "x", "GameFontNormalSmall", C.title, "OVERLAY")
    closeTxt:SetAllPoints()
    closeTxt:SetJustifyH("CENTER")
    closeTxt:SetJustifyV("MIDDLE")
    closeBtn:SetScript("OnClick", function() configFrame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeBg:SetAlpha(0.70) end)
    closeBtn:SetScript("OnLeave", function() closeBg:SetAlpha(1.00) end)

    -- â”€â”€ Scroll area â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local scrollFrame = CreateFrame("ScrollFrame", nil, configFrame)
    scrollFrame:SetPoint("TOPLEFT",     configFrame, "TOPLEFT",      0,           -HEADER_H)
    scrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -(CFG_SB_W + 4), FOOTER_H)

    local panel = CreateFrame("Frame", nil, scrollFrame)
    panel:SetWidth(WIN_W - CFG_SB_W - 4)
    scrollFrame:SetScrollChild(panel)

    -- Mouse-wheel: small step (20px) for smooth scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 20)))
        if cfgUpdateScrollbar then cfgUpdateScrollbar() end
    end)

    -- ── Main config scrollbar (same style as rotation list) ─────────────
    local cfgSbTrack = CreateFrame("Frame", nil, configFrame)
    cfgSbTrack:SetPoint("TOPLEFT",     configFrame, "TOPRIGHT",    -(CFG_SB_W), -HEADER_H)
    cfgSbTrack:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT",  0,           FOOTER_H)
    MakeRect(cfgSbTrack, "BACKGROUND", { 0.12, 0.14, 0.16, 1.0 }):SetAllPoints()

    local cfgSbThumb = CreateFrame("Button", nil, cfgSbTrack)
    cfgSbThumb:SetSize(CFG_SB_W, 40)
    cfgSbThumb:SetPoint("TOPLEFT", cfgSbTrack, "TOPLEFT", 0, 0)
    MakeRect(cfgSbThumb, "ARTWORK", { 0.35, 0.75, 0.65, 0.85 }):SetAllPoints()
    cfgSbThumb:RegisterForDrag("LeftButton")
    cfgSbThumb:SetMovable(true)

    local cfgDragStartY, cfgDragStartScroll = 0, 0
    local cfgDragging = false
    cfgSbThumb:SetScript("OnDragStart", function(self)
        cfgDragging        = true
        cfgDragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        cfgDragStartScroll = scrollFrame:GetVerticalScroll()
    end)
    cfgSbThumb:SetScript("OnDragStop", function() cfgDragging = false end)
    cfgSbThumb:SetScript("OnUpdate", function(self)
        if not cfgDragging then return end
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if maxScroll <= 0 then return end
        local trackH = cfgSbTrack:GetHeight()
        local thumbH = self:GetHeight()
        local travel = trackH - thumbH
        if travel <= 0 then return end
        local curY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local dy        = cfgDragStartY - curY
        local newScroll = cfgDragStartScroll + (dy / travel) * maxScroll
        scrollFrame:SetVerticalScroll(math.max(0, math.min(maxScroll, newScroll)))
        if cfgUpdateScrollbar then cfgUpdateScrollbar() end
    end)

    cfgUpdateScrollbar = function()
        local trackH    = cfgSbTrack:GetHeight()
        if trackH <= 0 then return end
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        if maxScroll <= 0 then
            cfgSbThumb:Hide()
            return
        end
        cfgSbThumb:Show()
        local viewH  = scrollFrame:GetHeight()
        local total  = viewH + maxScroll
        local ratio  = viewH / total
        local thumbH = math.max(16, math.floor(trackH * ratio))
        local travel = trackH - thumbH
        local cur    = scrollFrame:GetVerticalScroll()
        local top    = -(travel * (cur / maxScroll))
        cfgSbThumb:SetHeight(thumbH)
        cfgSbThumb:ClearAllPoints()
        cfgSbThumb:SetPoint("TOPLEFT", cfgSbTrack, "TOPLEFT", 0, top)
    end

    local y = -10  -- running y cursor

    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    -- SETUP
    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    MakeSectionHeader(panel, "SETUP", COL1_X, y)
    y = y - 24

    local hintTxt = MakeText(panel, nil, "GameFontNormalSmall", C.hint, "OVERLAY")
    hintTxt:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X + 2, y)
    hintTxt:SetWidth(WIN_W - 40)
    hintTxt:SetJustifyH("LEFT")
    hintTxt:SetText("First place |cFF00C8A0Assisted Combat|r (from Spellbook) on any action bar, then click the button below and click that slot.")
    y = y - 22

    local slotRow = MakeRow(panel, "Mirrored slot:", COL1_X, y, WIN_W - 36)
    pickBtn = CreateFrame("Button", nil, slotRow)
    pickBtn:SetSize(380, 24)
    pickBtn:SetPoint("RIGHT", slotRow, "RIGHT", -8, 0)
    local pickBtnBg = MakeRect(pickBtn, "ARTWORK", C.accentDim)
    pickBtnBg:SetAllPoints()
    local pickBtnTxt = MakeText(pickBtn, "Click to pick action bar slot...", "GameFontNormalSmall", C.title, "OVERLAY")
    pickBtnTxt:SetAllPoints()
    pickBtnTxt:SetJustifyH("CENTER")
    pickBtnTxt:SetJustifyV("MIDDLE")
    pickBtn:SetScript("OnClick", function()
        configFrame:Hide()
        EnterPickMode()
    end)
    pickBtn:SetScript("OnEnter", function() pickBtnBg:SetAlpha(0.70) end)
    pickBtn:SetScript("OnLeave", function() pickBtnBg:SetAlpha(1.00) end)
    pickBtn.SetText = function(_, t) pickBtnTxt:SetText(t) end
    y = y - ROW_H - 8

    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    -- DISPLAY
    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    MakeSectionHeader(panel, "DISPLAY", COL1_X, y)
    y = y - 24

    -- row 1  (Cooldown countdown — greyed out, in development)
    local cdRow = MakeRow(panel, "Cooldown countdown", COL1_X, y, COL_W)
    -- Dim the label to hint colour so it reads as disabled
    cdRow:GetChildren()  -- ensure children exist before iterating
    for _, child in ipairs({ cdRow:GetRegions() }) do
        if child.SetTextColor then
            child:SetTextColor(C.hint[1], C.hint[2], C.hint[3], C.hint[4])
        end
    end
    -- Frozen toggle (always off-state, non-interactive)
    local cdTog = MakeToggle(cdRow, COL_W - TOGGLE_W - 8, -(ROW_H - TOGGLE_H) / 2, nil)
    cdTog:SetChecked(false)
    cdTog:EnableMouse(false)
    cdTog:SetAlpha(0.35)
    togCooldown = cdTog
    -- "in development" label sits just below the row
    local devLbl = MakeText(panel, "|cFFFFAA00in development|r", "GameFontNormalSmall", C.hint, "OVERLAY")
    devLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X + 10, y - ROW_H)
    y = y - ROW_H - 18

    -- Scale slider
    local _, sScale = SliderRow(panel, "Scale", COL1_X, y, COL_W, 0.5, 3.0, 0.1, function(v)
        SynapseNS.cfg.scale = v; SynapseNS.ApplyScale(v)
    end)
    sliderScale = sScale
    y = y - ROW_H - 8

    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    -- OPACITY
    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    MakeSectionHeader(panel, "OPACITY", COL1_X, y)
    y = y - 24

    local _, sC = SliderRow(panel, "In combat",     COL1_X, y, COL_W, 0, 1, 0.05, function(v) SynapseNS.cfg.opacityCombat   = v; SynapseNS.RefreshDisplay() end)
    sliderCombat = sC
    local _, sN = SliderRow(panel, "Out of combat", COL2_X, y, COL_W, 0, 1, 0.05, function(v) SynapseNS.cfg.opacityNoCombat = v; SynapseNS.RefreshDisplay() end)
    sliderNoCombat = sN
    y = y - ROW_H - 8

    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    -- BEHAVIOUR
    -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    MakeSectionHeader(panel, "BEHAVIOUR", COL1_X, y)
    y = y - 24

    local _, t5 = ToggleRow(panel, "Click-through",           COL1_X, y, COL_W, function(v)
        SynapseNS.cfg.clickThrough = v
        if SynapseNS.ApplyClickThrough then SynapseNS.ApplyClickThrough(v) end
    end)
    togClickThrough = t5
    y = y - ROW_H

    local _, t7 = ToggleRow(panel, "Lock frame position",     COL1_X, y, COL_W, function(v) SynapseNS.cfg.locked = v; SynapseNS.LockFrame(v) end)
    togLocked = t7
    y = y - ROW_H - 8

    -- ══════════════════════════════════════════════════════════════
    -- ROTATION
    -- ══════════════════════════════════════════════════════════════
    MakeSectionHeader(panel, "ROTATION", COL1_X, y)
    y = y - 24

    -- Enable Playback toggle (full width so label has room)
    local _, togPb = ToggleRow(panel, "Enable playback mode", COL1_X, y, WIN_W - 36, function(v)
        SynapseNS.EnablePlayback(v)
    end)
    togPlayback = togPb
    y = y - ROW_H - 8

    -- ── Active rotation list ─────────────────────────────────────────────
    local rotHdr = MakeText(panel,
        "Active rotation \226\128\148 reorder or remove spells:",
        "GameFontNormalSmall", C.hint, "OVERLAY")
    rotHdr:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X + 2, y)
    y = y - 16

    local ROT_LIST_H = ROT_ROW_H * 6   -- fixed visible height (6 rows)
    local rotScrollFrame = CreateFrame("ScrollFrame", nil, panel)
    rotScrollFrame:SetSize(ROT_INNER_W, ROT_LIST_H)
    rotScrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X, y)

    rotListAnchor = CreateFrame("Frame", nil, rotScrollFrame)
    rotListAnchor:SetSize(ROT_INNER_W, ROT_ROW_H)
    rotScrollFrame:SetScrollChild(rotListAnchor)

    -- Scrollbar
    local sbTrack = CreateFrame("Frame", nil, panel)
    sbTrack:SetSize(ROT_SB_W, ROT_LIST_H)
    sbTrack:SetPoint("TOPLEFT", rotScrollFrame, "TOPRIGHT", 4, 0)
    MakeRect(sbTrack, "BACKGROUND", { 0.12, 0.14, 0.16, 1.0 }):SetAllPoints()

    local sbThumb = CreateFrame("Button", nil, sbTrack)
    sbThumb:SetSize(ROT_SB_W, ROT_LIST_H)
    sbThumb:SetPoint("TOPLEFT", sbTrack, "TOPLEFT", 0, 0)
    MakeRect(sbThumb, "ARTWORK", { 0.35, 0.75, 0.65, 0.85 }):SetAllPoints()
    sbThumb:RegisterForDrag("LeftButton")
    sbThumb:SetMovable(true)

    local dragStartY, dragStartScroll = 0, 0
    local rotDragging = false
    sbThumb:SetScript("OnDragStart", function(self)
        rotDragging     = true
        dragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartScroll = rotScrollFrame:GetVerticalScroll()
    end)
    sbThumb:SetScript("OnDragStop", function() rotDragging = false end)
    sbThumb:SetScript("OnUpdate", function(self)
        if not rotDragging then return end
        local maxScroll = rotScrollFrame:GetVerticalScrollRange()
        if maxScroll <= 0 then return end
        local thumbH = self:GetHeight()
        local travel = ROT_LIST_H - thumbH
        if travel <= 0 then return end
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local dy     = dragStartY - curY
        local newScroll = dragStartScroll + (dy / travel) * maxScroll
        rotScrollFrame:SetVerticalScroll(math.max(0, math.min(maxScroll, newScroll)))
        rotUpdateScrollbar()
    end)

    rotUpdateScrollbar = function()
        local maxScroll = rotScrollFrame:GetVerticalScrollRange()
        if maxScroll <= 0 then
            sbThumb:SetHeight(ROT_LIST_H)
            sbThumb:SetPoint("TOPLEFT", sbTrack, "TOPLEFT", 0, 0)
            sbThumb:Hide()
            return
        end
        sbThumb:Show()
        local ratio    = ROT_LIST_H / (ROT_LIST_H + maxScroll)
        local thumbH   = math.max(16, math.floor(ROT_LIST_H * ratio))
        local travel   = ROT_LIST_H - thumbH
        local cur      = rotScrollFrame:GetVerticalScroll()
        local thumbTop = -(travel * (cur / maxScroll))
        sbThumb:SetHeight(thumbH)
        sbThumb:ClearAllPoints()
        sbThumb:SetPoint("TOPLEFT", sbTrack, "TOPLEFT", 0, thumbTop)
    end

    rotScrollFrame:EnableMouseWheel(true)
    rotScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * ROT_ROW_H * 2)))
        rotUpdateScrollbar()
    end)

    rotEmptyLbl = MakeText(rotListAnchor,
        "No rotation recorded. Use Record Rotation below or load a profile.",
        "GameFontNormalSmall", C.hint, "OVERLAY")
    rotEmptyLbl:SetPoint("TOPLEFT", rotListAnchor, "TOPLEFT", 4, -6)
    rotEmptyLbl:SetWidth(ROT_INNER_W - 8)
    rotEmptyLbl:SetJustifyH("LEFT")

    y = y - ROT_LIST_H - 12

    -- ── Record Rotation ──────────────────────────────────────────────────
    local recRow = CreateFrame("Frame", nil, panel)
    recRow:SetSize(WIN_W - 36, ROW_H)
    recRow:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X, y)

    recordBtn = CreateFrame("Button", nil, recRow)
    recordBtn:SetSize(220, 26)
    recordBtn:SetPoint("LEFT", recRow, "LEFT", 0, 0)
    local recBtnBg  = MakeRect(recordBtn, "ARTWORK", C.accentDim)
    recBtnBg:SetAllPoints()
    local recBtnTxt = MakeText(recordBtn, "|TInterface\\Icons\\INV_Misc_StopWatch_01:14|t Record Rotation", "GameFontNormalSmall", C.title, "OVERLAY")
    recBtnTxt:SetAllPoints()
    recBtnTxt:SetJustifyH("CENTER")
    recBtnTxt:SetJustifyV("MIDDLE")
    recordBtn:SetScript("OnEnter", function() recBtnBg:SetAlpha(0.70) end)
    recordBtn:SetScript("OnLeave", function() recBtnBg:SetAlpha(1.00) end)
    recordBtn:SetScript("OnClick", function()
        if SynapseNS.recordMode then SynapseNS.StopRecording()
        else SynapseNS.StartRecording() end
    end)
    recordBtn._bg  = recBtnBg
    recordBtn._txt = recBtnTxt

    recordStatusLbl = MakeText(recRow, "No rotation recorded.", "GameFontNormalSmall", C.hint, "OVERLAY")
    recordStatusLbl:SetPoint("LEFT", recordBtn, "RIGHT", 10, 0)
    recordStatusLbl:SetWidth(WIN_W - 36 - 220 - 10)
    recordStatusLbl:SetJustifyH("LEFT")
    y = y - ROW_H - 12

    -- ── Profiles dropdown ────────────────────────────────────────────────
    MakeSectionHeader(panel, "PROFILES", COL1_X, y)
    y = y - 28

    -- Row 1: dropdown + Load + Save + Delete
    local DROPDOWN_W = WIN_W - 36 - 60 - 60 - 64 - 24  -- leaves room for 3 buttons
    local ddRow = CreateFrame("Frame", nil, panel)
    ddRow:SetSize(WIN_W - 36, ROT_ROW_H)
    ddRow:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X, y)

    -- Dropdown button
    local ddBtn = CreateFrame("Button", nil, ddRow)
    ddBtn:SetSize(DROPDOWN_W, 24)
    ddBtn:SetPoint("LEFT", ddRow, "LEFT", 0, 0)
    MakeRect(ddBtn, "BACKGROUND", { 0.10, 0.12, 0.14, 1.0 }):SetAllPoints()
    local ddBorder = MakeRect(ddBtn, "BORDER", C.border)
    ddBorder:SetSize(DROPDOWN_W, 1)
    ddBorder:SetPoint("BOTTOMLEFT", ddBtn, "BOTTOMLEFT")

    profileDropdownTxt = MakeText(ddBtn, "-- select profile --", "GameFontNormal", C.label, "OVERLAY")
    profileDropdownTxt:SetPoint("LEFT",  ddBtn, "LEFT",  8, 0)
    profileDropdownTxt:SetPoint("RIGHT", ddBtn, "RIGHT", -20, 0)
    profileDropdownTxt:SetJustifyH("LEFT")

    local ddArrow = ddBtn:CreateTexture(nil, "OVERLAY")
    ddArrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    ddArrow:SetSize(14, 12)
    ddArrow:SetPoint("RIGHT", ddBtn, "RIGHT", -5, 0)

    -- Load button
    local function MakeActionBtn(parent, label, xRight, color)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(56, 24)
        btn:SetPoint("RIGHT", parent, "RIGHT", xRight, 0)
        local bg = MakeRect(btn, "ARTWORK", color or C.accentDim)
        bg:SetAllPoints()
        local txt = MakeText(btn, label, "GameFontNormalSmall", C.title, "OVERLAY")
        txt:SetAllPoints(); txt:SetJustifyH("CENTER"); txt:SetJustifyV("MIDDLE")
        btn:SetScript("OnEnter", function() bg:SetAlpha(0.70) end)
        btn:SetScript("OnLeave", function() bg:SetAlpha(1.00) end)
        return btn
    end

    local ddDeleteBtn = MakeActionBtn(ddRow, "Delete", -4,   { 0.45, 0.12, 0.10, 1.0 })
    local ddSaveBtn   = MakeActionBtn(ddRow, "Save",   -64,  C.accentDim)
    local ddLoadBtn   = MakeActionBtn(ddRow, "Load",   -124, C.accentDim)

    -- Popup list (parented to configFrame so it overlaps other panel content)
    profileDropdownPopup = CreateFrame("Frame", nil, configFrame)
    profileDropdownPopup:SetFrameStrata("FULLSCREEN")
    profileDropdownPopup:SetFrameLevel(80)
    profileDropdownPopup:Hide()
    MakeRect(profileDropdownPopup, "BACKGROUND", { 0.06, 0.08, 0.09, 0.98 }):SetAllPoints()
    local popupBorder = MakeRect(profileDropdownPopup, "BORDER", C.border)
    popupBorder:SetAllPoints()

    -- Holds popup item buttons; rebuilt each time popup opens
    local popupItems = {}

    local function CloseDropdown()
        profileDropdownPopup:Hide()
        profileDropdownPopup:SetScript("OnHide", nil)
    end

    local function OpenDropdown()
        -- Clear old items
        for _, item in ipairs(popupItems) do item:Hide() end
        popupItems = {}

        local names = SynapseNS.GetProfiles()
        if #names == 0 then return end  -- nothing to show

        local itemH = 24
        profileDropdownPopup:SetWidth(DROPDOWN_W)
        profileDropdownPopup:SetHeight(#names * itemH + 4)

        -- Position popup below the dropdown button
        profileDropdownPopup:ClearAllPoints()
        profileDropdownPopup:SetPoint("TOPLEFT", ddBtn, "BOTTOMLEFT", 0, -2)

        for i, name in ipairs(names) do
            local item = CreateFrame("Button", nil, profileDropdownPopup)
            item:SetSize(DROPDOWN_W, itemH)
            item:SetPoint("TOPLEFT", profileDropdownPopup, "TOPLEFT", 0, -(i - 1) * itemH - 2)
            local itemBg = MakeRect(item, "BACKGROUND", { 0.06, 0.08, 0.09, 0.0 })
            itemBg:SetAllPoints()
            local itemTxt = MakeText(item, name, "GameFontNormal", C.label, "OVERLAY")
            itemTxt:SetPoint("LEFT", item, "LEFT", 8, 0)
            item:SetScript("OnEnter", function() FillColor(itemBg, C.rowAlt) end)
            item:SetScript("OnLeave", function() FillColor(itemBg, { 0.06, 0.08, 0.09, 0.0 }) end)
            local capName = name
            item:SetScript("OnClick", function()
                profileSelected = capName
                profileDropdownTxt:SetText(capName)
                CloseDropdown()
            end)
            popupItems[i] = item
        end

        profileDropdownPopup:Show()
        -- Close when clicking anywhere outside
        profileDropdownPopup:SetScript("OnHide", nil)
    end

    ddBtn:SetScript("OnClick", function()
        if profileDropdownPopup:IsShown() then
            CloseDropdown()
        else
            OpenDropdown()
        end
    end)

    -- Close popup when config frame is hidden
    configFrame:HookScript("OnHide", function() CloseDropdown() end)

    -- Load
    ddLoadBtn:SetScript("OnClick", function()
        if not profileSelected then return end
        SynapseNS.LoadProfile(profileSelected)
        RefreshRotationList()
    end)

    -- Save (overwrite selected profile with current rotation)
    ddSaveBtn:SetScript("OnClick", function()
        if not profileSelected then return end
        SynapseNS.SaveProfile(profileSelected)
        RefreshProfileDropdown()
    end)

    -- Delete
    ddDeleteBtn:SetScript("OnClick", function()
        if not profileSelected then return end
        SynapseNS.DeleteProfile(profileSelected)
        profileSelected = nil
        RefreshProfileDropdown()
    end)

    y = y - ROT_ROW_H - 4

    -- Row 2: new profile name input + Save New button
    local newRow = CreateFrame("Frame", nil, panel)
    newRow:SetSize(WIN_W - 36, ROT_ROW_H)
    newRow:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X, y)

    local newOuter = CreateFrame("Frame", nil, newRow)
    newOuter:SetSize(DROPDOWN_W, 24)
    newOuter:SetPoint("LEFT", newRow, "LEFT", 0, 0)
    MakeRect(newOuter, "BACKGROUND", { 0.10, 0.12, 0.14, 1.0 }):SetAllPoints()
    local newBorder = MakeRect(newOuter, "BORDER", C.border)
    newBorder:SetSize(DROPDOWN_W, 1)
    newBorder:SetPoint("BOTTOMLEFT", newOuter, "BOTTOMLEFT")

    local newPh = MakeText(newOuter, "New profile name\226\128\166", "GameFontNormal", C.hint, "OVERLAY")
    newPh:SetPoint("LEFT", newOuter, "LEFT", 8, 0)

    profileNameBox = CreateFrame("EditBox", nil, newOuter)
    profileNameBox:SetSize(newOuter:GetWidth() - 12, 20)
    profileNameBox:SetPoint("LEFT", newOuter, "LEFT", 6, 0)
    profileNameBox:SetFontObject("GameFontNormal")
    profileNameBox:SetTextColor(C.label[1], C.label[2], C.label[3], 1)
    profileNameBox:SetAutoFocus(false)
    profileNameBox:EnableMouse(true)
    profileNameBox:EnableKeyboard(true)
    profileNameBox:SetMaxLetters(48)
    profileNameBox:SetScript("OnTextChanged", function(self) newPh:SetShown(self:GetText() == "") end)
    profileNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local function DoSaveNew()
        local name = profileNameBox:GetText():match("^%s*(.-)%s*$")
        if not name or name == "" then return end
        SynapseNS.SaveProfile(name)
        profileSelected = name
        profileNameBox:SetText(""); newPh:Show()
        RefreshProfileDropdown()
    end
    profileNameBox:SetScript("OnEnterPressed", function() DoSaveNew() end)

    local saveNewBtn = CreateFrame("Button", nil, newRow)
    saveNewBtn:SetSize(56, 24)
    saveNewBtn:SetPoint("LEFT", newOuter, "RIGHT", 8, 0)
    local saveNewBg = MakeRect(saveNewBtn, "ARTWORK", C.accentDim)
    saveNewBg:SetAllPoints()
    local saveNewTxt = MakeText(saveNewBtn, "Save New", "GameFontNormalSmall", C.title, "OVERLAY")
    saveNewTxt:SetAllPoints(); saveNewTxt:SetJustifyH("CENTER"); saveNewTxt:SetJustifyV("MIDDLE")
    saveNewBtn:SetScript("OnEnter", function() saveNewBg:SetAlpha(0.70) end)
    saveNewBtn:SetScript("OnLeave", function() saveNewBg:SetAlpha(1.00) end)
    saveNewBtn:SetScript("OnClick", DoSaveNew)

    y = y - ROT_ROW_H - 12

    -- ── Spell search ───────────────────────────────────────────────────────
    MakeSectionHeader(panel, "SPELL SEARCH \226\128\148 add spells to rotation", COL1_X, y)
    y = y - 28

    local searchOuter = CreateFrame("Frame", nil, panel)
    searchOuter:SetSize(WIN_W - 36, 26)
    searchOuter:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X, y)
    MakeRect(searchOuter, "BACKGROUND", { 0.10, 0.12, 0.14, 1.0 }):SetAllPoints()
    local searchBorderTex = MakeRect(searchOuter, "BORDER", C.border)
    searchBorderTex:SetSize(WIN_W - 36, 1)
    searchBorderTex:SetPoint("BOTTOMLEFT", searchOuter, "BOTTOMLEFT")

    local phLbl = MakeText(searchOuter, "Search spells\226\128\166", "GameFontNormal", C.hint, "OVERLAY")
    phLbl:SetPoint("LEFT", searchOuter, "LEFT", 8, 0)

    searchBox = CreateFrame("EditBox", "SynapseSearchBox", searchOuter)
    searchBox:SetSize(WIN_W - 36 - 8, 20)
    searchBox:SetPoint("LEFT", searchOuter, "LEFT", 6, 0)
    searchBox:SetFontObject("GameFontNormal")
    searchBox:SetTextColor(C.label[1], C.label[2], C.label[3], 1)
    searchBox:SetAutoFocus(false)
    searchBox:EnableMouse(true)
    searchBox:EnableKeyboard(true)
    searchBox:SetMaxLetters(64)
    searchBox:SetScript("OnTextChanged", function(self)
        phLbl:SetShown(self:GetText() == "")
        RefreshSearchResults()
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    y = y - 26 - 6

    searchResultsAnchor = CreateFrame("Frame", nil, panel)
    searchResultsAnchor:SetPoint("TOPLEFT", panel, "TOPLEFT", COL1_X, y)
    searchResultsAnchor:SetSize(WIN_W - 36, SRCH_ROW_H)
    searchEmptyLbl = MakeText(searchResultsAnchor,
        "Type to search your character\226\128\153s spells.",
        "GameFontNormalSmall", C.hint, "OVERLAY")
    searchEmptyLbl:SetPoint("TOPLEFT", searchResultsAnchor, "TOPLEFT", 4, -6)
    y = y - SRCH_ROW_H * 8 - 12

    panel:SetHeight(math.abs(y) + 16)
    if cfgUpdateScrollbar then cfgUpdateScrollbar() end

    -- ── Record state hook ─────────────────────────────────────────────────
    -- Invoked by Core.lua on StartRecording / StopRecording / EnablePlayback
    SynapseNS.OnRecordStateChange = function()
        if not recordBtn then return end
        if SynapseNS.recordMode then
            FillColor(recordBtn._bg, { 0.55, 0.15, 0.12, 1.0 })
            recordBtn._txt:SetText("|TInterface\\Icons\\INV_Misc_StopWatch_01:14|t Stop Recording")
        else
            FillColor(recordBtn._bg, C.accentDim)
            recordBtn._txt:SetText("|TInterface\\Icons\\INV_Misc_StopWatch_01:14|t Record Rotation")
        end
        local charCfg = SynapseNS.charCfg
        local count = SynapseNS.recordMode
            and #SynapseNS.recordedSpells
            or (charCfg and #(charCfg.rotation or {}) or 0)
        if SynapseNS.recordMode then
            recordStatusLbl:SetText("Recording\226\128\166 " .. count .. " spell(s) captured")
        elseif count > 0 then
            recordStatusLbl:SetText(count .. " spell(s) recorded")
        else
            recordStatusLbl:SetText("No rotation recorded.")
        end
        if togPlayback and charCfg then
            togPlayback:SetChecked(charCfg.playback or false)
        end
        RefreshRotationList()
        RefreshProfileDropdown()
    end

    -- â”€â”€ Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    local footer = CreateFrame("Frame", nil, configFrame)
    footer:SetSize(WIN_W, FOOTER_H)
    footer:SetPoint("BOTTOMLEFT")
    MakeRect(footer, "BACKGROUND", { 0.03, 0.05, 0.06, 1.0 }):SetAllPoints()
    local fLine = MakeRect(footer, "ARTWORK", C.accent)
    fLine:SetSize(WIN_W, 1)
    fLine:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, 0)

    local function FooterBtn(label, ax, aw, isAccent, onClick)
        local btn = CreateFrame("Button", nil, footer)
        btn:SetSize(aw, 26)
        btn:SetPoint("LEFT", footer, "LEFT", ax, 0)
        local bg = MakeRect(btn, "BACKGROUND", isAccent and C.accent or C.accentDim)
        bg:SetAllPoints()
        local txt = MakeText(btn, label, "GameFontNormalSmall", C.title, "OVERLAY")
        txt:SetAllPoints(); txt:SetJustifyH("CENTER"); txt:SetJustifyV("MIDDLE")
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function() bg:SetAlpha(0.70) end)
        btn:SetScript("OnLeave", function() bg:SetAlpha(1.00) end)
    end

    FooterBtn("Reset Position", 14, 130, false, function()
        SynapseNS.ResetPosition()
        print("|cFF00C8FFSynapse|r: frame position reset.")
    end)
    FooterBtn("Done", WIN_W - 14 - 80, 80, true, function() configFrame:Hide() end)

    RegisterBlizzardPanel()
end

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  OpenConfig
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
function SynapseNS.OpenConfig()
    if not SynapseNS.cfg then
        print("|cFF00C8FFSynapse|r: configuration not yet loaded.")
        return
    end
    if not initialized then SynapseNS.InitConfig() end
    if configFrame:IsShown() then
        configFrame:Hide()
    else
        SyncFromConfig()
        configFrame:Show()
    end
end

-- -------------------------------------------------------------
--  Blizzard Settings registration
--  A minimal canvas panel with a single "Open Synapse Settings"
--  button — keeps our own window independent.
-- -------------------------------------------------------------
RegisterBlizzardPanel = function()
    local panel = CreateFrame("Frame")
    panel.name  = "Synapse"

    panel:SetScript("OnShow", function(self)
        if self._built then return end
        self._built = true

        local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("Synapse")

        local sub = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        sub:SetTextColor(0.55, 0.60, 0.62, 1)
        sub:SetText("Assisted Combat display addon")

        local btn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        btn:SetSize(200, 26)
        btn:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
        btn:SetText("Open Synapse Settings")
        btn:SetScript("OnClick", function()
            -- Close the Blizzard settings panel first, then open ours
            if SettingsPanel and SettingsPanel:IsShown() then
                HideUIPanel(SettingsPanel)
            elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
                HideUIPanel(InterfaceOptionsFrame)
            end
            SynapseNS.OpenConfig()
        end)
    end)

    pcall(function()
        if Settings and Settings.RegisterCanvasLayoutCategory then
            local cat = Settings.RegisterCanvasLayoutCategory(panel, "Synapse")
            Settings.RegisterAddOnCategory(cat)
        elseif InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
    end)
end


