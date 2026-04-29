-- =============================================================
-- Synapse/Core.lua  |  WoW Midnight 12.0.1+  |  Interface: 120001
-- =============================================================
-- Responsibilities:
--   • Addon namespace + saved-variable initialisation
--   • All event registration and routing
--   • SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE — glow-tracking
--     (the Assisted Combat system fires these to signal the next ability)
--   • Action-bar scan: FindSpellOnBars(spellID) → slot
--   • Keybind lookup: GetSlotKeybind(slot) → string
--   • Combat / encounter state tracking
--   • IsCommRestricted() + SafeSend() wrapper (queue on encounter,
--     flush on ENCOUNTER_END) — ready for future inter-player features
--   • /syn slash command router
--
-- MIDNIGHT SECRET-VALUE NOTES:
--   • UnitHealth / UnitHealthMax can return opaque "secret" objects
--     during boss encounters.  Synapse never compares secret values —
--     all combat-decision logic is delegated to Blizzard's Assisted
--     Combat spell.  We only read action-bar metadata (non-secret).
--   • GetActionInfo() and GetSpellTexture() are safe; no pcall needed.
--     We pcall defensively for any unit-targeted APIs just in case.
-- =============================================================

local ADDON_NAME, SynapseNS = ...
Synapse = SynapseNS  -- global alias so Display.lua / Tooltip.lua can reach it

-- -------------------------------------------------------------
--  SAVED VARIABLE DEFAULTS
-- -------------------------------------------------------------
local DEFAULTS = {
    -- 0 = not yet configured (setup required: place Assisted Combat on a bar slot)
    -- >0 = Mirror mode: the bar slot that holds the Assisted Combat button
    mirrorSlot      = 0,

    -- Display
    scale           = 1.0,
    opacityCombat   = 1.0,
    opacityNoCombat = 0.8,
    showRangeTint   = true,
    showCooldownText = true,          -- OmniCC reads all Cooldown frames automatically
    showResourceCost = true,          -- Tooltip.lua enrichment toggle
    fadeOnTarget    = false,
    locked          = false,
    clickThrough    = false,

    -- Saved frame anchor
    frameAnchor = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
}

-- -------------------------------------------------------------
--  RUNTIME STATE  (all non-persisted)
-- -------------------------------------------------------------
SynapseNS.cfg           = nil    -- set on ADDON_LOADED
SynapseNS.inCombat      = false
SynapseNS.inEncounter   = false
SynapseNS.aurasDirty    = false
SynapseNS.timeSinceAura = 0
SynapseNS.commQueue     = {}     -- queued SafeSend messages

-- -------------------------------------------------------------
--  COMM SAFETY
-- -------------------------------------------------------------
-- Blizzard restricted addon comms during active encounters in early
-- Midnight builds, then rolled back to "combat only".  We still guard
-- with IsCommRestricted() so queued messages never fire mid-boss.
-- Reference: github.com/TytaniumDev/Wheelson/issues/65
local function IsCommRestricted()
    if IsEncounterInProgress() then return true end
    if C_MythicPlus and C_MythicPlus.IsRunActive and C_MythicPlus.IsRunActive() then
        return true
    end
    if C_PvP and C_PvP.IsActiveBattlefield and C_PvP.IsActiveBattlefield() then
        return true
    end
    return false
end

function SynapseNS.SafeSend(prefix, message, distribution, target)
    if IsCommRestricted() then
        table.insert(SynapseNS.commQueue, { prefix, message, distribution, target })
        return
    end
    C_ChatInfo.SendAddonMessage(prefix, message, distribution, target)
end

local function FlushCommQueue()
    if #SynapseNS.commQueue == 0 then return end
    for _, m in ipairs(SynapseNS.commQueue) do
        pcall(C_ChatInfo.SendAddonMessage, m[1], m[2], m[3], m[4])
    end
    SynapseNS.commQueue = {}
end

-- -------------------------------------------------------------
--  SLASH COMMANDS  —  /synapse  |  /syn
-- -------------------------------------------------------------
local function PrintHelp()
    local c, y = "|cFF00C8FF", "|cFFFFD700"
    print(c .. "Synapse|r — commands:")
    print(y .. "/syn config|r   — open settings window")
    print(y .. "/syn reset|r    — reset frame to screen centre")
    print(y .. "/syn status|r   — show current config")
    print(y .. "/syn help|r     — show this message")
end

local function PrintStatus()
    local cfg = SynapseNS.cfg
    if not cfg then print("|cFF00C8FFSynapse|r not yet initialised"); return end
    local mode = cfg.mirrorSlot > 0
        and ("|cFFFFD700Mirroring|r slot " .. cfg.mirrorSlot)
        or  "|cFFFF4444Not configured|r (drag Assisted Combat to a bar slot, then /syn mirror <slot>)"
    print("|cFF00C8FFSynapse|r status:")
    print("  Mode: " .. mode)
    print("  Scale: " .. cfg.scale)
    print("  Range tint: " .. tostring(cfg.showRangeTint))
    print("  Cooldown text: " .. tostring(cfg.showCooldownText))
    print("  Resource cost: " .. tostring(cfg.showResourceCost))
    print("  Opacity combat/nocombat: " .. cfg.opacityCombat .. " / " .. cfg.opacityNoCombat)
    print("  Fade on target: " .. tostring(cfg.fadeOnTarget))
    print("  Click-through: " .. tostring(cfg.clickThrough))
    print("  Locked: " .. tostring(cfg.locked))
