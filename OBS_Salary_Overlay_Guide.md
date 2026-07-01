# OBS Salary Overlay - Complete Guide

A Lua script for OBS Studio that displays a dynamic salary counter in the bottom-right corner of your video feed.

## Features
- Displays ongoing call cost in real-time
- Updates every second
- Fully customizable appearance and settings
- No compilation required
- Works with any OBS scene

## Requirements
- OBS Studio (latest version recommended)
- Basic text editor (VS Code, Notepad++, etc.)

## Installation

### 1. Save the Script
Save the following code as `salary-overlay.lua`:

```lua
-- OBS Salary Overlay Script
-- Displays a running cost counter in OBS

obs = obslua

-- Configuration - modify these values
local SALARY_PER_SECOND = 1.00  -- $1.00 per second
local CURRENCY_SYMBOL = "$"
local DECIMAL_PLACES = 2
local UPDATE_INTERVAL_MS = 1000  -- Update every 1 second
local POSITION_MARGIN = 20  -- pixels from bottom-right corner
local FONT_SIZE = 24
local FONT_FACE = "Arial"
local TEXT_COLOR = {r=1.0, g=1.0, b=1.0, a=1.0}  -- White
local BACKGROUND_COLOR = {r=0.0, g=0.0, b=0.0, a=0.5}  -- Semi-transparent black
local BACKGROUND_PADDING = 10

-- Internal variables
local text_source = nil
local update_timer = nil
local accumulated_time = 0.0

function script_description()
    return "Displays the ongoing cost of the call\n\nSalary: $" .. SALARY_PER_SECOND .. " per second"
end

function script_properties()
    local props = obs.obs_properties_create()
    
    obs.obs_properties_add_float_slider(props, "salary_rate", "Salary per second ($)", 0.01, 100.0, 0.01)
    obs.obs_properties_add_int(props, "font_size", "Font Size", 10, 72, 1)
    obs.obs_properties_add_color(props, "text_color", "Text Color")
    obs.obs_properties_add_color(props, "bg_color", "Background Color")
    
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_double(settings, "salary_rate", SALARY_PER_SECOND)
    obs.obs_data_set_default_int(settings, "font_size", FONT_SIZE)
    obs.obs_data_set_default_int(settings, "text_color", obs.obs_rgba_to_int(1.0, 1.0, 1.0, 1.0))
    obs.obs_data_set_default_int(settings, "bg_color", obs.obs_rgba_to_int(0.0, 0.0, 0.0, 0.5))
end

function script_update(settings)
    SALARY_PER_SECOND = obs.obs_data_get_double(settings, "salary_rate")
    FONT_SIZE = obs.obs_data_get_int(settings, "font_size")
    
    local color_int = obs.obs_data_get_int(settings, "text_color")
    TEXT_COLOR = obs.obs_data_get_int_rgba(color_int)
    
    local bg_int = obs.obs_data_get_int(settings, "bg_color")
    BACKGROUND_COLOR = obs.obs_data_get_int_rgba(bg_int)
end

function script_load(settings)
    -- Create text source
    local source_name = "Salary Overlay"
    
    -- Check if source already exists
    local existing_source = obs.obs_get_source_by_name(source_name)
    if existing_source then
        text_source = existing_source
    else
        -- Create new text source
        local text_settings = obs.obs_data_create()
        obs.obs_data_set_string(text_settings, "text", "$0.00")
        obs.obs_data_set_string(text_settings, "font", FONT_FACE)
        obs.obs_data_set_int(text_settings, "font_size", FONT_SIZE)
        obs.obs_data_set_int(text_settings, "color", obs.obs_rgba_to_int(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a))
        obs.obs_data_set_bool(text_settings, "outline", true)
        obs.obs_data_set_int(text_settings, "outline_size", 2)
        obs.obs_data_set_int(text_settings, "outline_color", obs.obs_rgba_to_int(0, 0, 0, 1))
        
        text_source = obs.obs_source_create("text_gdiplus", source_name, text_settings, nil)
        obs.obs_data_release(text_settings)
        
        -- Add to current scene
        local scene = obs.obs_frontend_get_current_scene()
        if scene then
            local scene_item = obs.obs_scene_add(scene, text_source)
            obs.obs_sceneitem_set_alignment(scene_item, 10) -- Bottom-right alignment
            obs.obs_sceneitem_set_bounds_type(scene_item, 1) -- OBS_BOUNDS_SCALE_TO_WIDTH
            obs.obs_sceneitem_set_bounds(scene_item, {x=300, y=50}) -- Approximate size
            obs.obs_scene_release(scene)
        end
    end
    
    -- Set up update timer
    update_timer = obs.obs_hotkey_register_frontend("update_timer", "Update Salary", function(pressed)
        if pressed then
            update_salary_display()
        end
    end)
    
    obs.timer_add(function()
        update_salary_display()
        return true
    end, UPDATE_INTERVAL_MS)
end

function script_unload()
    if update_timer then
        obs.obs_hotkey_unregister(update_timer)
    end
    
    if text_source then
        obs.obs_source_release(text_source)
    end
end

function update_salary_display()
    accumulated_time = accumulated_time + 1
    local total_cost = SALARY_PER_SECOND * accumulated_time
    local formatted_cost = string.format("$" .. "%.2f", total_cost)
    
    -- Update text source
    if text_source then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", formatted_cost)
        obs.obs_data_set_int(settings, "font_size", FONT_SIZE)
        obs.obs_data_set_int(settings, "color", obs.obs_rgba_to_int(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a))
        obs.obs_source_update(text_source, settings)
        obs.obs_data_release(settings)
    end
end

-- Helper function to convert RGBA int to table
function obs.obs_data_get_int_rgba(color_int)
    local a = bit.band(bit.rshift(color_int, 24), 0xFF) / 255.0
    local b = bit.band(bit.rshift(color_int, 16), 0xFF) / 255.0
    local g = bit.band(bit.rshift(color_int, 8), 0xFF) / 255.0
    local r = bit.band(color_int, 0xFF) / 255.0
    return {r = r, g = g, b = b, a = a}
end
```

