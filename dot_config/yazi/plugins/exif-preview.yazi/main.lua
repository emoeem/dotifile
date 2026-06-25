--- A Yazi plugin that displays image EXIF metadata using exiftool.
--- Modeled after the style of `exiftool` CLI output.

local M = {}

local function is_binary_data(line)
	return line:find("(Binary data", 1, true) ~= nil
		or line:find("Tone Reproduction Curve", 1, true) ~= nil
end

function M:peek(job)
	local child = Command("exiftool")
		:arg{ "--sort", tostring(job.file.url) }
		:stdout(Command.PIPED)
		:stderr(Command.NULL)
		:spawn()

	if not child then
		return self:fallback_to_builtin()
	end

	local limit = job.area.h
	local i, lines = 0, {}

	repeat
		local next_line, event = child:read_line()
		if event == 1 then
			return self:fallback_to_builtin()
		elseif event ~= 0 then
			break
		end

		if is_binary_data(next_line) then
			goto continue
		end

		i = i + 1
		if i > job.skip then
			table.insert(lines, ui.Line(ui.Span(next_line)))
		end

		::continue::
	until i >= job.skip + limit

	child:wait()

	if #lines == 0 then
		return self:fallback_to_builtin()
	end

	ya.preview_widget(job, { ui.Text(lines):area(job.area):wrap(ui.Wrap.YES) })
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
