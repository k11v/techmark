---@class writer.gost.internal.tbl
local M = {}

---@param f pandoc.Figure
---@return pandoc.Block|nil
function M.WriteTableFigure(f)
	if not M.isTableFigure(f) then
		return nil
	end

	local tables = {}
	for _, t in ipairs(f.content) do
		assert(t.tag == "Table")
		t = t --[[@as pandoc.Table]]

		local tableWithIDAndCaption = t:clone()
		tableWithIDAndCaption.attr.identifier = f.attr.identifier
		tableWithIDAndCaption.caption = f.caption

		table.insert(tables, tableWithIDAndCaption)
	end

	return tables
end

---@param f pandoc.Figure
---@return boolean
function M.isTableFigure(f)
	for i = 1, #f.content do
		if f.content[i].tag ~= "Table" then
			return false
		end
	end
	return true
end

return M
