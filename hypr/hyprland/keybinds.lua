local home = os.getenv("HOME") or "/home/gigabyte"
local qsConfig = "ii"

-- Super key shell binds
hl.bind("Super + Super_L", hl.dsp.global("quickshell:searchToggleRelease"), { desc = "Toggle search" })
hl.bind("Super + Super_R", hl.dsp.global("quickshell:searchToggleRelease"), { desc = "Toggle search" })
hl.bind("Super + Super_L", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pkill fuzzel || fuzzel"))
hl.bind("Super + Super_R", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pkill fuzzel || fuzzel"))
hl.bind("Super + catchall", hl.dsp.global("quickshell:searchToggleReleaseInterrupt"), { transparent = true, ignore_mods = true, non_consuming = true })
hl.bind("Ctrl + Super_L", hl.dsp.global("quickshell:searchToggleReleaseInterrupt"))
hl.bind("Ctrl + Super_R", hl.dsp.global("quickshell:searchToggleReleaseInterrupt"))

local mouse_interrupts = { "mouse:275", "mouse:276", "mouse:277", "mouse_up", "mouse_down" }
for _, m in ipairs(mouse_interrupts) do
    hl.bind("Super + " .. m, hl.dsp.global("quickshell:searchToggleReleaseInterrupt"))
end

hl.bind("Super_L", hl.dsp.global("quickshell:workspaceNumber"), { transparent = true, ignore_mods = true })
hl.bind("Super_R", hl.dsp.global("quickshell:workspaceNumber"), { transparent = true, ignore_mods = true })
hl.bind("Super + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"))
hl.bind("Super + V", hl.dsp.global("quickshell:overviewClipboardToggle"), { desc = "Clipboard history >> clipboard" })
hl.bind("Super + period", hl.dsp.global("quickshell:overviewEmojiToggle"), { desc = "Emoji >> clipboard" })
hl.bind("Super + A", hl.dsp.global("quickshell:sidebarLeftToggle"))
hl.bind("Super+Alt + A", hl.dsp.global("quickshell:sidebarLeftToggleDetach"))
hl.bind("Super + B", hl.dsp.global("quickshell:sidebarLeftToggle"))
hl.bind("Super + O", hl.dsp.global("quickshell:sidebarLeftToggle"))
hl.bind("Super + N", hl.dsp.global("quickshell:sidebarRightToggle"), { desc = "Toggle right sidebar" })
hl.bind("Super + slash", hl.dsp.global("quickshell:cheatsheetToggle"), { desc = "Toggle cheatsheet" })
hl.bind("Super + K", hl.dsp.global("quickshell:oskToggle"), { desc = "Toggle on-screen keyboard" })
hl.bind("Super + M", hl.dsp.global("quickshell:mediaControlsToggle"), { desc = "Toggle media controls" })
hl.bind("Super + G", hl.dsp.global("quickshell:overlayToggle"))
hl.bind("Ctrl+Alt + Delete", hl.dsp.global("quickshell:sessionToggle"), { desc = "Toggle session menu" })
hl.bind("Super + J", hl.dsp.global("quickshell:barToggle"), { desc = "Toggle bar" })
hl.bind("Ctrl+Alt + Delete", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pkill wlogout || wlogout -p layer-shell"))
hl.bind("Shift+Super+Alt + slash", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/" .. qsConfig .. "/welcome.qml"))

-- Audio & Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call brightness increment || brightnessctl s 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call brightness decrement || brightnessctl s 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("Super+Shift + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true, desc = "Toggle mute" })
hl.bind("Alt + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("Super+Alt + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true, desc = "Toggle mic" })

-- Wallpaper & Widgets
hl.bind("Ctrl+Super + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), { desc = "Toggle wallpaper selector" })
hl.bind("Ctrl+Super+Alt + T", hl.dsp.global("quickshell:wallpaperSelectorRandom"), { desc = "Select random wallpaper" })
hl.bind("Ctrl+Super + T", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || ~/.config/quickshell/" .. qsConfig .. "/scripts/colors/switchwall.sh"), { desc = "Change wallpaper" })
hl.bind("Ctrl+Super + R", hl.dsp.exec_cmd("killall ags agsv1 gjs ydotool qs quickshell; qs -c " .. qsConfig .. " &"))
hl.bind("Ctrl+Super + P", hl.dsp.global("quickshell:panelFamilyCycle"))

-- Utilities
hl.bind("Super + V", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"), { desc = "Copy clipboard history entry" })
hl.bind("Super + period", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pkill fuzzel || ~/.config/hypr/hyprland/scripts/fuzzel-emoji.sh copy"), { desc = "Copy an emoji" })
hl.bind("Super+Shift + S", hl.dsp.global("quickshell:regionScreenshot"))
hl.bind("Super+Shift + S", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"))
hl.bind("Super+Shift + A", hl.dsp.global("quickshell:regionSearch"))
hl.bind("Super+Shift + A", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pidof slurp || ~/.config/hypr/hyprland/scripts/snip_to_search.sh"))
hl.bind("Super+Shift + X", hl.dsp.global("quickshell:regionOcr"))
hl.bind("Super+Shift + T", hl.dsp.global("quickshell:regionOcr"))
hl.bind("Super+Shift + X", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy && rm \"/tmp/ocr_image.png\""))
hl.bind("Super+Shift + T", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy && rm \"/tmp/ocr_image.png\""))
hl.bind("Super+Shift + C", hl.dsp.exec_cmd("hyprpicker -a"), { desc = "Color picker" })
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"), { locked = true })
hl.bind("Ctrl + Print", hl.dsp.exec_cmd("mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"), { locked = true, non_consuming = true })
hl.bind("Ctrl + Print", hl.dsp.exec_cmd("grim - | wl-copy"), { locked = true, non_consuming = true })

-- Recording
hl.bind("Super+Shift + R", hl.dsp.global("quickshell:regionRecord"), { locked = true })
hl.bind("Super+Shift + R", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || ~/.config/quickshell/" .. qsConfig .. "/scripts/videos/record.sh"), { locked = true })
hl.bind("Super+Alt + R", hl.dsp.global("quickshell:regionRecord"), { locked = true })
hl.bind("Super+Alt + R", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || ~/.config/quickshell/" .. qsConfig .. "/scripts/videos/record.sh"), { locked = true })
hl.bind("Ctrl+Alt + R", hl.dsp.exec_cmd("~/.config/quickshell/" .. qsConfig .. "/scripts/videos/record.sh --fullscreen"), { locked = true })
hl.bind("Super+Shift+Alt + R", hl.dsp.exec_cmd("~/.config/quickshell/" .. qsConfig .. "/scripts/videos/record.sh --fullscreen --sound"), { locked = true })
hl.bind("Super+Shift+Alt + mouse:273", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/ai/primary-buffer-query.sh"), { desc = "Generate AI summary for selected text" })

-- Window mouse binds
hl.bind("Super + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("Super + mouse:274", hl.dsp.window.drag(), { mouse = true })
hl.bind("Super + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Window focus & movement
hl.bind("Super + Left", hl.dsp.focus({ direction = "left" }))
hl.bind("Super + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("Super + Up", hl.dsp.focus({ direction = "up" }))
hl.bind("Super + Down", hl.dsp.focus({ direction = "down" }))
hl.bind("Super + left", hl.dsp.focus({ direction = "left" }))
hl.bind("Super + right", hl.dsp.focus({ direction = "right" }))
hl.bind("Super + up", hl.dsp.focus({ direction = "up" }))
hl.bind("Super + down", hl.dsp.focus({ direction = "down" }))
hl.bind("Super + BracketLeft", hl.dsp.focus({ direction = "left" }))
hl.bind("Super + BracketRight", hl.dsp.focus({ direction = "right" }))

hl.bind("Super+Shift + Left", hl.dsp.window.move({ direction = "left" }))
hl.bind("Super+Shift + Right", hl.dsp.window.move({ direction = "right" }))
hl.bind("Super+Shift + Up", hl.dsp.window.move({ direction = "up" }))
hl.bind("Super+Shift + Down", hl.dsp.window.move({ direction = "down" }))
hl.bind("Super+Shift + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("Super+Shift + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("Super+Shift + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("Super+Shift + down", hl.dsp.window.move({ direction = "down" }))

hl.bind("Alt + F4", hl.dsp.window.close())
hl.bind("Super + Q", hl.dsp.window.close())
hl.bind("Super+Shift+Alt + Q", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind("Alt + Tab", hl.dsp.window.cycle_next())

-- Layout & state
hl.bind("Super + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true })
hl.bind("Super + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true })
hl.bind("Super+Alt + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("Super + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("Super + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("Super+Alt + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 3 }))
hl.bind("Super + P", hl.dsp.window.pin())

-- Workspace switching & moving (Super + 1..0)
for i = 1, 10 do
    local key = i % 10
    hl.bind("Super + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind("Super+Alt + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
    hl.bind("Super+Shift + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end

-- Keycode mappings for alternate layouts & keypad numbers
local code_to_ws = {
    [10] = 1, [11] = 2, [12] = 3, [13] = 4, [14] = 5,
    [15] = 6, [16] = 7, [17] = 8, [18] = 9, [19] = 10,
    [87] = 1, [88] = 2, [89] = 3, [83] = 4, [84] = 5,
    [85] = 6, [79] = 7, [80] = 8, [81] = 9, [90] = 10,
}
for code, ws in pairs(code_to_ws) do
    hl.bind("Super + code:" .. code, hl.dsp.focus({ workspace = ws }))
    hl.bind("Super+Alt + code:" .. code, hl.dsp.window.move({ workspace = ws, follow = false }))
    hl.bind("Super+Shift + code:" .. code, hl.dsp.window.move({ workspace = ws, follow = true }))
end

-- Workspace movement with scroll & page keys
hl.bind("Super+Shift + mouse_down", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("Super+Shift + mouse_up", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("Super+Alt + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("Super+Alt + mouse_up", hl.dsp.window.move({ workspace = "+1" }))

hl.bind("Super+Alt + Page_Down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("Super+Alt + Page_Up", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("Super+Shift + Page_Down", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("Super+Shift + Page_Up", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("Ctrl+Super+Shift + Right", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("Ctrl+Super+Shift + Left", hl.dsp.window.move({ workspace = "r-1" }))

hl.bind("Super+Alt + S", hl.dsp.window.move({ workspace = "special", follow = false }))
hl.bind("Ctrl+Super + S", hl.dsp.workspace.toggle_special())

-- Relative workspace switching
hl.bind("Ctrl+Super + Right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("Ctrl+Super + Left", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("Ctrl+Super+Alt + Right", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("Ctrl+Super+Alt + Left", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("Super + Page_Down", hl.dsp.focus({ workspace = "+1" }))
hl.bind("Super + Page_Up", hl.dsp.focus({ workspace = "-1" }))
hl.bind("Ctrl+Super + Page_Down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("Ctrl+Super + Page_Up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("Super + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind("Super + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("Ctrl+Super + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("Ctrl+Super + mouse_down", hl.dsp.focus({ workspace = "r-1" }))

-- Special workspace
hl.bind("Super + S", hl.dsp.workspace.toggle_special())
hl.bind("Super + mouse:275", hl.dsp.workspace.toggle_special())
hl.bind("Ctrl+Super + BracketLeft", hl.dsp.focus({ workspace = "-1" }))
hl.bind("Ctrl+Super + BracketRight", hl.dsp.focus({ workspace = "+1" }))
hl.bind("Ctrl+Super + Up", hl.dsp.focus({ workspace = "r-5" }))
hl.bind("Ctrl+Super + Down", hl.dsp.focus({ workspace = "r+5" }))

-- Virtual machine submap
hl.bind("Super+Alt + F1", function()
    hl.exec_cmd("notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. Hit Super+Alt+F1 to escape' -a 'Hyprland'")
    hl.dispatch(hl.dsp.submap("virtual-machine"))
end)

hl.define_submap("virtual-machine", function()
    hl.bind("Super+Alt + F1", function()
        hl.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'")
        hl.dispatch(hl.dsp.submap("reset"))
    end)
end)

-- Session
hl.bind("Super + L", hl.dsp.exec_cmd("loginctl lock-session"), { desc = "Lock" })
hl.bind("Super+Shift + L", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), { locked = true, desc = "Suspend system" })
hl.bind("Ctrl+Shift+Alt+Super + Delete", hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"), { desc = "Shutdown" })

-- Screen zoom
hl.bind("Super + Minus", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/zoom.sh decrease 0.3"), { repeating = true })
hl.bind("Super + Equal", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/zoom.sh increase 0.3"), { repeating = true })
hl.bind("Super + code:82", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call zoom zoomOut"), { repeating = true })
hl.bind("Super + code:86", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call zoom zoomIn"), { repeating = true })
hl.bind("Super + code:82", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.1"), { repeating = true })
hl.bind("Super + code:86", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh increase 0.1"), { repeating = true })

-- Media keys
hl.bind("Super+Shift + N", hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("Super+Shift+Alt + mouse:275", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("Super+Shift+Alt + mouse:276", hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`"))
hl.bind("Super+Shift + B", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("Super+Shift + P", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Applications
hl.bind("Super + Return", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\""))
hl.bind("Super + T", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\""))
hl.bind("Ctrl+Alt + T", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"${TERMINAL}\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\""))
hl.bind("Super + E", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"dolphin\" \"nautilus\" \"nemo\" \"thunar\" \"${TERMINAL}\" \"kitty -1 fish -c yazi\""))
hl.bind("Super + W", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"firefox-developer-edition\" \"zen-browser\" \"firefox\" \"brave\" \"chromium\" \"microsoft-edge-stable\" \"opera\" \"librewolf\""))
hl.bind("Super + C", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"code\" \"antigravity\" \"codium\" \"cursor\" \"zed\" \"zedit\" \"zeditor\" \"kate\" \"gnome-text-editor\" \"emacs\" \"command -v nvim && kitty -1 nvim\" \"command -v micro && kitty -1 micro\""))
hl.bind("Ctrl+Super+Shift+Alt + W", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"wps\" \"onlyoffice-desktopeditors\" \"libreoffice\""))
hl.bind("Super + X", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"kate\" \"gnome-text-editor\" \"emacs\""))
hl.bind("Ctrl+Super + V", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"pavucontrol-qt\" \"pavucontrol\""))
hl.bind("Super + I", hl.dsp.exec_cmd("XDG_CURRENT_DESKTOP=gnome " .. home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"qs -p ~/.config/quickshell/" .. qsConfig .. "/settings.qml\" \"systemsettings\" \"gnome-control-center\" \"better-control\""))
hl.bind("Ctrl+Shift + Escape", hl.dsp.exec_cmd(home .. "/.config/hypr/hyprland/scripts/launch_first_available.sh \"gnome-system-monitor\" \"plasma-systemmonitor --page-name Processes\" \"command -v btop && kitty -1 fish -c btop\""))

-- Custom fallback / window resizing
hl.bind("Ctrl+Super + backslash", hl.dsp.window.resize({ x = 640, y = 480, exact = true }))
hl.bind("Super + space", hl.dsp.exec_cmd("fuzzel"))
