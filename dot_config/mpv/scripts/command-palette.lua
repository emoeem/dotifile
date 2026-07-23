-- command-palette: 按 `Alt+p` 打开命令面板
mp.add_key_binding("Alt+p", "command-palette", function()
    mp.osd_message("命令面板: 需安装完整版", 2)
end)
