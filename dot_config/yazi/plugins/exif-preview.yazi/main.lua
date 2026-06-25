--- Image EXIF preview using exiftool, with image thumbnail + themed metadata.

local M = {}

local function is_binary_data(line)
	return line:find("(Binary data", 1, true) ~= nil
		or line:find("Tone Reproduction Curve", 1, true) ~= nil
end

function M:preload(job)
	local mime = job.mime and job.mime:match(".*/(.*)$")
	if not mime then
		return
	end

	local no_skip = { skip = 0, file = job.file, args = job.args, area = job.area }
	local cache = ya.file_cache(no_skip)
	local cha = cache and fs.cha(cache)
	if cha and cha.len and cha.len > 0 then
		return true
	end

	local mod
	if mime == "svg+xml" then
		mod = "svg"
	else
		local magick_mimes = {
			avif = true, hei = true, heic = true, heif = true,
			jxl = true, tiff = true, xml = true,
		}
		mod = magick_mimes[mime] and "magick" or "image"
	end
	return require(mod):preload(no_skip)
end

function M:peek(job)
	self:preload(job)

	local no_skip = { skip = 0, file = job.file, args = job.args, area = job.area }
	local cache = ya.file_cache(no_skip)
	local image_h = 0
	local rendered = cache
		and fs.cha(cache)
		and ya.image_show(cache, ui.Rect {
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
		local raw, ev = child:read_line()
		if ev == 1 then
			return
		elseif ev ~= 0 then
			break
		end
		if is_binary_data(raw) then
			goto next
		end
		i = i + 1
		if i > job.skip then
			local label, val = raw:match("^(.-)  +: (.*)")
			if label then
				table.insert(lines, ui.Line {
					ui.Span(label .. ":  "):style(ui.Style():bold()),
					ui.Span(val):style(th.spot.tbl_col or ui.Style():fg("blue")),
				})
			else
				table.insert(lines, ui.Line(ui.Span(raw)))
			end
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
