return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = { "n", "v" },
			desc = "Format",
		},
	},

	config = function()
		require("conform").setup({
			formatters_by_ft = {
				python = { "ruff_format" },
				javascript = { "biome" },
				typescript = { "biome" },
				javascriptreact = { "biome" },
				typescriptreact = { "biome" },
				json = { "biome" },
				css = { "biome" },
				html = { "biome" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				lua = { "stylua" },
				markdown = { "markdownlint" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		})

		-- Install formatters via Mason
		vim.api.nvim_create_autocmd("User", {
			pattern = "MasonToolsUpdateCompleted",
			callback = function()
				vim.schedule(function()
					local registry = require("mason-registry")
					local formatters = { "ruff", "stylua", "biome", "markdownlint", "clang-format" }
					for _, formatter in ipairs(formatters) do
						if not registry.is_installed(formatter) then
							vim.cmd("MasonInstall " .. formatter)
						end
					end
				end)
			end,
		})
	end,
}
