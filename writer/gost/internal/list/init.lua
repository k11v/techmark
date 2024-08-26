---@class reader.internal.list
local M = {}

---WriteOrderedListFromDiv writes an ordered list.
---It writes the list with decimal parenthesis labels by default.
---Class with-parenthesis forces decimal parenthesis labels.
---Class with-period forces decimal period labels.
---@param d pandoc.Div
---@return pandoc.Div|nil
function M.WriteOrderedListFromDiv(d)
	local ol = d.content[1] --[[@as pandoc.OrderedList]]
	if #d.content ~= 1 or ol.tag ~= "OrderedList" then
		return nil
	end

	local style = "Decimal"
	local delimiter = "OneParen"
	local newClasses = pandoc.List({}) --[[@as pandoc.List<string>]]
	for _, c in ipairs(d.attr.classes) do
		if c == "with-parenthesis" then
			style = "Decimal"
			delimiter = "OneParen"
		elseif c == "with-period" then
			style = "Decimal"
			delimiter = "Period"
		else
			newClasses:insert(c)
		end
	end

	d = pandoc.walk_block(d, {
		---@param walkOl pandoc.OrderedList
		---@return pandoc.OrderedList
		OrderedList = function(walkOl)
			walkOl.listAttributes = pandoc.ListAttributes(walkOl.listAttributes.start, style, delimiter)
			return walkOl
		end,
	})
	d.attr.classes = newClasses

	return d
end

return M
