
-- chapter-list: 按 Ctrl+c 查看章节列表
mp.add_key_binding("Ctrl+c", "chapter-list", function()
    local ch = mp.get_property_native("chapter-list", {})
    if #ch == 0 then mp.osd_message("无章节信息", 2); return end
    local msg = {}
    for i, c in ipairs(ch) do
        local t = c.time or 0
        local min = math.floor(t / 60)
        local sec = math.floor(t % 60)
        table.insert(msg, string.format("%3d. %02d:%02d %s", i, min, sec, c.title or ""))
    end
    mp.osd_message(table.concat(msg, "\n"), 5)
end)
