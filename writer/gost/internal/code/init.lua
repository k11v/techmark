---@class writer.gost.internal.code
local M = {}

local e = require("internal.element")
local log = require("internal.log")

---@param c pandoc.Code
---@return pandoc.Inline
function M.WriteCode(c)
	local content = c.text
	local language = c.attr.classes[1] or ""
	if language == "" then
		language = "text"
	end
	return e.Merge({ e.Tex([[\mintinline{]]), e.Tex(language), e.Tex([[}`]]), e.Tex(content), e.Tex([[`]]) })
end

---@param f pandoc.Figure
---@return pandoc.Block|nil
function M.WriteCodeFigure(f)
	if not M.isCodeFigure(f) then
		return nil
	end

	local caption = e.Inline(e.MergeBlock(f.caption.long))
	local label = e.Tex(f.attr.identifier)

	local codeItems = M.itemsFromCodeFigure(f)
	if #codeItems ~= 1 then
		log.Error(
			"got " .. #codeItems .. "items in code figure, want " .. 1,
			"wrong-code-figure-item-count",
			e.GetSource(f)
		)
		return nil
	end
	local language = e.Tex(codeItems[1].language ~= "" and codeItems[1].language or "text")
	local content = e.Tex(codeItems[1].content)

	return pandoc.Plain({
		e.Merge({ e.Tex([[\noindent\begin{minipage}{\textwidth}]]), e.Tex("\n") }),
		e.Merge({ e.Tex([[\captionof{figure}{]]), caption, e.Tex([[}\label{]]), label, e.Tex([[}]]), e.Tex("\n") }),
		e.Merge({ e.Tex([[\end{minipage}]]), e.Tex("\n") }),
		e.Merge({ e.Tex("\n") }),
		e.Merge({ e.Tex([[\begin{tcolorbox}[ ]]), e.Tex("\n") }),
		e.Merge({ e.Tex([[  breakable=true,]]), e.Tex("\n") }),
		e.Merge({ e.Tex([[] ]]), e.Tex("\n") }),
		e.Merge({ e.Tex([[\begin{minted}{]]), language, e.Tex([[}]]), e.Tex("\n") }),
		e.Merge({ content, e.Tex("\n") }),
		e.Merge({ e.Tex([[\end{minted}]]), e.Tex("\n") }),
		e.Merge({ e.Tex([[\end{tcolorbox}]]) }),
	})
end

---@param f pandoc.Figure
---@return boolean
function M.isCodeFigure(f)
	for i = 1, #f.content do
		if not (f.content[i].tag == "Code" or f.content[i].tag == "CodeBlock") then
			return false
		end
	end
	return true
end

---@param f pandoc.Figure
---@return { language: string, content: string }[]
function M.itemsFromCodeFigure(f)
	local codeFigureContent = f.content --[[@as pandoc.List<pandoc.Code|pandoc.CodeBlock>]]
	for i = 1, #codeFigureContent do
		assert(codeFigureContent[i].tag == "Code" or codeFigureContent[i].tag == "CodeBlock")
	end

	---@type { language: string, content: string }[]
	local codes = {}
	for i = 1, #codeFigureContent do
		local c = codeFigureContent[i]
		table.insert(codes, { language = M.languageFromCode(c), content = M.contentFromCode(c) })
	end

	return codes
end

---@param c pandoc.Code|pandoc.CodeBlock
---@return string
function M.languageFromCode(c)
	return c.attr.classes[1] or ""
end

---@param c pandoc.Code|pandoc.CodeBlock
---@return string
function M.contentFromCode(c)
	return c.text
end

return M
