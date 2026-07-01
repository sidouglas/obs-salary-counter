-- OBS Salary Overlay Script
-- Displays a running cost counter in OBS

obs = obslua

local ANNUAL_SALARY = 150000
local HOURS_PER_YEAR = 2080  -- 40h/wk × 52wk; use 8760 for wall-clock (24/7)
local CURRENCY_SYMBOL = "$"
local DECIMAL_PLACES = 4
local UPDATE_INTERVAL_MS = 100
local POSITION_MARGIN = 20
local FONT_SIZE = 24
local FONT_FACE = "Arial"
local TEXT_COLOR = {r=1.0, g=1.0, b=1.0, a=1.0}
local BACKGROUND_COLOR = {r=0.0, g=0.0, b=0.0, a=0.5}
local BACKGROUND_PADDING = 10

local text_source = nil
local update_hotkey = nil
local accumulated_seconds = 0

local function int_to_rgba(color_int)
    local a = bit.band(bit.rshift(color_int, 24), 0xFF) / 255.0
    local b = bit.band(bit.rshift(color_int, 16), 0xFF) / 255.0
    local g = bit.band(bit.rshift(color_int, 8), 0xFF) / 255.0
    local r = bit.band(color_int, 0xFF) / 255.0
    return {r = r, g = g, b = b, a = a}
end

local function rgba_to_int(r, g, b, a)
    local ri = math.floor(r * 255 + 0.5)
    local gi = math.floor(g * 255 + 0.5)
    local bi = math.floor(b * 255 + 0.5)
    local ai = math.floor(a * 255 + 0.5)
    return bit.bor(bit.lshift(ai, 24), bit.lshift(bi, 16), bit.lshift(gi, 8), ri)
end

local function salary_per_second()
    return ANNUAL_SALARY / (HOURS_PER_YEAR * 3600)
end

function script_description()
    return "Displays the ongoing cost of the call, based on your annual salary."
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_int(props, "annual_salary", "Annual Salary ($)", 1, 10000000, 1000)
    local basis = obs.obs_properties_add_list(props, "hours_per_year", "Rate Basis",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_INT)
    obs.obs_property_list_add_int(basis, "Working hours (2080/yr)", 2080)
    obs.obs_property_list_add_int(basis, "Wall-clock (8760/yr, 24/7)", 8760)
    obs.obs_properties_add_int(props, "font_size", "Font Size", 10, 72, 1)
    obs.obs_properties_add_int(props, "decimal_places", "Decimal Places", 2, 6, 1)
    obs.obs_properties_add_color(props, "text_color", "Text Color")
    obs.obs_properties_add_color(props, "bg_color", "Background Color")
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_int(settings, "annual_salary", ANNUAL_SALARY)
    obs.obs_data_set_default_int(settings, "hours_per_year", HOURS_PER_YEAR)
    obs.obs_data_set_default_int(settings, "font_size", FONT_SIZE)
    obs.obs_data_set_default_int(settings, "decimal_places", DECIMAL_PLACES)
    obs.obs_data_set_default_int(settings, "text_color", rgba_to_int(1.0, 1.0, 1.0, 1.0))
    obs.obs_data_set_default_int(settings, "bg_color", rgba_to_int(0.0, 0.0, 0.0, 0.5))
end

function script_update(settings)
    ANNUAL_SALARY = obs.obs_data_get_int(settings, "annual_salary")
    HOURS_PER_YEAR = obs.obs_data_get_int(settings, "hours_per_year")
    FONT_SIZE = obs.obs_data_get_int(settings, "font_size")
    DECIMAL_PLACES = obs.obs_data_get_int(settings, "decimal_places")
    TEXT_COLOR = int_to_rgba(obs.obs_data_get_int(settings, "text_color"))
    BACKGROUND_COLOR = int_to_rgba(obs.obs_data_get_int(settings, "bg_color"))
end

local function get_text_source_type()
    -- text_gdiplus on Windows, text_ft2_source on macOS/Linux
    return package.config:sub(1, 1) == "\\" and "text_gdiplus" or "text_ft2_source"
end

local function apply_font(settings)
    local font = obs.obs_data_create()
    obs.obs_data_set_string(font, "face", FONT_FACE)
    obs.obs_data_set_string(font, "style", "Regular")
    obs.obs_data_set_int(font, "size", FONT_SIZE)
    obs.obs_data_set_int(font, "flags", 0)
    obs.obs_data_set_obj(settings, "font", font)
    obs.obs_data_release(font)
end

function update_salary_display()
    accumulated_seconds = accumulated_seconds + (UPDATE_INTERVAL_MS / 1000.0)
    local total_cost = salary_per_second() * accumulated_seconds
    local formatted_cost = string.format(CURRENCY_SYMBOL .. "%." .. DECIMAL_PLACES .. "f", total_cost)

    if text_source then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", formatted_cost)
        apply_font(settings)
        obs.obs_data_set_int(settings, "color1", rgba_to_int(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a))
        obs.obs_data_set_int(settings, "color2", rgba_to_int(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a))
        obs.obs_data_set_int(settings, "color", rgba_to_int(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a))
        obs.obs_source_update(text_source, settings)
        obs.obs_data_release(settings)
    end
end

function script_load(settings)
    local source_name = "Salary Overlay"

    local existing = obs.obs_get_source_by_name(source_name)
    if existing then
        text_source = existing
    else
        local text_settings = obs.obs_data_create()
        obs.obs_data_set_string(text_settings, "text", "$0.0000")
        apply_font(text_settings)
        local white = rgba_to_int(TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a)
        obs.obs_data_set_int(text_settings, "color1", white)
        obs.obs_data_set_int(text_settings, "color2", white)
        obs.obs_data_set_int(text_settings, "color", white)
        obs.obs_data_set_bool(text_settings, "outline", true)
        obs.obs_data_set_int(text_settings, "outline_size", 2)
        obs.obs_data_set_int(text_settings, "outline_color", rgba_to_int(0, 0, 0, 1))

        text_source = obs.obs_source_create(get_text_source_type(), source_name, text_settings, nil)
        obs.obs_data_release(text_settings)

        local scene_source = obs.obs_frontend_get_current_scene()
        if scene_source then
            local scene = obs.obs_scene_from_source(scene_source)
            if scene then
                local scene_item = obs.obs_scene_add(scene, text_source)
                obs.obs_sceneitem_set_alignment(scene_item, 0)  -- center

                local ovi = obs.obs_video_info()
                local cx, cy = 960, 540
                if obs.obs_get_video_info(ovi) then
                    cx = ovi.base_width / 2
                    cy = ovi.base_height / 2
                end
                local pos = obs.vec2()
                pos.x = cx
                pos.y = cy
                obs.obs_sceneitem_set_pos(scene_item, pos)
            end
            obs.obs_source_release(scene_source)
        end
    end

    update_hotkey = obs.obs_hotkey_register_frontend("salary_overlay_reset", "Reset Salary Counter", function(pressed)
        if pressed then
            accumulated_seconds = 0
            update_salary_display()
        end
    end)

    obs.timer_add(update_salary_display, UPDATE_INTERVAL_MS)
end

function script_unload()
    obs.timer_remove(update_salary_display)

    if update_hotkey then
        obs.obs_hotkey_unregister(update_hotkey)
    end

    if text_source then
        obs.obs_source_release(text_source)
        text_source = nil
    end
end
