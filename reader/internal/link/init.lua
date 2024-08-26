---@class reader.internal.link
local M = {}

local log = require("internal.log")
local element = require("internal.element")

---ReadInlinesWithGroupsFromInlines types and groups consecutive Links of the same type into link group Spans.
---It sets the type attribute for link group Spans.
---It creates link group Spans for single Links as well.
---@param inlines pandoc.List<pandoc.Inline>
---@param references table<string, any>
---@return pandoc.List<pandoc.Inline>
function M.ReadInlinesWithGroupsFromInlines(inlines, references)
	local inlinesWithGroups = pandoc.Inlines({})

	local groupType = ""
	local groupInlines = pandoc.Inlines({})

	local flushGroup = function()
		if #groupInlines ~= 0 then
			local group = pandoc.Span(groupInlines)
			element.SetKind(group, element.KindLinkGroup)
			group.attr.attributes["type"] = groupType
			inlinesWithGroups:insert(group)

			groupType = ""
			groupInlines = pandoc.Inlines({})
		end
	end

	for i = 1, #inlines do
		if inlines[i].tag == "Link" then
			local l = inlines[i] --[[@as pandoc.Link]]
			assert(l.tag == "Link")

			local type = M.typeFromLink(l, references)
			M.validateLinkWithType(l, type)

			if #groupInlines == 0 then
				groupType = type
				groupInlines:insert(inlines[i])
			elseif groupType == type then
				groupInlines:insert(inlines[i])
			else
				flushGroup()
				groupType = type
				groupInlines:insert(inlines[i])
			end
		else
			flushGroup()
			inlinesWithGroups:insert(inlines[i])
		end
	end

	flushGroup()

	return inlinesWithGroups
end

---typeFromLink determines the type of a Link.
---It validates and returns the type attribute if present.
---Otherwise it uses the Link's target to determine its type.
---@param l pandoc.Link
---@param references table<string, any>
---@return "internal-document"|"internal-reference"|"external"
function M.typeFromLink(l, references)
	if l.attr.attributes["type"] ~= nil then
		local gotType = l.attr.attributes["type"]
		local wantType

		wantType = "external"
		if gotType == wantType then
			return wantType
		end

		wantType = "internal-document"
		if gotType == wantType then
			return wantType
		end

		wantType = "internal-reference"
		if gotType == wantType then
			return wantType
		end

		log.Error(
			'expected "internal-document"|"internal-reference"|"external" link type, got "' .. gotType .. '"',
			"unexpected-link-type",
			element.GetSource(l)
		)
		log.Note('using "internal-document" link type instead', "", element.GetSource(l))
		return "internal-document"
	end

	if M.isAbsoluteURL(l.target) then
		return "external"
	end

	if references[l.target:match("^#(.*)$") or ""] ~= nil then
		return "internal-reference"
	end

	return "internal-document"
end

---@param l pandoc.Link
---@param type "internal-document"|"internal-reference"|"external"
---@return nil
function M.validateLinkWithType(l, type)
	if type == "external" then
		-- External links are not validated.
		return
	end

	if type == "internal-document" or type == "internal-reference" then
		local gotTitle = pandoc.utils.stringify(l)
		local wantTitle = l.target
		if gotTitle ~= wantTitle then
			log.Warning(
				'expected "' .. wantTitle .. '" internal link title, got "' .. gotTitle .. '"',
				"unexpected-internal-link-title",
				element.GetSource(l)
			)
		end
		return
	end

	assert(false)
end

---isAbsoluteURL tells if the given URL is absolute.
---It's implementation is best-effort, it works for most cases.
---@param u string
---@return boolean
function M.isAbsoluteURL(u)
	return u:match("[A-Za-z0-9]+://") ~= nil
end

return M
