# OBS Salary Counter

A Lua script for OBS Studio that overlays a live-updating salary counter on your scene. Enter your annual salary; the overlay ticks up in real time so you can see exactly what a meeting is costing.

https://github.com/user-attachments/assets/2f67fa5a-af71-4e01-ab35-f3a21d148a03

> **Inspired by** this r/theydidthemath post — [_[Request] Is this financially accurate?_](https://www.reddit.com/r/theydidthemath/comments/1j16pjw/request_is_this_financially_accurate/)

## Install

**macOS / Linux** — load the script directly from this repo (recommended for hacking), or copy it in:

```
~/Library/Application Support/obs-studio/scripts/    # macOS
~/.config/obs-studio/scripts/                        # Linux
```

**Windows:**

```
%APPDATA%\obs-studio\scripts\
```

Then in OBS: **Tools → Scripts → +** → pick `salary-overlay.lua`.

## First use

The overlay is added to the current scene, centered on the canvas. Drag it wherever you want it. Open **Tools → Scripts → salary-overlay** to configure.

## Settings

| Field | Notes |
| --- | --- |
| Annual Salary ($) | Defaults to $150,000. |
| Rate Basis | Working hours (2080/yr, 40h × 52wk) or wall-clock (8760/yr, 24/7). Working hours = "cost of this meeting"; wall-clock = "lifetime earnings ticker". |
| Font Size | 10–72. |
| Decimal Places | 2–6. Default 4 so a $150K salary ($0.02/sec) visibly ticks between updates. |
| Text Color / Background Color | Standard color pickers. |

At $150K, working-hours basis: ~$72.12/hr, ~$0.02003/sec.

## Reset

Bind the **Reset Salary Counter** hotkey under **Settings → Hotkeys** to zero the counter mid-stream.

## Notes

- Uses `text_ft2_source` on macOS/Linux and `text_gdiplus` on Windows.
- Updates every 100 ms.
- The overlay source is named `Salary Overlay`. If it already exists in your scene, the script reuses it (and won't reposition it) — delete the source to get a fresh centered placement.
