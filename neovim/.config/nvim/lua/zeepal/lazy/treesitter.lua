return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local parsers = {
				"lua",
				"vim",
				"vimdoc",
				"bash",
				"gitignore",
				"json",
				"yaml",
				"toml",
				"dockerfile",
				"terraform",
				"hcl",
				"python",
				"go",
				"rust",
				"markdown",
				"markdown_inline",
				"html",
				"typst",
				"awk",
				"comment",
				"c",
				"cpp",
				"javascript",
				"typescript",
				"make",
				"powershell",
				"regex",
				"requirements",
				"sql",
				"csv",
			}

			local ts = require("nvim-treesitter")
			ts.setup({})
			ts.install(parsers)

			local max_filesize = 100 * 1024
			local large_file_warned = {}

			local function should_disable(buf)
				if vim.bo[buf].filetype == "html" then
					return true
				end

				local name = vim.api.nvim_buf_get_name(buf)
				if name == "" then
					return false
				end

				local ok, stats = pcall(vim.uv.fs_stat, name)
				if ok and stats and stats.size > max_filesize then
					if not large_file_warned[buf] then
						large_file_warned[buf] = true
						vim.notify(
							"File larger than 100KB treesitter disabled for performance",
							vim.log.levels.WARN,
							{ title = "Treesitter" }
						)
					end
					return true
				end

				return false
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("zeepal_treesitter_start", { clear = true }),
				callback = function(args)
					if should_disable(args.buf) then
						return
					end

					pcall(vim.treesitter.start, args.buf)
					if vim.bo[args.buf].filetype == "markdown" then
						vim.bo[args.buf].syntax = "on"
					end
				end,
			})

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("zeepal_treesitter_indent", { clear = true }),
				callback = function(args)
					if should_disable(args.buf) then
						return
					end

					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				multiwindow = false, -- Enable multiwindow support.
				max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 20, -- Maximum number of lines to show for a single context
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
}
