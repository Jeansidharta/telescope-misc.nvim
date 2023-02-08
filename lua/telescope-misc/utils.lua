local previewers = require("telescope.previewers")
local pickers = require("telescope.pickers")
local action_state = require("telescope.actions.state")

local utils = {}

---@param previewer_name string
---@param initial_value string[]
---@param on_entry_change fun(entry: any, bufnr: number): nil
function utils.previewer_static_buffer(previewer_name, initial_value, on_entry_change) end

---@param text string
---@return number
function utils.search_text_on_previewer(text)
	local text_line = vim.fn.search("^" .. text .. "\\s", "n")
	local window_height = vim.fn.winheight(0)
	local window_top_line = text_line - window_height / 2
	local window_bottom_line = text_line + window_height / 2
	if window_top_line >= 0 then
		vim.cmd("normal " .. window_top_line .. "G")
	else
		vim.cmd("normal gg")
	end
	vim.cmd("normal " .. window_bottom_line .. "G")
	vim.cmd("normal " .. text_line .. "G")
	vim.cmd("normal 0") -- Go to the start of the line
	return text_line - 1
end

function utils.state_aware_picker(opts, config)
	local state = {
		previewer = {
			bufnr = nil,
			win = nil,
		},
		prompt = {
			bufnr = nil,
		},
	}

	state.picker = function()
		return action_state.get_current_picker(state.prompt.bufnr)
	end

	state.refresh_previewer = function(new_lines)
		vim.api.nvim_buf_set_lines(state.previewer.bufnr, 0, -1, false, new_lines)
	end

	local did_setup = false

	pickers
		.new(
			opts,
			vim.tbl_extend("force", config, {
				previewer = previewers.new_buffer_previewer({
					title = config.prompt_title,
					get_buffer_by_name = function()
						return config.prompt_title
					end,
					define_preview = function(self, entry)
						local bufnr = self.state.bufnr
						state.previewer.bufnr = bufnr
						state.previewer.win = self.state.winid
						if not did_setup then
							did_setup = true
							vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, config.initial_preview_value)
							local callback = ((config.previewer or {}).on_setup or function(...) end)
							callback(state)
							vim.wait(0)
						end

						vim.api.nvim_buf_call(bufnr, function()
							local callback = ((config.previewer or {}).on_changed_entry or function(...) end)
							callback(entry, state)
						end)
					end,
				}),

				attach_mappings = function(prompt_bufnr, ...)
					state.prompt.bufnr = prompt_bufnr
					return (config.attach_mappings or function(...) end)(state, ...)
				end,
			})
		)
		:find()
end

return utils
