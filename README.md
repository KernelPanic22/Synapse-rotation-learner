# Synapse — Assisted Combat Display
**World of Warcraft Midnight 12.0.1+ | Interface: 120001**

Synapse places a draggable button on your screen that mirrors whatever action
Blizzard's **Assisted Combat** system has queued — showing the spell icon,
cooldown spinner, and a red range tint when your target is out of range.
Clicking the Synapse button casts the action exactly like clicking the real
bar button would.

---

## Quick Setup

1. Open your Spellbook and drag **Assisted Combat** onto any free action bar slot.
2. Type `/syn config` (or go to **ESC → Settings → AddOns → Synapse**).
3. Under **Setup**, click **"Click to pick action bar slot…"** and then click
   the slot you just placed Assisted Combat on.
4. Drag the Synapse frame to wherever you want it on screen.

That's it. Synapse will now show the correct icon, run the cooldown spinner,
and tint red when you're out of range.

---

## Features

- **Mirror button** — clicking Synapse is identical to clicking your action bar
  slot (uses `SecureActionButtonTemplate`; GCD, range, and resource checks all
  work natively)
- **Cooldown spinner** — integrates automatically with OmniCC if installed
- **Range tint** — red overlay when the action is out of range (~150 ms throttle)
- **Opacity control** — separate in-combat and out-of-combat alpha
- **Fade on target** — dims the frame when you have no target out of combat
- **Click-through** — optional mouse passthrough
- **Frame lock** — prevent accidental dragging
- Position saved between sessions

---

## Commands  `/synapse` or `/syn`

| Command | Description |
|---|---|
| `/syn config` | Open the settings window |
| `/syn reset` | Move frame back to screen centre |
| `/syn status` | Print current configuration to chat |
| `/syn help` | List commands |

All other settings (slot, scale, opacity, toggles) are in `/syn config`.

---

## Troubleshooting

### "Synapse shows a question mark icon"
No mirror slot is configured. Open `/syn config` and pick your Assisted Combat
action bar slot.

### "The button doesn't cast anything when I click it"
Make sure the mirrored slot actually contains the **Assisted Combat** spell.
If you moved it to a different slot, open `/syn config` and re-pick.

### "Mirror button doesn't respond after a UI reload in combat"
`SecureActionButtonTemplate` attributes cannot be changed during combat. If
you reload mid-fight the button will resume working as soon as you leave combat.

---

## Midnight API Notes

Synapse never reads secret values (`UnitHealth`, GUIDs, stealth flags). All
combat decisions are delegated to Blizzard's Assisted Combat spell. The APIs
used (`GetActionTexture`, `GetActionCooldown`, `IsActionInRange`) return plain
non-secret data and are safe in all contexts.
accident via `/syn mirror`), the button will revert to the previous slot on
the next `/reload`. Always configure mirror slots out of combat.

---

## Files

```
Synapse/
├── Synapse.toc     ← Interface: 120001, SavedVariables: SynapseDB
├── Core.lua        ← Events, state, keybind scan, slash commands
├── Display.lua     ← Draggable frame, icon, cooldown, range tint
└── Tooltip.lua     ← TooltipDataProcessor enrichment (cast time, cost)
```

---

## License
 All Rights Reserved unless otherwise explicitly stated. 
