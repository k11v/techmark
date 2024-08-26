---@class writer.gost
local M = {}

local element = require("internal.element")
local file = require("internal.file")
local link = require("writer.gost.internal.link")
local code = require("writer.gost.internal.code")
local tbl = require("writer.gost.internal.tbl")
local contents = require("writer.gost.internal.contents")
local references = require("writer.gost.internal.references")
local list = require("writer.gost.internal.list")

---@param doc pandoc.Pandoc
---@param opts pandoc.WriterOptions
---@return string
function M.Write(doc, opts)
	local latexWriter = M.newLatexWriter(opts)
	local nativeWriter = M.newNativeWriter(opts)

	doc = doc:walk({
		---@param d pandoc.Div
		---@return pandoc.Block
		Div = function(d)
			return list.WriteOrderedListFromDiv(d)
				or contents.WriteContentsFromDiv(d)
				or references.WriteReferencesFromDiv(d)
				or d
		end,
		---@param s pandoc.Span
		---@return pandoc.Inline
		Span = function(s)
			return link.WriteLinkGroupFromSpan(s) or s
		end,
		---@param c pandoc.Code
		---@return pandoc.Inline
		Code = function(c)
			return code.WriteCode(c)
		end,
		---@param f pandoc.Figure
		---@return pandoc.Block
		Figure = function(f)
			return code.WriteCodeFigure(f) or tbl.WriteTableFigure(f) or f
		end,
	})

	doc = element.RemoveSources(doc)
	doc = element.RemoveMerges(doc)
	doc = element.RemoveRedundants(doc)

	-- Option csquotes depends on package csquotes.
	doc.meta["csquotes"] = true

	if opts.variables["template_development"] ~= nil and opts.variables["template_development"]:render() == "1" then
		io.stderr:write(nativeWriter.write(doc))
	end

	return latexWriter.write(doc)
end

---@return string
function M.template()
	local script_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
	local template_file = pandoc.path.join({ script_dir, "template.tex" })
	local template = file.Read(template_file)
	assert(template ~= nil)
	return template
end

---@param opts pandoc.WriterOptions
---@return { write: fun(d: pandoc.Pandoc): string }
function M.newLatexWriter(opts)
	return {
		---@param doc pandoc.Pandoc
		---@return string
		write = function(doc)
			return pandoc.write(doc, {
				format = "latex",
				extensions = {
					auto_identifiers = false,
					latex_macros = false,
					smart = true,
					task_lists = true,
				},
			}, opts)
		end,
	}
end

---@param opts pandoc.WriterOptions
---@return { write: fun(d: pandoc.Pandoc): string }
function M.newNativeWriter(opts)
	return {
		---@param doc pandoc.Pandoc
		---@return string
		write = function(doc)
			return pandoc.write(doc, { format = "native" }, opts)
		end,
	}
end

-- Pandoc bindings

---@param doc pandoc.Pandoc
---@param opts pandoc.WriterOptions
---@return string
function Writer(doc, opts)
	return M.Write(doc, opts)
end

---@return string
function Template()
	return M.template()
end

---@type { [string]: boolean }
Extensions = {}

return M
