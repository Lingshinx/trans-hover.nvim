local M = {}

---@class Trans.Option
---@field translator string[]
---@field sentence_translator string[]
local config = {
	translator = { "kd" },
	sentence_translator = { "kd", "-t" },
}

---@param list table
---@return table
local function flatten(list)
	return vim.iter(list):flatten():totable()
end

M.setup = function(opts)
	opts = opts or {}

	if opts.translator and opts.sentence_translator == nil then
		opts.sentence_translator = opts.translator
	end

	config = vim.tbl_deep_extend("keep", opts, config)
end

local function trans_word(word)
	return vim.fn.system(flatten({ config.translator, word }))
end

local function trans_sentence(sentence, callback)
	return vim.system(flatten({ config.sentence_translator, sentence }), {}, callback)
end

---@return string
local function get_word()
	return vim.fn.expand("<cword>")
end

local function trans_result()
	return {
		contents = {
			kind = "markdown",
			value = trans_word(get_word()),
		},
	}
end

local function has_noice()
	return package.loaded["noice"] and require("noice.config").options.lsp.hover.enabled
end

M.is_trans_enabled = false

local noice = require("noice.lsp.hover")

local origin_function = has_noice() and noice.on_hover or vim.lsp.buf.hover

local function toggle_noice()
	if M.is_trans_enabled then
		noice.on_hover = origin_function
	else
		origin_function = noice.on_hover
		noice.on_hover = function(_, result, ctx)
			origin_function(_, trans_result(), ctx)
		end
	end
end

local function toggle_hover()
	if M.is_trans_enabled then
		vim.lsp.buf.hover = origin_function
	else
		origin_function = vim.lsp.buf.hover
		vim.lsp.buf.hover = function(config)
			config = config or {}
			config.focus_id = require("vim.lsp.protocol").Methods.textDocument_hover
			vim.lsp.util.open_floating_preview(vim.split(trans_word(get_word()), "\n"), "markdown", config)
		end
	end
end

local origin_keyword = vim.o.keywordprg
local toggle_trans = has_noice() and toggle_noice or toggle_hover

vim.api.nvim_create_user_command("TransToggle", function()
	vim.o.keywordprg = M.is_trans_enabled and ":Trans" or origin_keyword
	toggle_trans()
	M.is_trans_enabled = not M.is_trans_enabled
end, { nargs = 0 })

vim.api.nvim_create_user_command("Trans", function(opts)
	trans_sentence(opts.args, function(result)
		print(result.stdout)
	end)
end, { nargs = "+" })

return M
