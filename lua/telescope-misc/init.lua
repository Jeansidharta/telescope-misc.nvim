local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local utils = require("telescope-misc.utils")

local namespace = vim.api.nvim_create_namespace("TelescopeCustomPreviewers")

local telescope_misc = {}

function telescope_misc.syntax(opts)
	opts = opts or {}
	local initial_buffer = vim.api.nvim_get_current_buf()

	function make_syntax_values()
		local syntax = vim.split(vim.api.nvim_exec(":syntax", true), "\n", {})

		local entries = vim.tbl_map(
			function(item)
				return vim.split(item, " ", {})[1]
			end,
			vim.tbl_filter(function(item)
				if vim.startswith(item, " ") or vim.startswith(item, "---") then
					return false
				end
				return true
			end, syntax)
		)
		return syntax, entries
	end

	local syntax, entries = make_syntax_values()

	function make_finder(new_entries)
		return finders.new_table({
			results = new_entries,
			entry_maker = function(entry)
				return {
					value = entry,
					display = function()
						local highligh_groups = {}
						return entry, highligh_groups
					end,
					ordinal = entry,
				}
			end,
		})
	end

	utils.state_aware_picker(opts, {
		prompt_title = "Syntax",
		finder = make_finder(entries),
		sorter = conf.generic_sorter(opts),
		initial_preview_value = syntax,
		previewer = {
			on_changed_entry = function(entry, state)
				local line = utils.search_text_on_previewer(entry.value)
				vim.api.nvim_buf_clear_namespace(state.previewer.bufnr, namespace, 0, -1)
				vim.api.nvim_buf_add_highlight(state.previewer.bufnr, namespace, "Cursor", line, 0, -1)
			end,
		},
		attach_mappings = function(state, mapping)
			actions.select_default:replace(function() end)

			local function delete_syntax()
				vim.api.nvim_buf_call(initial_buffer, function()
					local selection = action_state.get_selected_entry().value
					vim.cmd(":syntax clear " .. selection)

					local new_syntax, new_entries = make_syntax_values()
					state.picker():refresh(make_finder(new_entries))
					state.refresh_previewer(new_syntax)
				end)
			end

			local function reset_syntax()
				vim.cmd([[:syntax reset]])
			end

			mapping("n", "x", delete_syntax)
			mapping("i", "<C-x>", delete_syntax)
			mapping("n", "r", reset_syntax)
			mapping("i", "<C-r>", reset_syntax)

			return true
		end,
	})
end

function telescope_misc.extensions(opts, selected_extension)
	opts = opts or {}

	selected_extension = selected_extension or nil

	function make_finder()
		if selected_extension then
			return finders.new_table(vim.tbl_keys(require("telescope").extensions[selected_extension]))
		else
			return finders.new_table(vim.tbl_keys(require("telescope").extensions))
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Extensions",
			finder = make_finder(),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function()
				actions.select_default:replace(function(prompt)
					local selection = action_state.get_selected_entry()[1]
					if selected_extension then
						require("telescope").extensions[selected_extension][selection](opts)
					else
						selected_extension = selection
						action_state.get_current_picker(prompt):refresh(make_finder())
					end
				end)
				return true
			end,
		})
		:find()
end

function telescope_misc.namespaces(opts)
	opts = opts or {}

	local entries = {}
	for key, value in pairs(vim.api.nvim_get_namespaces()) do
		table.insert(entries, { name = key, id = value })
	end

	pickers
		.new(opts, {
			prompt_title = "Namespaces",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = function()
							return entry.id .. " " .. entry.name, { { { 0, #(tostring(entry.id)) }, "Constant" } }
							-- return entry.id .. " " .. entry.name, {}
						end,
						ordinal = entry.id .. " " .. entry.name,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry().value
					vim.fn.setreg([[""]], selection.name, "c")
					actions.close(prompt)
				end)

				return true
			end,
		})
		:find()
end

function telescope_misc.augroups()
	opts = opts or {}

	function augroups()
		return vim.split(vim.api.nvim_exec(":augroup", true), "  ", {})
	end

	pickers
		.new(opts, {
			prompt_title = "Namespaces",
			finder = finders.new_table(augroups()),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt, mapping)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()[1]
					vim.fn.setreg([[""]], selection, "c")
					actions.close(prompt)
				end)

				local function delete_augroup()
					local selection = action_state.get_selected_entry()[1]
					vim.api.nvim_del_augroup_by_name(selection)
					vim.notify("Group " .. selection .. " deleted")
					action_state.get_current_picker(prompt):refresh(finders.new_table(augroups()))
				end

				mapping("n", "d", delete_augroup)
				mapping("i", "<c-d>", delete_augroup)

				return true
			end,
		})
		:find()
