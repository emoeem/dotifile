--- Image EXIF preview using exiftool, with the actual image shown at the top.

local M = {}

local function is_binary_data(line)
	return line:find("(Binary data", 1, true) ~= nil
		or line:find("Tone Reproduction Curve", 1, true) ~= nil
end

function M:preload(job)
	local cache_url = ya.file_cache({ file = job.file, skip = 0 })
	local cache_cha = cache_url and fs.cha(cache_url)
	if cache_cha and cache_cha.len > 0 then
		return true
	end

	local mime = job.mime and job.mime:match(".*/(.*)$")
	if not mime then
		return false
	end

	local mod = mime == "svg+xml" and "svg" or "image"
	local ok, err = require(mod):preload({ skip = 0, file = job.file })
	if not ok and err then
		return false, err
	end
	return true
end

function M:peek(job)
	self:preload(job)

	local cache_url = ya.file_cache({ file = job.file, skip = 0 })

	local image_h = 0
	local rendered = cache_url
		and fs.cha(cache_url)
		and ya.image_show(cache_url, ui.Rect {
			x = job.area.x, y = job.area.y,
			w = job.area.w, h = math.floor(job.area.h * 0.5),
		})
	if rendered then
		image_h = rendered.h
	end

	local child = Command("exiftool")
		:arg({ tostring(job.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.NULL)
		:spawn()
	if not child then
		return
	end

	local text_h = math.max(1, job.area.h - image_h)
	local i, lines = 0, {}
	repeat
		local line, ev = child:read_line()
		if ev == 1 then
			return
		elseif ev ~= 0 then
			break
		end
		if is_binary_data(line) then
			goto next
		end
		i = i + 1
		if i > job.skip then
			table.insert(lines, ui.Line(ui.Span(line)))
		end
		::next::
	until i >= job.skip + text_h

	child:wait()

	if #lines == 0 and job.skip > 0 then
		ya.manager_emit("peek", {
			tostring(math.max(0, job.skip - text_h)),
			only_if = tostring(job.file.url),
			upper_bound = true,
		})
		return
	end

	ya.preview_widget(job, {
		ui.Text(lines):area(ui.Rect {
			x = job.area.x, y = job.area.y + image_h,
			w = job.area.w, h = text_h,
		}):wrap(ui.Wrap.YES),
	})
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.manager_emit("peek", {
			tostring(math.max(0, cx.active.preview.skip + job.units)),
			only_if = tostring(job.file.url),
		})
	end
end

return M
