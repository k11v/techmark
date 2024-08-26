local log = {}

---@type "text"|"json"
log.format = "text"

---@param type "panic" | "error" | "warning" | "note"
---@param message string
---@param code? string|nil
---@param source? string|nil
local function make_text_log(type, message, code, source)
	local s = ""

	local resetColor = "\27[0m"
	local codeColor = "\27[35m"
	local typeColor
	if type == "note" then
		typeColor = "\27[34m\27[1m"
	elseif type == "warning" then
		typeColor = "\27[33m\27[1m"
	elseif type == "error" then
		typeColor = "\27[31m\27[1m"
	else
		assert(false)
	end

	if source ~= nil and source ~= "" then
		s = source .. ": "
	else
		s = "<unknown>: "
	end
	s = s .. typeColor .. type .. ": " .. resetColor .. message
	if code ~= nil and code ~= "" then
		s = s .. " " .. codeColor .. "[" .. code .. "]" .. resetColor
	end

	return s
end

---@param type "panic" | "error" | "warning" | "note"
---@param message string
---@param code? string|nil
---@param source? string|nil
local function make_json_log(type, message, code, source)
	local d = { type = type, message = message, source = source, code = code }
	return pandoc.json.encode(d)
end

local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		local i = 1
		for k, v in pairs(o) do
			if i ~= 1 then
				s = s .. ", "
			end
			s = s .. "[" .. dump(k) .. "] = " .. dump(v)
			i = i + 1
		end
		return s .. " }"
	elseif type(o) == "string" then
		return '"' .. o .. '"'
	else
		return tostring(o)
	end
end

---@param log_type "panic" | "error" | "warning" | "note"
---@param message any
---@param code? string|nil
---@param source? string
function log.message(log_type, message, code, source)
	local s = ""

	local m = type(message) == "string" and message or dump(message)
	if log.format == "text" then
		s = make_text_log(log_type, m, code, source)
	elseif log.format == "json" then
		s = make_json_log(log_type, m, code, source)
	else
		assert(false)
	end

	io.stderr:write(s .. "\n")
end

---@param message any
---@param code? string|nil
---@param source? string|nil
function log.Error(message, code, source)
	log.message("error", message, code, source)
end

---@param message any
---@param code? string|nil
---@param source? string|nil
function log.Warning(message, code, source)
	log.message("warning", message, code, source)
end

---@param message any
---@param code? string|nil
---@param source? string|nil
function log.Note(message, code, source)
	log.message("note", message, code, source)
end

return log
