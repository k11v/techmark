---@class reader.internal.list
local M = {}

---@param ol pandoc.OrderedList
---@return pandoc.OrderedList
function M.ReadOrderedList(ol)
	-- The start number is Commonmark-compliant but the style and delimiter are not.
	ol.listAttributes = pandoc.ListAttributes(ol.listAttributes.start, "DefaultStyle", "DefaultDelim")
	return ol
end

return M
