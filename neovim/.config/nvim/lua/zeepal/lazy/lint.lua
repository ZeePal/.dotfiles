return {
	"mfussenegger/nvim-lint",
	dependencies = {
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	event = {
		"BufReadPre",
		"BufNewFile",
	},
	config = function()
		require("mason-tool-installer").setup({
			ensure_installed = {
				"tree-sitter-cli",
				"pylint",
				"actionlint",
				"ansible-lint",
				"cfn-lint",
				"tfsec",
				"isort",
				"goimports",
				"shellcheck",
				"trufflehog",
				"markdownlint-cli2",
			},
		})
		local lint = require("lint")
		lint.linters_by_ft = {
			terraform = { "tfsec" },
			["yaml.ansible"] = { "ansible_lint" },
			["yaml.github_actions"] = { "actionlint" },
			["yaml.cloudformation"] = { "cfn_lint" },
			markdown = { "markdownlint-cli2" },
		}
		lint.linters["markdownlint-cli2"].args =
			{ "--config", vim.fn.expand("~") .. "/.config/.markdownlint-cli2.yaml", "-" }

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
