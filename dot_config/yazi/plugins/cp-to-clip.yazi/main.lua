--- Copy hovered file content to system clipboard and show notification.
--- Depends on wl-clipboard (wl-copy) on Wayland, or xclip on X11.

local M = {}

function M:entry(job)
	local h = cx.active.current.hovered
	if not h then
		ya.notify { title = "剪贴板", content = "没有选中文件", timeout = 2, level = "warn" }
		return
	end

	local path = tostring(h.url)
	local ok, err = Command("sh"):arg {
		"-c", string.format("wl-copy < '%s' 2>/dev/null || xclip -selection clipboard < '%s' 2>/dev/null", path, path),
	}:output()

	if ok then
		ya.notify { title = "剪贴板", content = "已复制到系统剪贴板: " .. tostring(h.name), timeout = 3, level = "info" }
	else
		ya.notify { title = "剪贴板", content = "复制失败: " .. tostring(err), timeout = 3, level = "error" }
	end
end

return M
