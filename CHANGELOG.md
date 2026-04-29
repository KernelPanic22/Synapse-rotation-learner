# Synapse Changelog

## 1.0.1 (2026-04-29)

### Fixed
- Pick mode: replaced per-slot overlay buttons with a cursor-position detection approach so clicking an action bar slot to mirror works reliably on all bar types
- Pick mode: teal highlight now tracks cursor movement via `OnUpdate` on a single reused frame instead of per-button `OnEnter`/`OnLeave` handlers
- Pick mode: cancelling (Escape or right-click) now correctly restores the previously configured mirror slot
- Removed redundant options for display, left only necessary

---

## 1.0.0

**Initial release for World of Warcraft Midnight (12.0.1+)**

### Features
- Draggable display frame mirroring the configured Assisted Combat action bar slot
- **Mirror button** — clicking Synapse casts the action identically to the real bar button (`SecureActionButtonTemplate`; GCD, range, and resource checks all native)
- **Cooldown spinner** — integrates automatically with OmniCC if installed
- **Range tint** — red overlay when the mirrored action is out of range (~150 ms throttle)
- **Opacity control** — separate in-combat and out-of-combat alpha values
- **Fade on target** — dims the frame when no target exists out of combat
- **Click-through** — optional mouse passthrough
- **Frame lock** — prevent accidental dragging
- Position saved between sessions per character

### Settings UI (`/syn config`)
- Custom standalone settings window — independent of Blizzard's UI panel, not reparented
- **Click-to-pick slot** — click the button, then click any visible action bar slot; picked slot highlights in teal
- ESC closes the window via `UISpecialFrames` (does not interfere with other ESC bindings)
- Appears in ESC → Settings → AddOns → Synapse with a single "Open Synapse Settings" button
- All settings apply immediately — scale, opacity sliders, range tint, cooldown text, fade, click-through, lock

### Commands
- `/syn config` — open settings window
- `/syn reset` — reset frame to screen centre
- `/syn status` — print current configuration to chat
- `/syn help` — list commands