end

SLASH_SYNAPSE1 = "/synapse"
SLASH_SYNAPSE2 = "/syn"
SlashCmdList["SYNAPSE"] = function(msg)
    msg = msg:lower():trim()
    if msg == "" or msg == "help" then PrintHelp(); return end

    local cmd = msg:match("^(%S+)")
    cmd = cmd or ""

    if cmd == "config" then
        if SynapseNS.OpenConfig then SynapseNS.OpenConfig() end

    elseif cmd == "reset" then
        if SynapseNS.ResetPosition then SynapseNS.ResetPosition() end
        print("|cFF00C8FFSynapse|r position reset to screen centre")

    elseif cmd == "status" then
        PrintStatus()

    else
        PrintHelp()
    end
end

-- -------------------------------------------------------------
--  EVENT FRAME
-- -------------------------------------------------------------
local eventFrame = CreateFrame("Frame", "SynapseEventFrame")

-- Standard events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

-- UNIT_AURA: register only for "player" to avoid the max-MUF-query-limit
-- problem documented in Decursive (wowace.com/projects/decursive/files/7665828).
-- Broad UNIT_AURA registration in Midnight is "not very optimized and leans
-- on max MUF update query limits" — so we restrict to player only.
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")

-- Dirty-flag OnUpdate throttle: UNIT_AURA sets the flag; we only act
-- after AURA_THROTTLE seconds have passed, capping update frequency.
local AURA_THROTTLE = 0.1  -- 100 ms — matches Decursive's approach
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    if SynapseNS.aurasDirty then
        SynapseNS.timeSinceAura = SynapseNS.timeSinceAura + elapsed
        if SynapseNS.timeSinceAura >= AURA_THROTTLE then
            SynapseNS.timeSinceAura = 0
            SynapseNS.aurasDirty   = false
            if SynapseNS.OnAuraUpdate then SynapseNS.OnAuraUpdate() end
        end
    end
end)

eventFrame:SetScript("OnEvent", function(self, event, ...)

    -- ── Initialisation ─────────────────────────────────────────
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= ADDON_NAME then return end
        -- Merge SynapseDB with defaults (deep-copy tables so defaults
        -- are never mutated across sessions).
        SynapseDB = SynapseDB or {}
        for k, v in pairs(DEFAULTS) do
            if SynapseDB[k] == nil then
                if type(v) == "table" then
                    SynapseDB[k] = {}
                    for k2, v2 in pairs(v) do SynapseDB[k][k2] = v2 end
                else
                    SynapseDB[k] = v
                end
            end
        end
        SynapseNS.cfg = SynapseDB

    elseif event == "PLAYER_LOGIN" then
        if SynapseNS.InitDisplay then SynapseNS.InitDisplay() end
        if SynapseNS.InitTooltip  then SynapseNS.InitTooltip()  end
        if SynapseNS.InitConfig   then SynapseNS.InitConfig()   end
        if SynapseNS.cfg and SynapseNS.cfg.mirrorSlot == 0 then
            print("|cFF00C8FFSynapse|r |cFFFF4444\226\128\148 Setup needed:|r"
                .. " open your spellbook, drag |cFFFFD700Assisted Combat|r onto a free bar slot,"
                .. " then type |cFFFFD700/syn mirror <slot>|r or use |cFFFFD700/syn config|r.")
        else
            print("|cFF00C8FFSynapse|r ready \226\128\148 mirroring slot "
                .. tostring(SynapseNS.cfg.mirrorSlot)
                .. ".  Type |cFFFFD700/syn config|r to adjust settings.")
        end

    -- ── Combat State ───────────────────────────────────────────
    elseif event == "PLAYER_REGEN_DISABLED" then
        SynapseNS.inCombat = true
        if SynapseNS.OnCombatChange then SynapseNS.OnCombatChange(true) end

    elseif event == "PLAYER_REGEN_ENABLED" then
        SynapseNS.inCombat = false
        if SynapseNS.OnCombatChange then SynapseNS.OnCombatChange(false) end

    -- ── Encounter State ────────────────────────────────────────
    elseif event == "ENCOUNTER_START" then
        SynapseNS.inEncounter = true

    elseif event == "ENCOUNTER_END" then
        SynapseNS.inEncounter = false
        FlushCommQueue()  -- flush any queued SafeSend messages

    -- ── Aura Dirty Flag ────────────────────────────────────────
    elseif event == "UNIT_AURA" then
        SynapseNS.aurasDirty = true

    -- ── Target Changed ─────────────────────────────────────────
    elseif event == "PLAYER_TARGET_CHANGED" then
        if SynapseNS.OnTargetChanged  then SynapseNS.OnTargetChanged()  end
        if SynapseNS.RefreshDisplay    then SynapseNS.RefreshDisplay()    end

    -- ── Bar / Keybind Changes ──────────────────────────────────
    -- Re-scan bars after slots change (spec switch, bar page turn, etc.)
    elseif event == "ACTIONBAR_SLOT_CHANGED"
        or event == "UPDATE_BINDINGS"
        or event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Update the tracked spell's slot + keybind (may have moved)
        -- Re-scan to keep the rotation keybind current after bar/binding changes
        if SynapseNS.nextSpellID and SynapseNS.cfg then
            SynapseNS.SetNextSpell(SynapseNS.nextSpellID)
        end
        if SynapseNS.RefreshDisplay then SynapseNS.RefreshDisplay() end
    end
end)
