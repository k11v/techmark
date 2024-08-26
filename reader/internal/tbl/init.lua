---@class reader.internal.tbl
local M = {}

local element = require("internal.element")

---@param t pandoc.Table
---@param markdownReader { read: fun(input: string): pandoc.Pandoc }
---@return pandoc.Figure
function M.ReadFigureFromTable(t, markdownReader)
	local caption = element.GetAndRemoveCaption(t, markdownReader)
	local attr = element.GetAndRemoveAttrWithIDAndSource(t)
	return pandoc.Figure({ t }, caption, attr)
end

return M
