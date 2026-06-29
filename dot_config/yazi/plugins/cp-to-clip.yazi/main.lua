local M = {}

function M:entry(job)
	local h = cx.active.current.hovered
	if not h then return end

	local path = tostring(h.url)
	Command("sh"):arg({ "-c", 'wl-copy -t text/plain < "' .. path .. '" 2>/dev/null || cat "' .. path .. '" | wl-copy 2>/dev/null' }):stdout(Command.NULL):spawn()

	ya.notify {
		title = "剪贴板",
		content = "已复制: " .. tostring(h.name),
		timeout = 2,
		level = "info",
	}
end

return M
