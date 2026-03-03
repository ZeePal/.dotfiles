require("zeepal.set")
require("zeepal.remap")
require("zeepal.init_lazy")

local augroup = vim.api.nvim_create_augroup
local ZeePalGroup = augroup("ZeePal", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})

autocmd({ "BufWritePre" }, {
	group = ZeePalGroup,
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

autocmd("LspAttach", {
	group = ZeePalGroup,
	callback = function(e)
		local opts = { buffer = e.buf }
		vim.keymap.set("n", "gd", function()
			vim.lsp.buf.definition()
		end, opts)
		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover()
		end, opts)
		vim.keymap.set("n", "<leader>vws", function()
			vim.lsp.buf.workspace_symbol()
		end, opts)
		vim.keymap.set("n", "<leader>vd", function()
			vim.diagnostic.open_float()
		end, opts)
		vim.keymap.set("n", "<leader>vca", function()
			vim.lsp.buf.code_action()
		end, opts)
		vim.keymap.set("n", "<leader>vrr", function()
			vim.lsp.buf.references()
		end, opts)
		vim.keymap.set("n", "<leader>vrn", function()
			vim.lsp.buf.rename()
		end, opts)
		vim.keymap.set("i", "<C-h>", function()
			vim.lsp.buf.signature_help()
		end, opts)
		vim.keymap.set("n", "[d", function()
			vim.diagnostic.goto_next()
		end, opts)
		vim.keymap.set("n", "]d", function()
			vim.diagnostic.goto_prev()
		end, opts)
	end,
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

vim.filetype.add({
	pattern = {
		[".*/%.github/workflows/.*%.yml"] = "yaml.github_actions",
		[".*/playbooks/.*%.yml"] = "yaml.ansible",
		[".*/roles/.*%.yml"] = "yaml.ansible",
		[".*%.ansible%.yml"] = "yaml.ansible",
		[".*%.ya?ml"] = function(path, bufnr)
			local content = vim.api.nvim_buf_get_lines(bufnr, 0, 10, false)
			for _, line in ipairs(content) do
				if line:match("AWSTemplateFormatVersion") or line:match("Resources:") then
					return "yaml.cloudformation"
				end
			end
		end,
		[".*%.json"] = function(path, bufnr)
			local content = vim.api.nvim_buf_get_lines(bufnr, 0, 10, false)
			for _, line in ipairs(content) do
				if line:match('"AWSTemplateFormatVersion"') or line:match('"Resources"') then
					return "yaml.cloudformation"
				end
			end
		end,
	},
})
