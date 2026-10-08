return {
	-- LazyGit via snacks.nvim
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			lazygit = {
				configure = true,
				config = {
					os = { editPreset = "nvim-remote" },
					gui = {
						nerdFontsVersion = "3",
					},
				},
				theme = {
					[241] = { fg = "Special" },
					activeBorderColor = { fg = "MatchParen", bold = true },
					cherryPickedCommitBgColor = { fg = "Identifier" },
					cherryPickedCommitFgColor = { fg = "Function" },
					defaultFgColor = { fg = "Normal" },
					inactiveBorderColor = { fg = "FloatBorder" },
					optionsTextColor = { fg = "Function" },
					searchingActiveBorderColor = { fg = "MatchParen", bold = true },
					selectedLineBgColor = { bg = "Visual" },
					unstagedChangesColor = { fg = "DiagnosticError" },
				},
			},
		},
		keys = {
			{
				"<leader>lg",
				function()
					Snacks.lazygit.open()
				end,
				desc = "LazyGit",
			},
			{
				"<leader>gf",
				function()
					Snacks.lazygit.log()
				end,
				desc = "LazyGit Repo History",
			},
			{
				"<leader>gF",
				function()
					Snacks.lazygit.log_file()
				end,
				desc = "LazyGit Current File History",
			},
		},
		config = function(_, opts)
			require("snacks").setup(opts)

			-- Diffview integration: press <C-d> in lazygit terminal to open Diffview
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "lazygit",
				callback = function()
					vim.keymap.set("t", "<C-d>", function()
						vim.cmd("DiffviewOpen")
					end, { buffer = true, desc = "Open Diffview" })
				end,
			})
		end,
	},

	-- Git signs
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "│" },
					change = { text = "│" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
				},
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns
					local map = vim.keymap.set

					-- Navigation
					map("n", "]c", function()
						if vim.wo.diff then
							return "]c"
						end
						vim.schedule(function()
							gs.next_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, buffer = bufnr, desc = "Next git hunk" })

					map("n", "[c", function()
						if vim.wo.diff then
							return "[c"
						end
						vim.schedule(function()
							gs.prev_hunk()
						end)
						return "<Ignore>"
					end, { expr = true, buffer = bufnr, desc = "Previous git hunk" })

					-- Actions
					map("n", "<leader>hs", gs.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
					map("n", "<leader>hr", gs.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
					map("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
					map("n", "<leader>hb", function()
						gs.blame_line({ full = true })
					end, { buffer = bufnr, desc = "Blame line" })
				end,
			})
		end,
	},
	-- Git Conflict management
	{
		"akinsho/git-conflict.nvim",
		version = "*",
		event = { "BufReadPost", "BufNewFile" },
		keys = {
			{ "<leader>gco", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose Ours" },
			{ "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose Theirs" },
			{ "<leader>gcb", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose Both" },
			{ "<leader>gcn", "<cmd>GitConflictChooseNone<cr>", desc = "Choose None" },
			{ "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Previous Conflict" },
			{ "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next Conflict" },
		},
		config = function()
			require("git-conflict").setup({
				default_mappings = true,
				disable_diagnostics = false,
				highlights = {
					incoming = "DiffAdd",
					current = "DiffText",
				},
			})
		end,
	},

	-- Diffview: For file/repo history and merge visualization
	{
		"sindrets/diffview.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
			{ "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo History" },
		},
		config = function()
			require("diffview").setup({
				enhanced_diff_hl = true,
				view = {
					merge_tool = {
						layout = "diff3_mixed", -- show base + theirs + ours
					},
				},
			})
		end,
	},
}
