---@class reader
local M = {}

local code = require("reader.internal.code")
local image = require("reader.internal.image")
local link = require("reader.internal.link")
local mth = require("reader.internal.mth")
local tbl = require("reader.internal.tbl")

---@param srcs pandoc.Sources
---@param opts pandoc.ReaderOptions
---@return pandoc.Pandoc
function M.Read(srcs, opts)
	local markdownReader = M.newMarkdownReader(opts)

	local doc = markdownReader.read(srcs)

	doc = doc:walk({
		---@param cb pandoc.CodeBlock
		---@return pandoc.Block
		CodeBlock = function(cb)
			return code.ReadFigureFromCodeBlock(cb, markdownReader)
		end,
		---@param d pandoc.Div
		---@return pandoc.Block
		Div = function(d)
			local imageFigure = image.ReadFigureFromDiv(d, markdownReader)
			if imageFigure ~= nil then
				return imageFigure
			end

			local mathFigure = mth.ReadFigureFromDiv(d, markdownReader)
			if mathFigure ~= nil then
				return mathFigure
			end

			return d
		end,
		---@param inlines pandoc.Inlines
		---@return pandoc.Inlines
		Inlines = function(inlines)
			return link.ReadInlinesWithGroupsFromInlines(inlines, doc.meta["references"] or {})
		end,
		---@param t pandoc.Table
		---@return pandoc.Block
		Table = function(t)
			return tbl.ReadFigureFromTable(t, markdownReader)
		end,
	})

	return doc
end

---@param opts pandoc.ReaderOptions
---@return { read: fun(input: (string | pandoc.Sources)): pandoc.Pandoc }
function M.newMarkdownReader(opts)
	local htmlReader = M.newHTMLReader(opts)

	return {
		---@param input string | pandoc.Sources
		---@return pandoc.Pandoc
		read = function(input)
			local doc = pandoc.read(input, {
				format = "commonmark",
				extensions = {
					-- GFM extensions.
					autolink_bare_uris = true, -- https://github.github.com/gfm/#autolinks-extension-
					footnotes = true, -- https://github.blog/changelog/2021-09-30-footnotes-now-supported-in-markdown-fields/
					pipe_tables = true, -- https://github.github.com/gfm/#tables-extension-
					strikeout = true, -- https://github.github.com/gfm/#strikethrough-extension-
					task_lists = true, -- https://github.github.com/gfm/#task-list-items-extension-
					-- Must-have extensions.
					attributes = true,
					tex_math_dollars = true,
					-- Handy extensions.
					wikilinks_title_after_pipe = true, -- https://help.obsidian.md/Linking+notes+and+files/Internal+links
					bracketed_spans = true,
					fenced_divs = true,
					smart = true,
					sourcepos = true,
					yaml_metadata_block = true,
				},
			}, opts)

			doc = doc:walk({
				---@param ri pandoc.RawInline
				---@return pandoc.Inlines
				RawInline = function(ri)
					local blocks = htmlReader.read(ri.text).blocks
					local inlines = pandoc.utils.blocks_to_inlines(blocks)
					return inlines
				end,
				---@param rb pandoc.RawBlock
				---@return pandoc.Blocks
				RawBlock = function(rb)
					local blocks = htmlReader.read(rb.text).blocks
					return blocks
				end,
			})

			return doc
		end,
	}
end

---@param opts pandoc.ReaderOptions
---@return { read: fun(input: (string | pandoc.Sources)): pandoc.Pandoc }
function M.newHTMLReader(opts)
	return {
		---@param input string | pandoc.Sources
		---@return pandoc.Pandoc
		read = function(input)
			return pandoc.read(input, {
				format = "html",
				extensions = {
					auto_identifiers = false,
					empty_paragraphs = true,
					line_blocks = false,
					smart = true,
					task_lists = true,
					tex_math_dollars = true,
				},
			}, opts)
		end,
	}
end

-- Pandoc bindings

---@param srcs pandoc.Sources
---@param opts pandoc.ReaderOptions
---@return pandoc.Pandoc
function Reader(srcs, opts)
	return M.Read(srcs, opts)
end

return M
