return {
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            highlight = {
                comments_only = false,
                pattern = [[<(KEYWORDS)>]], -- Vim Regex
                keyword = "bg",         -- No "Wide" plz
            },
            search = {
                pattern = [[\b(KEYWORDS)\b]], -- RipGrep Regex
            },
        }
    }
}
