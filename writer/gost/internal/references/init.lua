---@class writer.gost.internal.references
local M = {}

local element = require("internal.element")

---@param d pandoc.Div
---@return pandoc.Block|nil
function M.WriteReferencesFromDiv(d)
	if d.attr.identifier ~= "template-references" then
		return nil
	end

	-- TODO: Validate content is empty.

	-- \printbibliography[heading=none] writes the list of references directly.
	-- It doesn't include uncited references unless \nocite{*} is used before it.
	-- \printbibliography is provided by package biblatex.
	return pandoc.Plain({
		element.Tex([[\printbibliography[heading=none] ]]),
	})
end

return M
