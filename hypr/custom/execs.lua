hl.on("hyprland.start", function()
    -- Ensure xdg-desktop-portal starts
    hl.exec_cmd("/usr/lib/xdg-desktop-portal")
end)
