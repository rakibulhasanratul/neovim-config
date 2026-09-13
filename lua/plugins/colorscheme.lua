return {
	"EdenEast/nightfox.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("nightfox").setup({
			options = {
				transparent = false,
				terminal_colors = true, -- Set terminal colors (vim.g.terminal_color_*) used in `:terminal`
				styles = {
					comments = "italic",
					conditionals = "italic",
					constants = "NONE",
					functions = "NONE",
					keywords = "bold",
					numbers = "NONE",
					operators = "bold",
					strings = "NONE",
					types = "italic",
					variables = "NONE",
				},
			},
		})

		vim.cmd("colorscheme carbonfox") -- load colorscheme
	end,
}
