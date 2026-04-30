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
    showCooldownText = true,          -- OmniCC reads all Cooldown frames automatically
    locked          = false,
    clickThrough    = false,

    -- Saved frame anchor
    frameAnchor = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 },
}

-- Per-character defaults (rotation, playback mode)
local CHAR_DEFAULTS = {
    rotation  = {},    -- editable spell sequence: { spellID, spellID, ... }
    playback  = false, -- whether playback mode was active at logout
    profiles  = {},    -- saved profiles: { [name] = { spellID, ... }, ... }
}

-- Spells to ignore during recording (auto-attacks, banking, etc.)
local RECORD_IGNORE = {
    [6603]   = true,  -- Melee Auto Attack
    [75]     = true,  -- Auto Shot (Hunter)
    [83958]  = true,  -- Mobile Banking
    [125439] = true,  -- Revive Battle Pets
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

SynapseNS.charCfg        = nil   -- set on ADDON_LOADED (per-character)
SynapseNS.nextSpellID    = nil   -- currently suggested spell
SynapseNS.recordMode     = false -- true while recording a rotation
SynapseNS.recordedSpells = {}    -- accumulates spellIDs during recording
SynapseNS.playbackIndex  = 1     -- position in the effective rotation
SynapseNS.sentCastGUIDs  = {}    -- GUIDs of casts the player actively initiated

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
--  SPELL TRACKING
-- -------------------------------------------------------------
-- Called by glow events, playback advancement, and bar-refresh.
function SynapseNS.SetNextSpell(spellID)
    SynapseNS.nextSpellID = spellID
    if SynapseNS.RefreshDisplay then SynapseNS.RefreshDisplay() end
end

-- -------------------------------------------------------------
--  ROTATION RECORDING
-- -------------------------------------------------------------
function SynapseNS.StartRecording()
    SynapseNS.recordedSpells = {}
    SynapseNS.recordMode     = true
    if SynapseNS.OnRecordStateChange then SynapseNS.OnRecordStateChange() end
end

function SynapseNS.StopRecording()
    SynapseNS.recordMode = false
    local saved = {}
    for i, id in ipairs(SynapseNS.recordedSpells) do saved[i] = id end
    if SynapseNS.charCfg then SynapseNS.charCfg.rotation = saved end
    SynapseNS.recordedSpells = {}
    if SynapseNS.OnRecordStateChange then SynapseNS.OnRecordStateChange() end
end

-- -------------------------------------------------------------
--  PLAYBACK
-- -------------------------------------------------------------
-- Returns the rotation as-is (it is directly edited by the user).
function SynapseNS.GetEffectiveRotation()
    if not SynapseNS.charCfg then return {} end
    local rot = SynapseNS.charCfg.rotation or {}
    local seq = {}
    for i = 1, #rot do seq[i] = rot[i] end
    return seq
end

-- -------------------------------------------------------------
--  PROFILES  (save / load / delete named rotation lists)
-- -------------------------------------------------------------
-- Returns sorted list of profile names.
function SynapseNS.GetProfiles()
    local charCfg = SynapseNS.charCfg
    if not charCfg then return {} end
    charCfg.profiles = charCfg.profiles or {}
    local names = {}
    for name in pairs(charCfg.profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

-- Saves the current rotation under `name`, overwriting any existing entry.
function SynapseNS.SaveProfile(name)
    if not name or name == "" then return end
    local charCfg = SynapseNS.charCfg
    if not charCfg then return end
    charCfg.profiles = charCfg.profiles or {}
    local copy = {}
    for i, id in ipairs(charCfg.rotation or {}) do copy[i] = id end
    charCfg.profiles[name] = copy
end

-- Loads the named profile into the active rotation.
function SynapseNS.LoadProfile(name)
    if not name then return end
    local charCfg = SynapseNS.charCfg
    if not charCfg then return end
    charCfg.profiles = charCfg.profiles or {}
    local src = charCfg.profiles[name]
    if not src then return end
    local copy = {}
    for i, id in ipairs(src) do copy[i] = id end
    charCfg.rotation = copy
    -- Restart playback from index 1 with the new rotation
    if charCfg.playback then
        SynapseNS.EnablePlayback(true)
    end
    if SynapseNS.OnRecordStateChange then SynapseNS.OnRecordStateChange() end
end

-- Deletes the named profile.
function SynapseNS.DeleteProfile(name)
    if not name then return end
    local charCfg = SynapseNS.charCfg
    if not charCfg or not charCfg.profiles then return end
    charCfg.profiles[name] = nil
end

-- Tracks cooldown expiry timestamps for playback skip logic.
-- Populated when spells are cast; compared via plain GetTime() — never tainted.
-- Keys are base spellIDs, values are GetTime() timestamps when the CD expires.
local spellCDEnd = {}

-- Returns true when spellID is truly unavailable: on a real cooldown AND has
-- no remaining charges.  Taint-safe: never compares secret values from
-- GetSpellCooldown (which are restricted in Midnight combat).
local function SpellIsOnCooldown(spellID)
    if not spellID then return false end
    -- Charge-based spells: castable if ≥1 charge remains.
    -- Wrap comparisons of potentially-tainted charge counts in pcall.
    local isChargeBased = false
    local hasCharges    = true
    pcall(function()
        local cur, maxC = C_Spell.GetSpellCharges(spellID)
        local isCB = false
        pcall(function() isCB = maxC > 1 end)  -- maxC may be tainted
        if isCB then
            isChargeBased = true
            hasCharges    = tostring(cur) ~= "0"  -- tostring is always safe
        end
    end)
    if isChargeBased then
        return not hasCharges
    end
    -- Non-charge spell: compare our own tracked expiry (plain Lua numbers).
    local cdEnd = spellCDEnd[spellID]
    return cdEnd ~= nil and GetTime() < cdEnd
end

-- Walks forward from startIndex (wrapping) and returns the first index
-- whose spell is not on cooldown.  If every spell is on cooldown, returns
-- startIndex unchanged so the display keeps showing the nearest upcoming spell.
local function FindNextReadyIndex(seq, startIndex)
    local n = #seq
    if n == 0 then return startIndex end
    for i = 0, n - 1 do
        local idx = ((startIndex - 1 + i) % n) + 1
        if not SpellIsOnCooldown(seq[idx]) then
            return idx
        end
    end
    return startIndex
end

function SynapseNS.EnablePlayback(enable)
    if not SynapseNS.charCfg then return end
    SynapseNS.charCfg.playback = enable
    if enable then
        local seq = SynapseNS.GetEffectiveRotation()
        if #seq > 0 then
            -- Clamp index in case the rotation was edited while disabled
            if SynapseNS.playbackIndex < 1 or SynapseNS.playbackIndex > #seq then
                SynapseNS.playbackIndex = 1
            end
            local readyIdx = FindNextReadyIndex(seq, SynapseNS.playbackIndex)
            SynapseNS.playbackIndex = readyIdx
            SynapseNS.SetNextSpell(seq[readyIdx])
        else
            SynapseNS.SetNextSpell(nil)
        end
    else
        SynapseNS.SetNextSpell(nil)
    end
    if SynapseNS.OnRecordStateChange then SynapseNS.OnRecordStateChange() end
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
    print("  Cooldown text: " .. tostring(cfg.showCooldownText))
    print("  Opacity combat/nocombat: " .. cfg.opacityCombat .. " / " .. cfg.opacityNoCombat)
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
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

-- UNIT_AURA: register only for "player" to avoid the max-MUF-query-limit
-- problem documented in Decursive (wowace.com/projects/decursive/files/7665828).
-- Broad UNIT_AURA registration in Midnight is "not very optimized and leans
-- on max MUF update query limits" — so we restrict to player only.
eventFrame:RegisterUnitEvent("UNIT_AURA", "player")

-- Glow events: Assisted Combat fires these when suggesting the next ability
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
eventFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
-- Track casts to advance playback position
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
-- Track player-initiated casts (to exclude triggered/proc spells from recording)
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT",        "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED",      "player")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")

-- Dirty-flag OnUpdate throttle: UNIT_AURA sets the flag; we only act
-- after AURA_THROTTLE seconds have passed, capping update frequency.
local AURA_THROTTLE = 0.1   -- 100 ms — matches Decursive's approach
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

        -- Per-character saved variables: rotation, blacklist, playback mode.
        SynapseDBChar = SynapseDBChar or {}
        for k, v in pairs(CHAR_DEFAULTS) do
            if SynapseDBChar[k] == nil then
                if type(v) == "table" then
                    SynapseDBChar[k] = {}
                else
                    SynapseDBChar[k] = v
                end
            end
        end
        SynapseNS.charCfg = SynapseDBChar

    elseif event == "PLAYER_LOGIN" then
        if SynapseNS.InitDisplay then SynapseNS.InitDisplay() end
        if SynapseNS.InitTooltip  then SynapseNS.InitTooltip()  end
        if SynapseNS.InitConfig   then SynapseNS.InitConfig()   end
        -- Restore playback mode if it was active at last logout
        if SynapseNS.charCfg and SynapseNS.charCfg.playback then
            SynapseNS.EnablePlayback(true)
        end
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

    -- ── Glow-Tracking (Assisted Combat suggestions) ────────────
    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
        -- Recording is now cast-based (UNIT_SPELLCAST_SUCCEEDED).
        -- Glow events are kept only for the live display (non-playback mode).
        if not (SynapseNS.charCfg and SynapseNS.charCfg.playback) then
            local glowSpellID = ...
            local spellID = glowSpellID
            if C_AssistedCombat and C_AssistedCombat.IsAvailable
               and C_AssistedCombat.IsAvailable() then
                local ok, nextCast = pcall(C_AssistedCombat.GetNextCastSpell)
                if ok and nextCast and nextCast ~= 0 then spellID = nextCast end
            end
            SynapseNS.SetNextSpell(spellID)
        end

    elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
        if not (SynapseNS.charCfg and SynapseNS.charCfg.playback) then
            local acSpell = nil
            if C_AssistedCombat and C_AssistedCombat.IsAvailable
               and C_AssistedCombat.IsAvailable() then
                local ok, nextCast = pcall(C_AssistedCombat.GetNextCastSpell)
                if ok and nextCast and nextCast ~= 0 then acSpell = nextCast end
            end
            SynapseNS.SetNextSpell(acSpell)
        end

    -- ── Player-initiated cast tracking (for recording filter) ──
    -- UNIT_SPELLCAST_SENT fires only when the player presses a button.
    -- Triggered/proc spells never produce a SENT event, so we use the
    -- castGUID to tell the two apart in UNIT_SPELLCAST_SUCCEEDED.
    elseif event == "UNIT_SPELLCAST_SENT" then
        -- args: unit, target, castGUID, spellID
        local _, _, sentGUID = ...
        if sentGUID and sentGUID ~= "" then
            SynapseNS.sentCastGUIDs[sentGUID] = true
        end

    elseif event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_INTERRUPTED" then
        -- Clean up GUIDs for casts that never completed
        local _, failGUID = ...
        if failGUID then SynapseNS.sentCastGUIDs[failGUID] = nil end

    -- ── Cast-based recording + playback advancement ────────────
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- args: unit, castGUID, spellID
        local _, castGUID, castSpellID = ...
        -- Resolve proc overrides back to the base spell so the rotation
        -- stores canonical IDs (e.g. Ambush proc → Sinister Strike).
        local baseID = castSpellID
        pcall(function()
            local b = FindBaseSpellByID(castSpellID)
            if b and b ~= 0 then baseID = b end
        end)
        local recordID = baseID  -- use base ID for both recording and matching

        -- ── Recording (player-initiated casts only) ─────────────
        -- Only record if this cast was triggered by the player pressing a button.
        -- Triggered/proc spells have no SENT event and no entry in sentCastGUIDs.
        local isPlayerCast = castGUID and SynapseNS.sentCastGUIDs[castGUID]
        if isPlayerCast then
            SynapseNS.sentCastGUIDs[castGUID] = nil  -- consume the token
        end

        if SynapseNS.recordMode and isPlayerCast and not RECORD_IGNORE[recordID] then
            local rec = SynapseNS.recordedSpells
            if rec[#rec] ~= recordID then
                rec[#rec + 1] = recordID
            end
            if SynapseNS.OnRecordStateChange then SynapseNS.OnRecordStateChange() end
        end

        -- Track this spell's cooldown expiry so SpellIsOnCooldown can skip it
        -- without calling GetSpellCooldown (which returns secret values in combat).
        -- GetSpellBaseCooldown returns static milliseconds — never tainted.
        do
            local baseCD = GetSpellBaseCooldown(recordID)
            if baseCD and baseCD > 1500 then
                spellCDEnd[recordID] = GetTime() + (baseCD / 1000)
            end
        end

        -- ── Playback advancement ────────────────────────────────
        -- Advance on every player cast (event is unit-registered to "player"
        -- only, so no other unit's casts reach here).  Instant-cast spells
        -- have an empty GUID so we cannot rely on isPlayerCast here — we just
        -- advance on any successful cast, then skip over spells that are on
        -- cooldown with no charges.
        if SynapseNS.charCfg and SynapseNS.charCfg.playback and not RECORD_IGNORE[recordID] then
            local seq = SynapseNS.GetEffectiveRotation()
            if #seq > 0 then
                local nextIdx = (SynapseNS.playbackIndex % #seq) + 1
                nextIdx = FindNextReadyIndex(seq, nextIdx)
                SynapseNS.playbackIndex = nextIdx
                SynapseNS.SetNextSpell(seq[nextIdx])
            end
        end
    end
end)
