---@class internal.file
local M = {}

---@param path string
---@return boolean
function M.Exists(path)
	local f = io.open(path)
	if f then
		f:close()
	end
	return f ~= nil
end

---@param path string
---@return string|nil
function M.Read(path)
	return M.read(path, "r")
end

---@param path string
---@return string|nil
function M.ReadBytes(path)
	return M.read(path, "rb")
end

---@param path string
---@param mode "r"|"rb"
---@return string|nil
function M.read(path, mode)
	local f = io.open(path, mode)
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

return M
