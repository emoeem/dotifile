
-- playlist-view: 按 P 显示播放列表
mp.add_key_binding("P", "playlist-view", function()
    local count = mp.get_property_number("playlist-count", 0)
    local pos = mp.get_property_number("playlist-pos", 0) + 1
    mp.osd_message(string.format("播放列表: %d/%d 首", pos, count), 3)
end)
