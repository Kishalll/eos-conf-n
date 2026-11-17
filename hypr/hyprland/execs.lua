local home = os.getenv("HOME") or "/home/gigabyte"
local qsConfig = "ii"

hl.on("hyprland.start", function()
    -- Bar, wallpaper
    hl.exec_cmd(home .. "/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -c " .. qsConfig .. " &")
    hl.exec_cmd(home .. "/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c " .. qsConfig .. " ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c " .. qsConfig .. " ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")

    -- KDE Connect
    hl.exec_cmd("kdeconnectd")
end)
