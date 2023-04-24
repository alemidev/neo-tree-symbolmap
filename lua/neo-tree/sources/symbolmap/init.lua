local renderer = require("neo-tree.ui.renderer")

local M = { name = "symbolmap" }

M.navigate = function(state, path)
	if path == nil then
		path = vim.fn.getcwd()
	end
	state.path = path

	if state.symboltree == nil then
		state.symboltree = { {
			id = 'root',
			name = 'workspace symbols',
			type = 'directory',
			children = { {
				id = 'root.help',
				name = "use 'a' to query LS",
				type = 'module',
				children = { }
			} }
		} }
	end

	renderer.show_nodes(state.symboltree, state)
end

M.setup = function(config, global_config) end

return M
