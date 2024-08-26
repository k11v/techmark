---@class reader.internal.mth
local M = {}

local element = require("internal.element")

---Depends on sourcepos extension. It embeds Paras into Divs and Maths into Spans to add source information.
---@param d pandoc.Div
---@param markdownReader { read: fun(input: string): pandoc.Pandoc }
---@return pandoc.Figure|nil
function M.ReadFigureFromDiv(d, markdownReader)
	local p = d.content[1] --[[@as pandoc.Para]]
	if #d.content ~= 1 or p.tag ~= "Para" then
		return nil
	end

	local s = p.content[1] --[[@as pandoc.Span]]
	if #p.content ~= 1 or s.tag ~= "Span" then
		return nil
	end

	local m = s.content[1] --[[@as pandoc.Math]]
	if #p.content ~= 1 or m.tag ~= "Math" then
		return nil
	end

	local caption = element.GetAndRemoveCaption(d, markdownReader)
	local attr = element.GetAndRemoveAttr(d)

	return pandoc.Figure({ pandoc.Plain({ s }) }, caption, attr)
end

return M