### 2. Place in Scripts Folder

**Windows:**
```
%APPDATA%\obs-studio\scripts\
```

**macOS:**
```
~/Library/Application Support/obs-studio/scripts/
```

**Linux:**
```
~/.config/obs-studio/scripts/
```

### 3. Load in OBS
1. Open OBS Studio
2. Go to **Tools → Scripts**
3. Click the **+** button and select your `salary-overlay.lua` file
4. The salary overlay will appear in the bottom-right corner of your video feed

## Customization

### Change the Salary Rate
Edit the `SALARY_PER_SECOND` value in the script:
```lua
local SALARY_PER_SECOND = 1.50  -- $1.50 per second
```

Or adjust it in OBS:
- Go to **Tools → Scripts**
- Select "salary-overlay"
- Use the slider to change the rate

### Change Appearance
Modify these variables at the top of the script:
```lua
local FONT_SIZE = 32
local TEXT_COLOR = {r=1.0, g=0.8, b=0.0, a=1.0}  -- Gold
local BACKGROUND_COLOR = {r=0.2, g=0.2, b=0.2, a=0.7}  -- Dark background
local POSITION_MARGIN = 30
```

## Troubleshooting

### Script Not Loading
- ✅ Verify the file is in the correct `scripts/` folder
- ✅ Check for Lua syntax errors
- ✅ Ensure OBS is up to date
- ✅ Check OBS logs for error messages

### Overlay Not Visible
- ✅ Make sure you have a scene selected
- ✅ Check that the text source is added to your scene
- ✅ Verify the source isn't hidden

### Performance Issues
- ✅ Reduce `UPDATE_INTERVAL_MS` if needed
- ✅ Simplify the text source settings
- ✅ Check OBS performance metrics

## Technical Details

### How It Works
1. The script creates a **text_gdiplus** source in OBS
2. A timer updates the text every second
3. The accumulated time is multiplied by the salary rate
4. The result is formatted and displayed
5. The source is positioned in the bottom-right corner

### Source Type
- Uses OBS's built-in `text_gdiplus` source type
- No custom graphics or shaders required
- Renders efficiently as part of OBS's normal pipeline

## License
This script is provided as-is for use with OBS Studio. You may modify and distribute it freely.

---

**Created for:** OBS Studio
**Version:** 1.0
**Last Updated:** July 2026