local cc = require("neo-tree.sources.common.commands")
local manager = require("neo-tree.sources.manager")

local M = {}

local function kind_to_str(kind)
	return string.format("%s", vim.lsp.protocol.SymbolKind[kind])
end

-- https://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
-- vim.tbl_extend overwrites values assuming position in array is its key
function TableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
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
		local name = node.name
		if node.containerName ~= nil then
			fragments = vim.fn.split(node.containerName, "\\.")
		end
		if #vim.fn.split(name,"\\.") then
			local extra_frags = vim.fn.split(name, "\\.")
			name = table.remove(extra_frags, #extra_frags)
			fragments = TableConcat(fragments, extra_frags)
		end
		local target = root
		for _, x in pairs(fragments) do
			if target[x] == nil then
				target[x] = {}
			end
			target = target[x]
		end
		target[name] = node
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
			if data ~= nil then
				local map = array_to_tree(data)
				local root = parse_tree(map, 'root', 'workspace symbols')
				local prev_root = state.symboltree[1]
				if prev_root ~= nil then
					root.children = TableConcat(prev_root.children, root.children)
				end
				state.symboltree = { root }
			end
			manager.refresh("symbolmap")
		end)
	end)
end

M.delete = function(state)
	vim.ui.input({ prompt = "clear symbol tree? (y/n)" }, function(input)
		if input == 'y' or input == 'Y' then
			state.symboltree = { {
				id = 'root',
				name = 'workspace symbols',
				type = 'directory',
				children = { }
			} }
			manager.refresh("symbolmap")
		end
	end)
end

cc._add_common_commands(M)
return M
