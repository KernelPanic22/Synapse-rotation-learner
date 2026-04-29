-- =============================================================
-- Synapse/Display.lua  |  WoW Midnight 12.0.1+  |  Interface: 120001
-- =============================================================
-- Responsibilities:
--   • Main 48×48 movable display frame
--   • Two operating modes:
--       Glow-Tracking mode  (mirrorSlot == 0):
--           Display-only.  Shows the icon and keybind of whichever
--           spell SPELL_ACTIVATION_OVERLAY_GLOW_SHOW is tracking.
--           Assisted Combat fires this event with the suggested ability.
--
--       Mirror mode  (mirrorSlot > 0):
--           A transparent SecureActionButtonTemplate overlays the
--           display frame, inheriting the action at the configured
--           slot — so clicking Synapse is identical to clicking that
--           bar button.  Inspired by Danders Rotation Tracker's
--           verified technique (curseforge.com/wow/addons/danders-rotation-tracker).
--
--   • Cooldown spinner (CooldownFrameTemplate — OmniCC auto-integrates)
--   • Combat / out-of-combat opacity fade
--   • Drag-to-move + frame lock
--   • Click-through option
--   • GameTooltip integration on hover
-- =============================================================

local ADDON_NAME, SynapseNS = ...

-- -------------------------------------------------------------
--  CONSTANTS
-- -------------------------------------------------------------
local BUTTON_SIZE          = 48
local COOLDOWN_REFRESH_SEC = 0.5    -- seconds between SetCooldown refreshes
local QUESTION_TEXTURE     = "Interface\\Icons\\INV_Misc_QuestionMark"

-- -------------------------------------------------------------
--  FRAME REFERENCES  (module-local)
-- -------------------------------------------------------------
local mainFrame       -- outer draggable Frame
local iconTexture     -- ARTWORK texture showing the spell icon
local cooldownFrame   -- Cooldown frame (spinner + OmniCC text)
local mirrorButton    -- SecureActionButtonTemplate (mirror mode only)

-- -------------------------------------------------------------
--  TIMERS
-- -------------------------------------------------------------
local cdTimer       = 0

-- -------------------------------------------------------------
--  UTILITY: spell icon (Midnight-safe)
-- -------------------------------------------------------------
local function GetSafeSpellIcon(spellID)
    if not spellID then return QUESTION_TEXTURE end
    -- C_Spell.GetSpellInfo is the preferred Midnight API.
    -- We pcall because in exotic edge-cases (vehicle, phased content)
    -- it can return nil or unexpected types.
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    if ok and info and info.iconID then
        return info.iconID
    end
    -- Legacy fallback (may still work in 12.x for most spells)
    local tex = GetSpellTexture and GetSpellTexture(spellID)
    return tex or QUESTION_TEXTURE
end

-- -------------------------------------------------------------
--  UTILITY: cooldown data for the active tracking target
-- -------------------------------------------------------------
local function GetCurrentCooldown()
    local start, duration, enable = 0, 0, 1
    local slot = SynapseNS.cfg and SynapseNS.cfg.mirrorSlot or 0
    if slot > 0 then
        -- Mirror mode: slot cooldown is authoritative.
        -- GetActionCooldown is not a secret-value API.
        local ok, s, d, e = pcall(GetActionCooldown, slot)
        if ok and s then start, duration, enable = s, d, e end
    elseif SynapseNS.nextSpellID then
        -- Glow-tracking mode: use spell cooldown.
        local ok, cd = pcall(C_Spell.GetSpellCooldown, SynapseNS.nextSpellID)
        if ok and cd and cd.startTime then
            start    = cd.startTime
            duration = cd.duration
            enable   = cd.isEnabled and 1 or 0
        end
    end
    return start, duration, enable
end

-- -------------------------------------------------------------
--  UTILITY: update icon texture for mirror mode
-- -------------------------------------------------------------
local function GetMirrorIcon(slot)
    -- GetActionTexture is safe in Midnight (returns a plain texture path/ID).
    local ok, tex = pcall(GetActionTexture, slot)
    return (ok and tex) or QUESTION_TEXTURE
end

