-- screenshot-to-clipboard.lua
-- Copy screenshot to Wayland clipboard
local mp = require 'mp'

local function copy()
    local dir = os.getenv('XDG_RUNTIME_DIR') or '/tmp'
    local path = dir .. '/mpv-screenshot-' .. os.time() .. '.png'
    mp.commandv('screenshot-to-file', path, 'subtitles')
    mp.add_timeout(0.3, function()
        mp.command_native({ name = 'subprocess', args = { 'sh', '-c', 'wl-copy < ' .. path }, playback_only = false })
        mp.osd_message('截图已复制到剪贴板')
    end)
end

mp.register_script_message('screenshot-to-clipboard', copy)
