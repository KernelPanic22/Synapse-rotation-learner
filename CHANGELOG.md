# Synapse Changelog

## 2.0.2-alpha (2026-04-30)

### Added
- **Rotation recording** — record your cast sequence via a button in the config window; spells are stored per character
- **Playback mode** — continuously suggests the next castable spell in your recorded rotation; skips spells on cooldown and advances automatically via an OnUpdate loop
- **Charge awareness** — spells with charges (e.g. Marrowrend) are treated as castable while charges remain, even during the GCD
- **Saved profiles** — save, load, and delete named rotation profiles per character from a dropdown UI in the PROFILES section
- **Spell search** — search your character's spellbook and add spells directly to the active rotation from the config window
- **Reorder / remove spells** — up/down WoW arrow buttons and a remove button on each rotation row
- **WoW-native icons** — arrow buttons use `Interface\Buttons\Arrow-*` textures; record button uses the stopwatch icon; dropdown uses a WoW arrow chevron

### Fixed
- Scrollbar drag detection: both the main config scrollbar and the rotation list scrollbar now use a proper boolean drag flag; previously any left-click after dragging the scrollbar would jump the scroll position
- Cooldown display: guard against nil `start`/`duration` values from `GetSpellCooldown` to prevent errors on spells with no cooldown data

---

## 1.0.2 (2026-04-29)

### Fixed
- Cooldown spinner: avoid comparing secret number values returned by `GetActionCooldown` in mirror mode; secret values are taint-protected and cannot be used with `>` / `<` in addon code. Values are now passed directly to `cooldownFrame:SetCooldown()`, which accepts secret numbers natively.

---

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
