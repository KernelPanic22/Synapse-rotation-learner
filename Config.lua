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
local WIN_H     = 500
local HEADER_H  = 64
local FOOTER_H  = 44
local COL_W     = 288
local COL_GAP   = 20
local COL1_X    = 18
local COL2_X    = COL1_X + COL_W + COL_GAP
local ROW_H     = 36
local TOGGLE_W  = 44
local TOGGLE_H  = 22
local SLIDER_W  = 120

-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
--  STATE
-- â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local initialized = false
local configFrame
local pickBtn
local pickOverlay
local pickBtnRefs = {}
local togRangeTint, togCooldown, togResourceCost
local togFadeOnTarget, togClickThrough, togLocked
local sliderScale, sliderCombat, sliderNoCombat

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
-- ─────────────────────────────────────────────────────────────
local BARS = {
    { prefix = "ActionButton",              offset = 0  },
    { prefix = "MultiBar5Button",           offset = 12 },
    { prefix = "MultiBarBottomLeftButton",  offset = 24 },
    { prefix = "MultiBarBottomRightButton", offset = 36 },
    { prefix = "MultiBarRightButton",       offset = 48 },
    { prefix = "MultiBarLeftButton",        offset = 60 },
}

local ExitPickMode  -- forward declaration

local function EnterPickMode()
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
            "|cFF00C8A0Click any action bar button to mirror as your Assisted Combat slot.|r\n"
         .. "|cFFAAAAAARRight-click or Escape to cancel.|r")
        pickOverlay:EnableMouse(true)
        pickOverlay:EnableKeyboard(true)
        pickOverlay:SetPropagateKeyboardInput(false)
        pickOverlay:SetScript("OnKeyDown",   function(_, k)   if k == "ESCAPE"        then ExitPickMode(nil) end end)
        pickOverlay:SetScript("OnMouseDown", function(_, btn) if btn == "RightButton" then ExitPickMode(nil) end end)
    end
    pickOverlay:Show()

    for _, bar in ipairs(BARS) do
        for i = 1, 12 do
            local slot = bar.offset + i
            local src  = _G[bar.prefix .. i]
            if src and src:IsVisible() then
                local ovr = CreateFrame("Button", nil, UIParent)
                ovr:SetAllPoints(src)
                ovr:SetFrameStrata("TOOLTIP")
                ovr:SetFrameLevel(50)
                local hl = ovr:CreateTexture(nil, "ARTWORK")
                hl:SetAllPoints()
                hl:SetColorTexture(0, 0.78, 0.63, 0.35)
                local lbl = ovr:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                lbl:SetAllPoints()
                lbl:SetText(tostring(slot))
                lbl:SetJustifyH("CENTER")
                lbl:SetJustifyV("MIDDLE")
                ovr:SetScript("OnClick",  function() ExitPickMode(slot) end)
                ovr:SetScript("OnEnter",  function() hl:SetColorTexture(0, 0.78, 0.63, 0.75) end)
                ovr:SetScript("OnLeave",  function() hl:SetColorTexture(0, 0.78, 0.63, 0.35) end)
                table.insert(pickBtnRefs, ovr)
            end
        end
    end
end

ExitPickMode = function(selectedSlot)
    if pickOverlay then pickOverlay:Hide() end
    for _, b in ipairs(pickBtnRefs) do b:Hide() end
    pickBtnRefs = {}
    if selectedSlot then
        SynapseNS.cfg.mirrorSlot = selectedSlot
        SynapseNS.SetMirrorSlot(selectedSlot)
        SynapseNS.RefreshDisplay()
    end
    configFrame:Show()  -- triggers OnShow -> SyncFromConfig
end

local function SyncFromConfig()
    local cfg = SynapseNS.cfg
    if not cfg then return end
    local slot = cfg.mirrorSlot or 0
    pickBtn:SetText(slot > 0 and ("Slot " .. slot .. "  \226\128\148  click to change") or "Click to pick action bar slot...")
    togRangeTint:SetChecked(cfg.showRangeTint)
    togCooldown:SetChecked(cfg.showCooldownText)
    togResourceCost:SetChecked(cfg.showResourceCost)
    togFadeOnTarget:SetChecked(cfg.fadeOnTarget)
    togClickThrough:SetChecked(cfg.clickThrough)
    togLocked:SetChecked(cfg.locked)
    sliderScale:SetValue(cfg.scale or 1.0)
    sliderCombat:SetValue(cfg.opacityCombat or 1.0)
    sliderNoCombat:SetValue(cfg.opacityNoCombat or 0.8)
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
    local scrollFrame = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     configFrame, "TOPLEFT",      0, -HEADER_H)
    scrollFrame:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -18,  FOOTER_H)

    local panel = CreateFrame("Frame", nil, scrollFrame)
    panel:SetWidth(WIN_W - 18)
    scrollFrame:SetScrollChild(panel)

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

    -- row 1
    local _, t2 = ToggleRow(panel, "Show range tint",        COL1_X, y, COL_W, function(v) SynapseNS.cfg.showRangeTint   = v; SynapseNS.RefreshDisplay() end)
    togRangeTint = t2
    local _, t3 = ToggleRow(panel, "Cooldown countdown",     COL2_X, y, COL_W, function(v)
        SynapseNS.cfg.showCooldownText = v
        if SynapseNS.ApplyCooldownText then SynapseNS.ApplyCooldownText(v) end
    end)
    togCooldown = t3
    y = y - ROW_H - 4

    -- row 2
    local _, t4 = ToggleRow(panel, "Resource cost (tooltip)", COL1_X, y, COL_W, function(v) SynapseNS.cfg.showResourceCost = v end)
    togResourceCost = t4
    y = y - ROW_H - 4

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

    local _, t5 = ToggleRow(panel, "Fade when no target",     COL1_X, y, COL_W, function(v) SynapseNS.cfg.fadeOnTarget = v end)
    togFadeOnTarget = t5
    local _, t6 = ToggleRow(panel, "Click-through",           COL2_X, y, COL_W, function(v)
        SynapseNS.cfg.clickThrough = v
        if SynapseNS.ApplyClickThrough then SynapseNS.ApplyClickThrough(v) end
    end)
    togClickThrough = t6
    y = y - ROW_H

    local _, t7 = ToggleRow(panel, "Lock frame position",     COL1_X, y, COL_W, function(v) SynapseNS.cfg.locked = v; SynapseNS.LockFrame(v) end)
    togLocked = t7
    y = y - ROW_H - 8

    panel:SetHeight(math.abs(y) + 16)

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


