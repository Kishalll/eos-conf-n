hl.config({
    general = {
        col = {
            active_border = "rgba(91919077)",
            inactive_border = "rgba(46474655)",
        },
    },
    misc = {
        background_color = "rgba(121413FF)",
    },
})

local loaded_plugins = {}
for _, p in ipairs(hl.get_loaded_plugins() or {}) do
    if p.name then loaded_plugins[p.name] = true end
end

if loaded_plugins["hyprbars"] then
    hl.config({
        plugin = {
            hyprbars = {
                bar_text_font = "Google Sans Flex Medium, Rubik, Geist, AR One Sans, Reddit Sans, Inter, Roboto, Ubuntu, Noto Sans, sans-serif",
                bar_height = 30,
                bar_padding = 10,
                bar_button_padding = 5,
                bar_precedence_over_border = true,
                bar_part_of_window = true,
                bar_color = "rgba(121413FF)",
                col = {
                    text = "rgba(e3e2e1FF)",
                },
            },
        },
    })
end

hl.window_rule({
    match = { pin = true },
    border_color = "rgba(b8cac6AA) rgba(b8cac677)",
})
