return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			terminal = {},
			scratch = {
				autowrite = true,
				filekey = {
					cwd = true,
					branch = true,
					count = true,
				},
			},
			toggle = {},
			input = {},
			notifier = {
				enabled = true,
				timeout = 3000,
				margin = { top = 0, right = 1, bottom = 1 },
				top_down = false,
			},
		},
		keys = {
			{
				"<leader>tt",
				function()
					Snacks.terminal()
				end,
				desc = "Toggle Terminal",
			},
			{
				"<leader>.",
				function()
					Snacks.scratch()
				end,
				desc = "Toggle Scratch Buffer",
			},
			{
				"<leader>S",
				function()
					Snacks.scratch.select()
				end,
				desc = "Select Scratch Buffer",
			},
			{
				"<leader>tw",
				function()
					Snacks.toggle.option("wrap", { name = "Wrap" }):toggle()
				end,
				desc = "Toggle Wrap",
			},
			{
				"<leader>tl",
				function()
					Snacks.toggle.line_number():toggle()
				end,
				desc = "Toggle Line Numbers",
			},
			{
				"<leader>tn",
				function()
					Snacks.toggle.option("relativenumber", { name = "Relative Number" }):toggle()
				end,
				desc = "Toggle Relative Numbers",
			},
			{
				"<leader>td",
				function()
					Snacks.toggle.diagnostics():toggle()
				end,
				desc = "Toggle Diagnostics",
			},
			{
				"<leader>tc",
				function()
					Snacks.toggle
						.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
						:toggle()
				end,
				desc = "Toggle Conceal Level",
			},
			{
				"<leader>th",
				function()
					Snacks.toggle.inlay_hints():toggle()
				end,
				desc = "Toggle Inlay Hints",
			},
			{
				"<leader>tb",
				function()
					Snacks.toggle
						.option("background", { off = "light", on = "dark", name = "Dark Background" })
						:toggle()
				end,
				desc = "Toggle Dark Background",
			},
			{
				"<leader>tg",
				function()
					Snacks.toggle.indent():toggle()
				end,
				desc = "Toggle Indent Guides",
			},
		},
		config = function(_, opts)
			require("snacks").setup(opts)
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<leader>nl", "<cmd>NoiceLog<cr>", desc = "Noice Log" },
			{ "<leader>nh", "<cmd>NoiceHistory<cr>", desc = "Noice History" },
			{ "<leader>nd", "<cmd>NoiceDismiss<cr>", desc = "Dismiss Notifications" },
		},
		config = function()
			require("noice").setup({
				cmdline = {
					enabled = true,
					view = "cmdline_popup", -- Classic command line at the bottom
					format = {
						cmdline = { icon = "  " },
						search_down = { icon = "  " },
						search_up = { icon = "  " },
						filter = { icon = "  " },
						lua = { icon = "  " },
						help = { icon = "  " },
					},
				},
				popupmenu = {
					enabled = true,
					backend = "nui", -- Use nui for completion menu
				},
				messages = {
					enabled = true,
					view = "snacks",
					view_error = "snacks",
					view_warn = "snacks",
					view_history = "messages",
					view_search = "virtualtext",
				},
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
					progress = {
						enabled = true,
						format = "lsp_progress",
						view = "mini",
					},
					hover = {
						enabled = true,
						silent = false,
					},
					signature = {
						enabled = true,
					},
				},
				presets = {
					bottom_search = true,
					command_palette = true,
					long_message_to_split = true,
					inc_rename = false,
					lsp_doc_border = true,
				},
				views = {
					notify = {
						backend = { "snacks", "notify" },
						fallback = "mini",
						format = "notify",
						replace = false,
						merge = false,
					},
				},
				routes = {
					{
						filter = {
							event = "msg_show",
							kind = "",
							find = "written",
						},
						opts = { skip = true },
					},
				},
			})
		end,
	},
}