-- =============================================================
--  PUBLIC: InitDisplay  — called on PLAYER_LOGIN
-- =============================================================
function SynapseNS.InitDisplay()
    local cfg = SynapseNS.cfg

    -- ── Main frame ──────────────────────────────────────────────
    mainFrame = CreateFrame("Frame", "SynapseMainFrame", UIParent)
    mainFrame:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    mainFrame:SetScale(cfg.scale)
    mainFrame:SetAlpha(cfg.opacityNoCombat)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(10)

    -- Restore saved position
    local a = cfg.frameAnchor
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint(a.point, UIParent, a.relPoint, a.x, a.y)

    -- ── Dark background ────────────────────────────────────────
    local bg = mainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.45)

    -- ── Spell icon ─────────────────────────────────────────────
    iconTexture = mainFrame:CreateTexture(nil, "ARTWORK")
    iconTexture:SetAllPoints()
    iconTexture:SetTexture(QUESTION_TEXTURE)
    -- Trim the default 1-pixel border WoW adds to all spell icons
    iconTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- ── Cooldown spinner ───────────────────────────────────────
    -- CooldownFrameTemplate is the same template used by action buttons.
    -- OmniCC detects any Cooldown child frame and adds text automatically.
    cooldownFrame = CreateFrame("Cooldown", "SynapseCooldown", mainFrame,
        "CooldownFrameTemplate")
    cooldownFrame:SetAllPoints()
    cooldownFrame:SetDrawEdge(true)
    cooldownFrame:SetHideCountdownNumbers(not cfg.showCooldownText)

    -- ── Drag support ───────────────────────────────────────────
    mainFrame:EnableMouse(not cfg.clickThrough)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if not SynapseNS.cfg.locked then self:StartMoving() end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        SynapseNS.cfg.frameAnchor = {
            point = point, relPoint = relPoint, x = x, y = y
        }
    end)

    -- ── Tooltip on hover ───────────────────────────────────────
    mainFrame:SetScript("OnEnter", function(self)
        local slot = SynapseNS.cfg.mirrorSlot
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if slot and slot > 0 then
            GameTooltip:SetAction(slot)
        elseif SynapseNS.nextSpellID then
            GameTooltip:SetSpellByID(SynapseNS.nextSpellID)
        else
            GameTooltip:SetText("|cFF00C8FFSynapse|r\nWaiting for Assisted Combat glow…",
                nil, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    mainFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- ── Per-frame update (range + cooldown refresh) ────────────
    mainFrame:SetScript("OnUpdate", function(self, elapsed)
        -- Cooldown refresh (throttled at 0.5 s — Cooldown widget
        -- counts down automatically once SetCooldown is called, but
        -- we re-sync periodically in case the spell comes off CD).
        cdTimer = cdTimer + elapsed
        if cdTimer >= COOLDOWN_REFRESH_SEC then
            cdTimer = 0
            local start, duration, enable = GetCurrentCooldown()
            if duration and duration > 0.5 then
                cooldownFrame:SetCooldown(start, duration)
            else
                cooldownFrame:Clear()
            end
        end
    end)

    -- ── Apply initial mirror slot & lock ───────────────────────
    SynapseNS.SetMirrorSlot(cfg.mirrorSlot)
    SynapseNS.LockFrame(cfg.locked)

    -- Initial visual refresh
    SynapseNS.RefreshDisplay()
end

-- =============================================================
--  PUBLIC: SetMirrorSlot
--  slot == 0  → Glow-Tracking (display only)
--  slot > 0   → Mirror mode (transparent SecureActionButton overlay)
-- =============================================================
function SynapseNS.SetMirrorSlot(slot)
    if not mainFrame then return end

    -- Tear down old mirror button
    if mirrorButton then
        mirrorButton:SetParent(nil)
        mirrorButton = nil
    end

    if slot and slot > 0 then
        -- The SecureActionButtonTemplate button overlays the visual frame.
        -- It is transparent (alpha = 0 is not used — instead we make
        -- mainFrame a child of mirrorButton so input flows naturally):
        --   mirrorButton  → handles all clicks / WoW action dispatch
        --   mainFrame     → child of mirrorButton, handles visuals & tooltip
        --
        -- This mirrors what Danders Rotation Tracker does: rely on the
        -- existing action button infrastructure for GCD, range, resource —
        -- all of which the SecureActionButtonTemplate already manages.
        mirrorButton = CreateFrame("Button", "SynapseMirrorButton", UIParent,
            "SecureActionButtonTemplate")
        mirrorButton:SetSize(BUTTON_SIZE, BUTTON_SIZE)
        mirrorButton:SetScale(SynapseNS.cfg.scale)
        mirrorButton:SetAlpha(SynapseNS.cfg.opacityNoCombat)
        mirrorButton:SetClampedToScreen(true)
        mirrorButton:SetMovable(true)
        mirrorButton:RegisterForClicks("AnyUp")

        -- Restore position from mainFrame anchor
        local a = SynapseNS.cfg.frameAnchor
        mirrorButton:SetPoint(a.point, UIParent, a.relPoint, a.x, a.y)

        -- Secure attributes — type "action" uses the slot directly.
        -- This is the same technique as action bar buttons; no taint risk.
        mirrorButton:SetAttribute("type",   "action")
        mirrorButton:SetAttribute("action", slot)

        -- Re-parent the visual frame onto the mirror button
        mainFrame:SetParent(mirrorButton)
        mainFrame:ClearAllPoints()
        mainFrame:SetAllPoints(mirrorButton)
        mainFrame:EnableMouse(false)   -- let mirrorButton handle all input

        -- Drag support for mirror button
        mirrorButton:RegisterForDrag("LeftButton")
        mirrorButton:SetScript("OnDragStart", function(self)
            if not SynapseNS.cfg.locked then self:StartMoving() end
        end)
        mirrorButton:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relPoint, x, y = self:GetPoint()
            SynapseNS.cfg.frameAnchor = {
                point = point, relPoint = relPoint, x = x, y = y
            }
        end)
    else
        -- Glow-Tracking mode: mainFrame stands alone
        mainFrame:SetParent(UIParent)
        mainFrame:ClearAllPoints()
        local a = SynapseNS.cfg.frameAnchor
        mainFrame:SetPoint(a.point, UIParent, a.relPoint, a.x, a.y)
        mainFrame:EnableMouse(not SynapseNS.cfg.clickThrough)
    end
end

-- =============================================================
--  PUBLIC: RefreshDisplay  — update icon and keybind text
-- =============================================================
function SynapseNS.RefreshDisplay()
    if not mainFrame then return end
    local cfg   = SynapseNS.cfg
    local slot  = cfg.mirrorSlot or 0

    -- ── Icon ──────────────────────────────────────────────────
    if slot > 0 then
        iconTexture:SetTexture(GetMirrorIcon(slot))
    elseif SynapseNS.nextSpellID then
        iconTexture:SetTexture(GetSafeSpellIcon(SynapseNS.nextSpellID))
    else
        iconTexture:SetTexture(QUESTION_TEXTURE)
    end

    -- ── Opacity ───────────────────────────────────────────────
    local alpha = SynapseNS.inCombat and cfg.opacityCombat or cfg.opacityNoCombat
    local activeFrame = mirrorButton or mainFrame
    activeFrame:SetAlpha(alpha)

end

-- =============================================================
--  PUBLIC: LockFrame
-- =============================================================
function SynapseNS.LockFrame(locked)
    local f = mirrorButton or mainFrame
    if not f then return end
    if locked then
        f:EnableMouse(false)
    else
        -- In mirror mode the SecureActionButton must stay mouse-enabled
        -- for clicks to register.
        if mirrorButton then
            mirrorButton:EnableMouse(true)
        else
            mainFrame:EnableMouse(not SynapseNS.cfg.clickThrough)
        end
    end
end

-- =============================================================
--  PUBLIC: ApplyScale
-- =============================================================
function SynapseNS.ApplyScale(scale)
    if mirrorButton then mirrorButton:SetScale(scale) end
    if mainFrame    then mainFrame:SetScale(scale) end
end

-- =============================================================
--  PUBLIC: ApplyClickThrough
--  Enables or disables mouse interactivity on the main frame.
--  Only relevant in Glow-Tracking mode; in Mirror mode the
--  SecureActionButton always needs mouse input for clicks.
-- =============================================================
function SynapseNS.ApplyClickThrough(enabled)
    if not mainFrame then return end
    if mirrorButton then return end  -- click-through not applicable in mirror mode
    mainFrame:EnableMouse(not enabled)
end

-- =============================================================
--  PUBLIC: ApplyCooldownText
--  Shows or hides the OmniCC / built-in countdown numbers on
--  the cooldown spinner without recreating the frame.
-- =============================================================
function SynapseNS.ApplyCooldownText(enabled)
    if cooldownFrame then
        cooldownFrame:SetHideCountdownNumbers(not enabled)
    end
end

-- =============================================================
--  PUBLIC: ResetPosition
-- =============================================================
function SynapseNS.ResetPosition()
    local f = mirrorButton or mainFrame
    if not f then return end
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    SynapseNS.cfg.frameAnchor = {
        point = "CENTER", relPoint = "CENTER", x = 0, y = 0
    }
end

-- =============================================================
--  EVENT CALLBACKS  (invoked from Core.lua event handler)
-- =============================================================

-- Called when entering / leaving combat
function SynapseNS.OnCombatChange(inCombat)
    if not mainFrame then return end
    local cfg        = SynapseNS.cfg
    local targetAlpha = inCombat and cfg.opacityCombat or cfg.opacityNoCombat
    local activeFrame = mirrorButton or mainFrame
    -- Simple direct alpha set — avoids UIFrameFadeIn/Out signature
    -- differences across WoW versions.
    activeFrame:SetAlpha(targetAlpha)
end

-- Called after aura dirty-flag throttle fires
function SynapseNS.OnAuraUpdate()
    -- A lightweight refresh on aura changes is enough;
    -- we don't parse aura lists here.
    if SynapseNS.RefreshDisplay then SynapseNS.RefreshDisplay() end
end
