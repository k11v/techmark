---@class writer.gost.internal.contents
local M = {}

local element = require("internal.element")

---@param d pandoc.Div
---@return pandoc.Block|nil
function M.WriteContentsFromDiv(d)
	if d.attr.identifier ~= "template-contents" then
		return nil
	end

	-- TODO: Validate content is empty.

	-- \@starttoc{toc} writes the table of contents directly.
	-- \@starttoc is provided by package tocloft.
	-- See https://tex.stackexchange.com/q/51479.
	return pandoc.Plain({
		element.Tex([[\makeatletter]]),
		element.Tex([[\@starttoc{toc}]]),
		element.Tex([[\makeatother]]),
	})
end

return M
