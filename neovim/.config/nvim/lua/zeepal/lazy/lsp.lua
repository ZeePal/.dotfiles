return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"stevearc/conform.nvim",
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"j-hui/fidget.nvim",
	},

	config = function()
		local cmp = require("cmp")
		local cmp_lsp = require("cmp_nvim_lsp")
		local capabilities = vim.tbl_deep_extend(
			"force",
			{},
			vim.lsp.protocol.make_client_capabilities(),
			cmp_lsp.default_capabilities()
		)

		require("fidget").setup({})
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"rust_analyzer",
				"gopls",
				"bashls",
				"jsonls",
				"yamlls",
				"terraformls",
				"pyright",
				"ruff",
				"pylsp",
				"marksman",
				"vtsls",
				"ansiblels",
				"powershell_es",
				"dockerls",
				"gh_actions_ls",
				"taplo", -- toml
			},
		})

		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
					format = {
						enable = true,
						-- Put format options here
						-- NOTE: the value should be STRING!!
						defaultConfig = {
							indent_style = "space",
							indent_size = "2",
						},
					},
				},
			},
		})

		vim.lsp.config("pyright", {
			settings = {
				pyright = {
					-- Using Ruff's import organizer
					disableOrganizeImports = true,
				},
			},
		})

		vim.lsp.config("pylsp", {
			capabilities = capabilities,
			settings = {
				pylsp = {
					plugins = {
						pylint = {
							enabled = true,
							args = { "--ignore=C0301,C0114" },
						},
						mccabe = {
							enabled = false,
						},
						pyflakes = {
							enabled = false,
						},
						pycodestyle = {
							enabled = false,
						},
					},
				},
			},
		})

		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					format = {
						enable = true,
					},
					hover = true,
					completion = true,
					schemaStore = {
						enable = true,
					},

					customTags = {
						"!And sequence",
						"!Base64 scalar",
						"!Cidr scalar",
						"!Condition scalar",
						"!Equals sequence",
						"!FindInMap sequence",
						"!GetAtt scalar",
						"!GetAtt sequence",
						"!GetAZs scalar",
						"!If sequence",
						"!ImportValue scalar",
						"!Join sequence",
						"!Not sequence",
						"!Or sequence",
						"!Ref scalar",
						"!Select sequence",
						"!Split sequence",
						"!Sub scalar",
						"!Transform mapping",
					},
				},
			},
		})

		local cmp_select = { behavior = cmp.SelectBehavior.Select }

		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
				["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
				["<C-y>"] = cmp.mapping.confirm({ select = true }),
				["<C-Space>"] = cmp.mapping.complete(),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" }, -- For luasnip users.
			}, {
				{ name = "buffer" },
			}),
		})

		vim.diagnostic.config({
			-- update_in_insert = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if client == nil then
					return
				end
				if client.name == "ruff" then
					-- Disable hover in favor of Pyright
					client.server_capabilities.hoverProvider = false
				end
			end,
			desc = "LSP: Disable hover capability from Ruff",
		})
	end,
}
