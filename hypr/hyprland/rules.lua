-- Window rules

-- Blur overrides
hl.window_rule({ match = { class = "^$", title = "^$" }, no_blur = true })
hl.window_rule({ match = { class = ".*" }, no_blur = true })

-- Office / documents
hl.window_rule({ match = { class = "^(soffice)$" }, float = true, size = "(monitor_w*.55) (monitor_h*.65)", center = true })
hl.window_rule({ match = { class = "^(org.kde.gwenview)$" }, maximize = true })
hl.window_rule({ match = { class = "^(org.kde.okular)$" }, maximize = true })

-- Dialogs
local dialog_titles = {
    "^(Open File)(.*)$",
    "^(Select a File)(.*)$",
    "^(Choose wallpaper)(.*)$",
    "^(Open Folder)(.*)$",
    "^(Save As)(.*)$",
    "^(Library)(.*)$",
    "^(File Upload)(.*)$",
    "^(.*)(wants to save)$",
    "^(.*)(wants to open)$",
}
for _, t in ipairs(dialog_titles) do
    hl.window_rule({ match = { title = t }, float = true, center = true })
end
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, size = "(monitor_w*.60) (monitor_h*.65)" })

-- Tools & Utilities
hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = "^(guifetch)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true, size = "(monitor_w*.45) (monitor_h*.45)", center = true })
hl.window_rule({ match = { class = "^(pavucontrol-qt)$" }, float = true, size = "(monitor_w*.55) (monitor_h*.65)", center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, size = "(monitor_w*.45) (monitor_h*.45)", center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true, size = "(monitor_w*.45) (monitor_h*.45)", center = true })

hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { title = ".*Welcome" }, float = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, float = true })
hl.window_rule({ match = { title = ".*Shell conflicts.*" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true, center = true, size = "(monitor_w*.60) (monitor_h*.65)" })
hl.window_rule({ match = { class = "^(Zotero)$" }, float = true, size = "(monitor_w*.45) (monitor_h*.45)" })
hl.window_rule({ match = { class = "org.kde.plasma-systemmonitor" }, float = true, center = true, size = "(monitor_w*.60) (monitor_h*.80)" })

-- Helper suppression
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, float = true, no_initial_focus = true, move = "999999 999999" })
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = "40 80" })

-- Tiling & Picture in picture
hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })
hl.window_rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    keep_aspect_ratio = true,
    move = "(monitor_w*.73) (monitor_h*.72)",
    size = "(monitor_w*.25) (monitor_h*.25)",
    pin = true,
})

-- Tearing rules
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- Jetbrains IDE fix
hl.window_rule({ match = { class = "^jetbrains-.*$", float = true, title = "^$|^\\s$|^win\\d+$" }, no_initial_focus = true })

-- No shadow for tiled windows
hl.window_rule({ match = { float = false }, no_shadow = true })

-- Workspace rules
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- Layer rules
hl.layer_rule({ match = { namespace = ".*" }, xray = true })
local no_anim_layers = { "walker", "selection", "overview", "anyrun", "indicator.*", "osk", "hyprpicker", "noanim", "gtk4-layer-shell" }
for _, l in ipairs(no_anim_layers) do
    hl.layer_rule({ match = { namespace = l }, no_anim = true })
end

hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.69 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

-- AGS layers
hl.layer_rule({ match = { namespace = "sideleft.*" }, animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })
local ags_blurred = { "session[0-9]*", "bar[0-9]*", "barcorner.*", "dock[0-9]*", "indicator.*", "overview[0-9]*", "cheatsheet[0-9]*", "sideright[0-9]*", "sideleft[0-9]*", "osk[0-9]*" }
for _, l in ipairs(ags_blurred) do
    hl.layer_rule({ match = { namespace = l }, blur = true, ignore_alpha = 0.6 })
end

-- Quickshell layers
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true, blur = true, ignore_alpha = 0.79 })
hl.layer_rule({ match = { namespace = "quickshell:bar" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:actionCenter" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:dock" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, animation = "popin 120%" })
hl.layer_rule({ match = { namespace = "quickshell:lockWindowPusher" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, no_anim = true, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:osk" }, animation = "slide bottom", order = -1 })
hl.layer_rule({ match = { namespace = "quickshell:polkit" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:popup" }, xray = false, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:regionSelector" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:screenshot" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true, no_anim = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, animation = "slide left" })
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, animation = "slide top" })
hl.layer_rule({ match = { namespace = "quickshell:wNotificationCenter" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wStartMenu" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, ignore_alpha = 0, no_anim = true })
