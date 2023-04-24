local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")
local lspkind = require('lspkind')

local lsp_highlights = {
	Text = highlights.NORMAL,
	Method = highlights.GIT_STAGED,
	Function = highlights.GIT_STAGED,
	Constructor = highlights.GIT_STAGED,
	Field = highlights.GIT_ADDED,
	Variable = highlights.GIT_ADDED,
	Class = highlights.GIT_CONFLICT,
	Interface = highlights.GIT_CONFLICT,
	Module = highlights.GIT_UNTRACKED,
	Property = highlights.GIT_ADDED,
	Unit = highlights.GIT_CONFLICT,
	Value = highlights.GIT_CONFLICT,
	Enum = highlights.GIT_CONFLICT,
	Keyword = highlights.GIT_DELETED,
	Snippet = highlights.GIT_IGNORED,
	Color = highlights.GIT_IGNORED,
	File = highlights.GIT_RENAMED,
	Reference = highlights.GIT_IGNORED,
	Folder = highlights.DIRECTORY_ICON,
	EnumMember = highlights.GIT_CONFLICT,
	Constant = highlights.GIT_DELETED,
	Struct = highlights.GIT_RENAMED,
	Event = highlights.GIT_UNSTAGED,
	Operator = highlights.GIT_DELETED,
	TypeParameter = highlights.GIT_UNSTAGED,
}

local M = {}

M.icon = function(config, node, state)
	local icon = config.default or " "
	local padding = config.padding or " "
	local highlight = config.highlight or highlights.FILE_ICON
	if node.type == "directory" then
		highlight = highlights.DIRECTORY_ICON
		if node:is_expanded() then
			icon = config.folder_open or "-"
		else
			icon = config.folder_closed or "+"
		end
	elseif node.type == "file" then
		if node.extra.kind ~= nil then
			icon = lspkind.symbolic(node.extra.kind, { mode = "symbol" })
			if #icon == 0 then
				icon = '?'
			end
			highlight = lsp_highlights[node.extra.kind] or highlights.DIM_TEXT
		else
			local success, web_devicons = pcall(require, "nvim-web-devicons")
			if success then
				local devicon, hl = web_devicons.get_icon(node.name, node.ext)
				icon = devicon or icon
				highlight = hl or highlight
			end
		end
	end
	return {
		text = icon .. padding,
		highlight = highlight,
	}
end

M.name = function(config, node, state)
	local highlight = config.highlight or highlights.FILE_NAME
	if node.type == "directory" then
		highlight = highlights.DIRECTORY_NAME
	end
	if node:get_depth() == 1 then
		highlight = highlights.ROOT_NAME
	end
	return {
		text = node.name,
		highlight = highlight,
	}
end

return vim.tbl_deep_extend("force", common, M)
