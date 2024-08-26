---@class writer.gost.internal.link
local M = {}

local element = require("internal.element")
local log = require("internal.log")

---@param g pandoc.Span
---@return pandoc.Inline|nil
function M.WriteLinkGroupFromSpan(g)
	if element.GetKind(g) ~= element.KindLinkGroup then
		return nil
	end

	local type = g.attr.attributes["type"] or ""
	if type == "" then
		log.Error(
			"expected the type attribute of link group to not be empty",
			"link-group-has-empty-type",
			element.GetSource(g)
		)
	end
	if type == "external" then
		return element.Merge(g.content)
	end

	local targets = {}
	for _, l in ipairs(g.content) do
		if l.tag ~= "Link" then
			log.Error("expected Link in link group, got " .. l.tag, "link-group-has-non-link", element.GetSource(l))
			goto continue
		end
		l = l --[[@as pandoc.Link]]

		table.insert(targets, l.target)

		::continue::
	end

	local targetsLatex = {}
	for _, t in ipairs(targets) do
		local tLatex = t:match("^#(.*)$") or ""
		if tLatex == "" then
			log.Error(
				"expected the target of internal Link to be like #example, got " .. t,
				"internal-link-has-invalid-target",
				element.GetSource(g)
			)
			goto continue2
		end

		table.insert(targetsLatex, tLatex)

		::continue2::
	end

	local targetsLatexJoined = table.concat(targetsLatex, ",")

	if type == "internal-document" then
		-- \labelcref is provided by package cleveref.
		-- It is used over \ref because \labelcref can accept multiple targets when \ref can't.
		-- It requires that all targets are of the same type (e.g. all image figures).
		return element.Merge({ element.Tex([[\labelcref{]]), element.Tex(targetsLatexJoined), element.Tex([[}]]) })
	elseif type == "internal-reference" then
		return element.Merge({ element.Tex([[\cite{]]), element.Tex(targetsLatexJoined), element.Tex([[}]]) })
	else
		assert(false)
	end
end

return M
