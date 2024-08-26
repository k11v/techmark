---@class reader.internal.image
local M = {}

local element = require("internal.element")

---Depends on sourcepos extension. It embeds Paras into Divs to add source information.
---@param d pandoc.Div
---@param markdownReader { read: fun(input: string): pandoc.Pandoc }
---@return pandoc.Figure|nil
function M.ReadFigureFromDiv(d, markdownReader)
	local p = d.content[1] --[[@as pandoc.Para]]
	if #d.content ~= 1 or p.tag ~= "Para" then
		return nil
	end

	local i = p.content[1] --[[@as pandoc.Image]]
	if #p.content ~= 1 or i.tag ~= "Image" then
		return nil
	end

	local caption = element.GetAndRemoveCaption(d, markdownReader)
	local attr = element.GetAndRemoveAttr(d)

	return pandoc.Figure({ pandoc.Plain({ i }) }, caption, attr)
end

return M
