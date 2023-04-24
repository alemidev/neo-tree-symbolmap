local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")

local M = {}

local function kind_to_str(kind)
	return string.format("%s", vim.lsp.protocol.SymbolKind[kind])
end

local function parse_tree(tree, id, name)
	if tree.name ~= nil then
		return {
			id = id .. math.random(0, bit.lshift(1, 30)),
			name = tree.name,
			type = 'file',
			extra = { kind = kind_to_str(tree.kind) },
			path = tree.location.uri,
		}
	end
	local children = {}
	for key, val in pairs(tree) do
		table.insert(children, parse_tree(val, id .. '.' .. key, key))
	end
	table.sort(children, function(a, b)
		if a.type == 'directory' and b.type ~= 'directory' then
			return true
		end
		if a.type ~= 'directory' and b.type == 'directory' then
			return false
		end
		return a.name < b.name
	end)
	return {
		id = id,
		name = name,
		type = 'directory',
		children = children
	}
end

local function array_to_tree(array)
	local root = {}
	for _, node in pairs(array) do
		local fragments = {}
		if node.containerName ~= nil then
			fragments = vim.fn.split(node.containerName, "\\.")
		end
		local target = root
		for _, x in pairs(fragments) do
			if target[x] == nil then
				target[x] = {}
			end
			target = target[x]
		end
		target[node.name] = node
	end
	return root
end

M.refresh = require("neo-tree.utils").wrap(require("neo-tree.sources.manager").refresh, "symbolmap")

local function find_last_buffer()
	local cur = vim.api.nvim_get_current_buf()
	local tabpage = vim.api.nvim_win_get_tabpage(0)
	local winlist = vim.api.nvim_tabpage_list_wins(tabpage)
	for _, win in ipairs(winlist) do
		local buf = vim.api.nvim_win_get_buf(win)
		if (buf ~= cur) then
			return buf
		end
	end
	return 0
end

M.add = function(state)
	vim.ui.input({ prompt = "query" }, function(input)
		local buf = find_last_buffer()
		vim.lsp.buf_request(buf, 'workspace/symbol', { query = input }, function(err, data, _, _)
			local root = {
				id = "root",
				name = "workspace symbols",
				type = "directory",
				children = {}
			}
			if data ~= nil then
				local map = array_to_tree(data)
				root = parse_tree(map, 'root', 'workspace symbols')
			end
			vim.tbl_deep_extend('force', state.symboltree, { root })
			manager.refresh("symbolmap")
		end)
		state.symboltree = { {
			id = "root",
			name = "reloading symbols ...",
			type = "directory",
			children = {}
		} }
		manager.refresh("symbolmap")
	end)
end

M.delete = function(state)
	state.symboltree = { }
	manager.refresh("symbolmap")
end

cc._add_common_commands(M)
return M
