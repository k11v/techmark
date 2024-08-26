---@class reader.internal.code
local M = {}

local element = require("internal.element")

---@param cb pandoc.CodeBlock
---@param markdownReader { read: fun(input: string): pandoc.Pandoc }
---@return pandoc.Figure
function M.ReadFigureFromCodeBlock(cb, markdownReader)
	local caption = element.GetAndRemoveCaption(cb, markdownReader)
	local attr = element.GetAndRemoveAttrWithIDAndSource(cb)
	return pandoc.Figure({ cb }, caption, attr)
end

return M