end

function telescope_misc.options()
	opts = opts or {}

	local options = {}
	for key, value in pairs(vim.api.nvim_get_all_options_info()) do
		table.insert(options, { name = key, desc = value })
	end

	local current_window = vim.api.nvim_get_current_win()
	local current_buffer = vim.api.nvim_get_current_buf()

	function get_option_value(name)
		return try_value(function()
			return vim.opt[name]:get()
		end) or try_value(function()
			return vim.opt_local[name]:get()
		end) or try_value(function()
			return vim.opt_global[name]:get()
		end) or try_value(vim.api.nvim_get_option, name) or try_value(
			vim.api.nvim_win_get_option,
			current_window,
			name
		) or try_value(vim.api.nvim_buf_get_option, current_buffer, name)
	end

	function resolve_highlight_group(t)
		if t == "number" then
			return "Number"
		elseif t == "string" then
			return "String"
		elseif t == "boolean" then
			return "Boolean"
		elseif t == "function" then
			return "Function"
		elseif t == "table" then
			return "Structure"
		end
		return ""
	end

	function try_value(...)
		local ok, res = pcall(...)
		if ok then
			return { highlight = resolve_highlight_group(type(res)), str = vim.inspect(res) }
		else
			return nil
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Options",
			previewer = previewers.new_buffer_previewer({
				title = "Options",
				get_buffer_by_name = function()
					return "Options"
				end,
				define_preview = function(self, entry)
					local desc = vim.split(vim.inspect(entry.option.desc), "\n", {})
					local name = entry.option.name
					local value = vim.split((entry.value or {}).str or "", "\n", {})

					local lines = vim.tbl_flatten({
						"Option name: " .. name,
						{ "", "--------------------------------------------", "", "Option details:" },
						desc,
						{ "", "--------------------------------------------", "", "Option value:" },
						value,
					})
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

					vim.api.nvim_win_set_option(self.state.winid, "wrap", true)

					vim.api.nvim_buf_add_highlight(self.state.bufnr, 0, "Constant", 0, string.find(lines[1], ":"), -1)
					vim.api.nvim_buf_add_highlight(self.state.bufnr, 0, "WinSeparator", 2, 0, -1)
					for i = 5, #desc + 5, 1 do
						vim.api.nvim_buf_add_highlight(self.state.bufnr, 0, "Identifier", i, 0, -1)
					end
					vim.api.nvim_buf_add_highlight(self.state.bufnr, 0, "WinSeparator", #desc + 6, 0, -1)
					for i = #desc + 9, #desc + 9 + #value, 1 do
						vim.api.nvim_buf_add_highlight(
							self.state.bufnr,
							0,
							(entry.value or {}).highlight or "",
							i,
							0,
							-1
						)
					end
				end,
			}),
			finder = finders.new_table({
				results = options,
				entry_maker = function(option)
					local name = option.name
					local value = get_option_value(name)

					if value then
						name = name .. " = " .. string.gsub(value.str, "%s+", " ")
					end

					return {
						value = value,
						option = option,
						display = function()
							local hl = {
								{ { 0, #option.name }, "Constant" },
							}
							if value then
								table.insert(hl, {
									{ #option.name + 3, #option.name + 300 },
									value.highlight,
								})
							end

							return name, hl
						end,
						ordinal = name,
					}
				end,
			}),
			sorter = conf.generic_sorter(opts),
		})
		:find()
end

-- TODO options picker using vim.api.nvim_get_all_options_info()

return telescope_misc
