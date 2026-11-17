local home = os.getenv("HOME") or "/home/gigabyte"
local qsConfig = "ii"

-- Quick config edit shortcuts
hl.bind("Ctrl+Super + slash", hl.dsp.exec_cmd("xdg-open " .. home .. "/.config/illogical-impulse/config.json"))
hl.bind("Ctrl+Super+Alt + slash", hl.dsp.exec_cmd("xdg-open " .. home .. "/.config/hypr/custom/keybinds.lua"))

-- Tab cycle override (preserves monocle maximized view when cycling)
hl.unbind("Alt + Tab")
hl.bind("Alt + Tab", function()
    local w = hl.get_active_window()
    if w and w.fullscreen == 1 then
        hl.dispatch(hl.dsp.window.cycle_next())
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))
    else
        hl.dispatch(hl.dsp.window.cycle_next())
    end
end)

-- Laptop lid switch
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), { locked = true })

-- Super key search menu toggles on release
hl.unbind("Super + Super_L")
hl.unbind("Super + Super_R")
hl.bind("Super + Super_L", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call search toggle"), { release = true })
hl.bind("Super + Super_R", hl.dsp.exec_cmd("qs -c " .. qsConfig .. " ipc call search toggle"), { release = true })
