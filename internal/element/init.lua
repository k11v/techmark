---@class internal.element
local M = {}

---@param s string
---@return pandoc.Inline
function M.Tex(s)
	return pandoc.RawInline("latex", s)
end

---@param s string
---@return pandoc.Block
function M.TexBlock(s)
	return pandoc.RawBlock("latex", s)
end

---@param inlines pandoc.Inlines
---@return pandoc.Inline
function M.Merge(inlines)
	local i = pandoc.Span(inlines)
	i.attr.attributes["template-merge"] = "1"
	return i
end

---@param blocks pandoc.Blocks
---@return pandoc.Block
function M.MergeBlock(blocks)
	local b = pandoc.Div(blocks)
	b.attr.attributes["template-merge"] = "1"
	return b
end

---@param b pandoc.Block
---@return pandoc.Inline
function M.Inline(b)
	return M.Merge(pandoc.utils.blocks_to_inlines({ b }))
end

---@param e { attr: pandoc.Attr }
---@return pandoc.Attr
function M.GetAndRemoveAttr(e)
	local a = e.attr
	e.attr = pandoc.Attr()
	return a
end

---@param e { attr: pandoc.Attr }
---@param markdownReader { read: fun(input: string): pandoc.Pandoc }
---@return pandoc.Caption
function M.GetAndRemoveCaption(e, markdownReader)
	local captionStr = e.attr.attributes["caption"] or ""
	e.attr.attributes["caption"] = nil

	local blocks = markdownReader.read(captionStr).blocks
	local inlines = pandoc.utils.blocks_to_inlines(blocks)
	if #inlines == 0 then
		return {}
	end

	return { long = { pandoc.Plain(inlines) } }
end

---@param e { attr: pandoc.Attr }
---@return pandoc.Attr
function M.GetAndRemoveAttrWithIDAndSource(e)
	local id = e.attr.identifier
	e.attr.identifier = ""

	-- Don't remove source because it's okay to have duplicates.
	local source = M.GetSource(e)

	local a = pandoc.Attr(id, {}, {})
	M.SetSource(e, source)
	return a
end

---RemoveMerges removes the merge attribute from elements.
---It only removes the attribute, it doesn't remove Divs and Spans created for them.
---It is recommended to call RemoveRedundants after RemoveMerges to have a clearer document.
---@param doc pandoc.Pandoc
---@return pandoc.Pandoc
function M.RemoveMerges(doc)
	return doc:walk({
		---@param d pandoc.Div
		---@return pandoc.Div | pandoc.Blocks
		Div = function(d)
			if M.isMerge(d) then
				M.removeMerge(d)
			end
			return d
		end,

		---@param s pandoc.Span
		---@return pandoc.Span | pandoc.Inlines
		Span = function(s)
			if M.isMerge(s) then
				M.removeMerge(s)
			end
			return s
		end,
	})
end

---@param e pandoc.Div | pandoc.Span
---@return boolean
function M.isMerge(e)
	return e.attr.attributes["template-merge"] == "1"
end

---@param e { attr: pandoc.Attr }
---@return nil
function M.removeMerge(e)
	e.attr.attributes["template-merge"] = nil
end

M.KindLinkGroup = "link-group"

---@param e { attr: pandoc.Attr }
---@return string
function M.GetKind(e)
	return e.attr.attributes["template-element-kind"] or ""
end

---@param e { attr: pandoc.Attr }
---@param kind string
---@return nil
function M.SetKind(e, kind)
	e.attr.attributes["template-element-kind"] = kind
end

---@param e { attr: pandoc.Attr }
---@return string
function M.GetSource(e)
	return e.attr.attributes["data-pos"] or ""
end

---@param e { attr: pandoc.Attr }
---@return nil
function M.SetSource(e, source)
	e.attr.attributes["data-pos"] = source
end

---RemoveSources removes data-pos attributes from elements.
---It only removes the attributes, it doesn't remove Divs and Spans created for them.
---It is recommended to call RemoveRedundants after RemoveSources to have a clearer document.
---@param doc pandoc.Pandoc
---@return pandoc.Pandoc
function M.RemoveSources(doc)
	return doc:walk({
		---@param b pandoc.Block
		---@return pandoc.Block
		Block = function(b)
			if b["attr"] ~= nil then
				M.removeSource(b)
			end
			return b
		end,

		---@param i pandoc.Inline
		---@return pandoc.Inline
		Inline = function(i)
			if i["attr"] ~= nil then
				M.removeSource(i)
			end
			return i
		end,
	})
end

---@param e { attr: pandoc.Attr }
---@return nil
function M.removeSource(e)
	-- pandoc.Attr.attributes is not a simple table, it is a table with repeatable keys.
	-- The while loop ensures we remove the key completely.
	-- In practice Pandoc have produced documents with multiple data-pos attributes.
	while e.attr.attributes["data-pos"] ~= nil do
		e.attr.attributes["data-pos"] = nil
	end
end

---RemoveRedundants replaces Divs and Spans that don't have anything on them with their content.
---@param doc pandoc.Pandoc
---@return pandoc.Pandoc
function M.RemoveRedundants(doc)
	return doc:walk({
		---@param d pandoc.Div
		---@return pandoc.Div | pandoc.Blocks
		Div = function(d)
			if M.isRedundant(d) then
				return d.content
			end
			return d
		end,

		---@param s pandoc.Span
		---@return pandoc.Span | pandoc.Inlines
		Span = function(s)
			if M.isRedundant(s) then
				return s.content
			end
			return s
		end,
	})
end

---@param e pandoc.Div | pandoc.Span
---@return boolean
function M.isRedundant(e)
	if e.attr.identifier ~= "" then
		return false
	end
	if #e.attr.classes > 0 then
		return false
	end
	for _ in pairs(e.attr.attributes) do
		return false
	end
	return true
end

return M
