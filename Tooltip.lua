-- =============================================================
-- Synapse/Tooltip.lua  |  WoW Midnight 12.0.5+  |  Interface: 120005
-- =============================================================
-- Tooltip enrichment for the Synapse hover frame.
--
-- API choice: TooltipDataProcessor.AddTooltipPostCall()
--   This is Blizzard's modern, sanctioned approach since Dragonflight
--   (10.0) and the correct forward path in Midnight.
--   Reference: github.com/Grimblaz-and-Friends/BlazDamage/issues/8
--
-- Rejected alternatives:
--   hooksecurefunc(GameTooltip, "SetSpellByID", ...)
--     → Legacy; GetSpell() is deprecated; may stop working in future patches.
--   OnTooltipSetSpell
--     → Same issue; both work today but TooltipDataProcessor is canonical.
--
-- SCOPE: Enrichment only fires when the Synapse frame is the tooltip
-- owner — we never add lines to every spell tooltip in the game.
--
-- SECRET-VALUE SAFETY:
--   We never read UnitHealth / secret combat values here.
--   C_Spell.GetSpellInfo and C_Spell.GetSpellPowerCost return plain
--   numeric data — safe to use freely.  Both calls are wrapped in
--   pcall as a belt-and-suspenders guard against nil returns from
--   unknown spells or spells that Blizzard has partially protected.
-- =============================================================

local ADDON_NAME, SynapseNS = ...

-- -------------------------------------------------------------
--  RESOURCE-TYPE LABELS
-- -------------------------------------------------------------
-- Mana / Rage / Energy / Focus / Runic Power + common secondaries.
-- Unknown types fall back to the empty string (no line added).
local RESOURCE_LABEL = {
    [0]  = "Mana",
    [1]  = "Rage",
    [2]  = "Focus",
    [3]  = "Energy",
    [4]  = "Combo Points",
    [5]  = "Runes",
    [6]  = "Runic Power",
    [7]  = "Soul Shards",
    [8]  = "Lunar Power",
    [9]  = "Holy Power",
    [11] = "Maelstrom",
    [12] = "Chi",
    [13] = "Insanity",
    [17] = "Fury",
    [18] = "Pain",
    [20] = "Essence",
}

-- -------------------------------------------------------------
--  FORMAT HELPERS
-- -------------------------------------------------------------
local function FormatCastTime(castTimeMs)
    if not castTimeMs or castTimeMs == 0 then
        return "Instant"
    end
    local s = castTimeMs / 1000
    if s == math.floor(s) then
        return s .. " sec"
    end
    return string.format("%.1f sec", s)
end

local function FormatCost(cost, powerType)
    if not cost or cost <= 0 then return nil end
    local label = RESOURCE_LABEL[powerType]
    if not label then return nil end  -- unknown resource type — skip line
    return cost .. " " .. label
end

-- -------------------------------------------------------------
--  INIT: register the post-call hook
-- -------------------------------------------------------------
function SynapseNS.InitTooltip()
    -- Guard: TooltipDataProcessor is Dragonflight+ / Midnight.
    -- Skip enrichment entirely if the API is absent (safety net for
    -- any future API deprecation).
    if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) then
        return
    end
    if not (Enum and Enum.TooltipDataType and Enum.TooltipDataType.Spell) then
        return
    end

    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Spell,
        function(tooltip, tooltipData)
            -- ── Scope guard ───────────────────────────────────────
            -- Only enrich when the Synapse frame triggered the tooltip.
            -- This prevents adding our lines to every spell tooltip in
            -- the UI (spellbook, talent panel, NPC gossip, etc.).
            local owner = tooltip:GetOwner()
            if owner ~= SynapseMainFrame then return end

            -- ── Config guards ─────────────────────────────────────
            if not SynapseNS.cfg then return end
            if not SynapseNS.cfg.showResourceCost then return end

            -- ── Spell ID ──────────────────────────────────────────
            local spellID = tooltipData and tooltipData.id
            if not spellID or spellID == 0 then return end

            -- ── Cast time ─────────────────────────────────────────
            local castTimeMs
            local ok1, spellInfo = pcall(C_Spell.GetSpellInfo, spellID)
            if ok1 and spellInfo then
                castTimeMs = spellInfo.castTime
            end

            -- ── Resource cost ─────────────────────────────────────
            -- C_Spell.GetSpellPowerCost returns a table of cost entries.
            -- We display the first (primary) cost only.
            local resourceCost, powerType
            local ok2, costTable = pcall(C_Spell.GetSpellPowerCost, spellID)
            if ok2 and costTable and costTable[1] then
                resourceCost = costTable[1].cost
                powerType    = costTable[1].type
            end

            -- ── Build lines ───────────────────────────────────────
            -- Only add the Synapse section if there is at least one
            -- data point to show (graceful degradation).
            local castStr = FormatCastTime(castTimeMs)
            local costStr = FormatCost(resourceCost, powerType)

            if castStr or costStr then
                -- Header separator
                tooltip:AddLine("|cFF00C8FF── Synapse ──|r", 1, 1, 1)
                if castStr then
                    tooltip:AddDoubleLine(
                        "  Cast time:", castStr,
                        0.85, 0.85, 0.85,   -- label: light grey
                        1.00, 0.82, 0.00)   -- value: gold
                end
                if costStr then
                    tooltip:AddDoubleLine(
                        "  Cost:", costStr,
                        0.85, 0.85, 0.85,
                        1.00, 0.82, 0.00)
                end
                -- Force the tooltip to recalculate its size after
                -- we've added lines (required when using PostCall).
                tooltip:Show()
            end
        end
    )
end
