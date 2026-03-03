return {
	"folke/trouble.nvim",
	opts = {},
	cmd = "Trouble",
	keys = {
		{
			"<leader>tt",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		{
			"<leader>tT",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		{
			"[t",
			"<cmd>Trouble next skip_groups=true jump=true<cr>",
			desc = "Next Trouble Item",
		},
		{
			"]t",
			"<cmd>Trouble prev skip_groups=true jump=true<cr>",
			desc = "Previous Trouble Item",
		},
	},
}
