-- Hyprland Lua configuration
-- Migrated from hyprland.conf
-- https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "DP-2",
    mode     = "5120x1440@120",
    position = "0x0",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------

local editor      = "vim"
local terminal    = "kitty"
local fileManager = "thunar"

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE",            "12")
hl.env("HYPRCURSOR_SIZE",         "12")
hl.env("LIBVA_DRIVER_NAME",       "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GTK_THEME",               "Adwaita:dark")

-------------------
---- AUTOSTART ----
-------------------

-- NB: noctalia is managed by a custom noctalia.service
-- Defined in ~/.config/systemd/user/noctalia.service
-- systemctl --user enable noctalia.service

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")   -- stores only text data
    hl.exec_cmd("wl-paste --type image --watch cliphist store")  -- stores only image data

    -- Theme (GTK)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")   -- GTK3 apps
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark") -- GTK4 apps
end)



---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,ua",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 3,

        col = {
            active_border = {
                colors = { "rgba(cba6f7ff)", "rgba(89b4faff)", "rgba(94e2d5ff)" },
                angle  = 10,
            },
            inactive_border = "0xff45475a",
            -- group_border        = "0xff89dceb",  -- uncomment if needed
            -- group_border_active = "0xfff9e2af",  -- uncomment if needed
        },

        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding = 20,
        rounding_power = 2,

        shadow = {
            enabled        = true,
            range          = 4,
            render_power   = 3,
            color          = 0xee1a1a1a, 
            color_inactive = 0x22000000,
        },

        blur = {
            enabled           = true,
            size              = 3,     -- was 'true' in old conf (likely a typo); 3 is a sane default
            passes            = 2,
            vibrancy          = 0.1696,
            new_optimizations = true,
            ignore_opacity    = false,
        },
    },

    dwindle = {
        preserve_split        = true,
        default_split_ratio   = 1.0
    },
})

--------------------
---- ANIMATIONS ----
--------------------

hl.curve("overshot", { type = "bezier", points = { { 0.13, 0.99 }, { 0.29, 1.1 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 4,  bezier = "overshot", style = "popin" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "overshot", style = "slidevert" })

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local ipc     = "noctalia msg "

-- Mouse: move/resize windows by dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Apps
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("uwsm app -- kitty --title all_is_kitty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("uwsm app -- " .. editor))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("uwsm app -- zen-browser"))

-- Screenshots
-- The PrtScr key does not reach us as Print: the Lofree is kept in Mac mode (it
-- impersonates an Apple keyboard so macOS gives it native Cmd/Option), and there
-- the key is a hardware Cmd+Shift+3 macro, which would otherwise collide with the
-- SUPER+SHIFT+3 workspace bind below. prtscr-remap.service turns it back into a
-- real Print key; see ~/.config/hypr/scripts/prtscr-remap.
local scriptDir = os.getenv("HOME") .. "/.config/hypr/scripts/"
hl.bind("Print",         hl.dsp.exec_cmd(scriptDir .. "screenshot_full"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(scriptDir .. "screenshot"))

-- Window management
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd("hyprctl dispatch exit"))
hl.bind("CTRL + ALT + V",          hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + J",         hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.layout("swapsplit"))
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + tab",       hl.dsp.group.next())

-- Noctalia / QuickShell
hl.bind(mainMod .. " + V",        hl.dsp.exec_cmd(ipc .. "panel-toggle clipboard"))
hl.bind(mainMod .. " + R",        hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + P",        hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind(mainMod .. " + CTRL + Q", hl.dsp.exec_cmd(ipc .. "session lock-and-suspend"))
hl.bind(mainMod .. " + L",        hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("qs -c noctalia-dev ipc call lockScreen focusPassword"))

-- Keyboard layout (cycle us/ua)
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

-- Move window with arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

-- Move focus with arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true, repeating = true })

-- Media player
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Switch workspaces / move window to workspace (1–10)
for i = 1, 10 do
    local key = i % 10  -- workspace 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e+1" }))

-- For Noctalia Color templates
require("noctalia").apply_theme()

-----------------
---  LAYOUTS  ---
-----------------


