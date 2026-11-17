-- Hyprland main Lua configuration
-- Matches the visual style and functionality of the original hyprland.conf

-- Environment
require("hyprland.env")
require("custom.env")

-- Monitors and workspaces
require("monitors")
require("workspaces")

-- General layout, decoration, animations, and input
require("hyprland.general")
require("custom.general")

-- Colors and rules
require("hyprland.colors")
require("hyprland.rules")
require("custom.rules")

-- Keybindings
require("hyprland.keybinds")
require("custom.keybinds")

-- Autostart
require("hyprland.execs")
require("custom.execs")

-- XWayland scaling
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
