return {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = {
		{ "williamboman/mason.nvim", opts = {} },
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		{ "j-hui/fidget.nvim", opts = {} },
		"saghen/blink.cmp",
		"folke/snacks.nvim",
		-- LSP file operations support
		{
			"antosha417/nvim-lsp-file-operations",
			dependencies = { "nvim-lua/plenary.nvim" },
			event = "InsertEnter",
		},
		{
			"mfussenegger/nvim-jdtls", -- required for jdtls
		},
	},
	config = function()
		-- Server-specific configs live in after/lsp/<name>.lua and are merged
		-- automatically on top of the defaults shipped by nvim-lspconfig.

		-- Check whether an executable exists on the system PATH, ignoring
		-- mason's own bin dir (which mason prepends to PATH and would otherwise
		-- shadow system-wide installs).
		local function system_wide(exe)
			local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
			for dir in vim.env.PATH:gmatch("[^:]+") do
				if dir ~= mason_bin and vim.fn.executable(dir .. "/" .. exe) == 1 then
					return true
				end
			end
			return false
		end

		-- Every enabled server has a config file in after/lsp/<name>.lua, so
		-- the file names are the single source of truth for the server list.
		local function lsp_servers()
			local names = {}
			for file in vim.fs.dir(vim.fn.stdpath("config") .. "/after/lsp") do
				if file:match("%.lua$") then
					table.insert(names, (file:gsub("%.lua$", "")))
				end
			end
			table.sort(names)
			return names
		end

		-- LspAttach autocommand for keymaps
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
			callback = function(event)
				local map = vim.keymap.set

				-- Navigation
				map("n", "gd", vim.lsp.buf.definition, { buffer = event.buf, desc = "[G]oto [D]efinition" })
				map("n", "gD", vim.lsp.buf.declaration, { buffer = event.buf, desc = "[G]oto [D]eclaration" })
				map("n", "gi", vim.lsp.buf.implementation, { buffer = event.buf, desc = "[G]oto [I]mplementation" })
				map("n", "gr", vim.lsp.buf.references, { buffer = event.buf, desc = "[G]oto [R]eferences" })
				map("n", "gt", vim.lsp.buf.type_definition, { buffer = event.buf, desc = "[G]oto [T]ype Definition" })

			-- Document symbols
			map({ "n", "v" }, "gO", function()
				---@cast Snacks Snacks
				Snacks.picker.lsp_symbols()
			end, { buffer = event.buf, desc = "Open Document Symbols" })

			-- Workspace symbols
			map({ "n", "v" }, "gW", function()
				---@cast Snacks Snacks
				Snacks.picker.lsp_workspace_symbols()
			end, { buffer = event.buf, desc = "Open Workspace Symbols" })

				-- Documentation
				map("n", "<leader>k", vim.lsp.buf.hover, { buffer = event.buf, desc = "Hover documentation" })
				map(
					{ "n", "i" },
					"<C-Space>",
					vim.lsp.buf.signature_help,
					{ buffer = event.buf, desc = "Signature help" }
				)

				-- Code actions
				map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = event.buf, desc = "Code action" })

				-- Rename
				map("n", "<leader>rn", vim.lsp.buf.rename, { buffer = event.buf, desc = "[R]e[n]ame" })

				-- Diagnostics
				map("n", "[d", function()
					vim.diagnostic.jump({ count = -1 })
				end, { buffer = event.buf, desc = "Previous diagnostic" })
				map("n", "]d", function()
					vim.diagnostic.jump({ count = 1 })
				end, { buffer = event.buf, desc = "Next diagnostic" })
				map("n", "<leader>ld", vim.diagnostic.open_float, { buffer = event.buf, desc = "Show diagnostic" })
				map("n", "<leader>cl", "<cmd>LspInfo<cr>", { buffer = event.buf, desc = "LSP Info" })
				map("n", "<leader>lr", "<cmd>lsp restart<cr>", { buffer = event.buf, desc = "Restart LSP" })

				-- Highlight references under cursor
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if
					client
					and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
				then
					local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						group = highlight_augroup,
						callback = vim.lsp.buf.clear_references,
					})

					vim.api.nvim_create_autocmd("LspDetach", {
						group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
						callback = function(event2)
							vim.lsp.buf.clear_references()
							vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
						end,
					})
				end
			end,
		})

		-- Diagnostic configuration
		vim.diagnostic.config({
			severity_sort = true,
			float = { border = "rounded", source = true },
			underline = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.INFO] = "",
					[vim.diagnostic.severity.HINT] = "",
				},
			} or {},
			virtual_text = {
				source = "if_many",
				spacing = 2,
				format = function(diagnostic)
					return diagnostic.message
				end,
			},
		})

		-- Global defaults: share blink.cmp completion capabilities with every server
		vim.lsp.config("*", {
			capabilities = require("blink.cmp").get_lsp_capabilities(),
		})

		-- Helper function to skip system-wide installations for tools
		local function skip_if_system_wide_tools(tools)
			local mason_registry = require("mason-registry")
			return vim.tbl_filter(function(tool_name)
				local ok, pkg = pcall(mason_registry.get_package, tool_name)
				if not ok then
					return true
				end
				-- Check if any executable from this package exists on PATH
				for _, exe in ipairs(pkg.spec.bin or {}) do
					if system_wide(exe) then
						return false
					end
				end
				return true
			end, tools)
		end

		-- Helper function to skip system-wide installations for LSP servers
		local function skip_if_system_wide_lsp(servers)
			local mason_registry = require("mason-registry")
			return vim.tbl_filter(function(server_name)
				local pkg_name = require("mason-lspconfig").get_mappings().lspconfig_to_package[server_name]
				if not pkg_name then
					return true
				end -- not handled by Mason
				local ok, pkg = pcall(mason_registry.get_package, pkg_name)
				if not ok then
					return true
				end
				for _, exe in ipairs(pkg.spec.bin or {}) do
					if system_wide(exe) then
						return false
					end
				end
				return true
			end, servers)
		end

		-- Servers are derived from after/lsp/*.lua, so adding a server is just
		-- creating its config file.
		-- jdtls is handled by nvim-jdtls plugin (not lspconfig), so exclude it.
		local servers = vim.tbl_filter(function(name)
			return name ~= "jdtls"
		end, lsp_servers())

		-- Tools to install (formatters, linters, etc.)
		local tools = {
			"stylua",
			"clang-format",
			"biome",
			"ruff",
			"google-java-format",
			"checkstyle",
			"hyprls",
			-- Java LSP ecosystem
			"jdtls",
		}

		-- Install tools (skipping system-wide installations)
		require("mason-tool-installer").setup({
			ensure_installed = skip_if_system_wide_tools(tools),
			auto_update = true,
			run_on_start = true,
		})

		-- Install LSP servers with Mason (skipping system-wide installations).
		-- automatic_enable is disabled since we enable all configured servers
		-- explicitly below, which also covers system-wide installations.
		require("mason-lspconfig").setup({
			ensure_installed = skip_if_system_wide_lsp(servers),
			automatic_enable = false,
		})

		-- Enable LSP servers: nvim auto-starts them when a matching filetype
		-- (and root dir, if required) is detected.
		vim.lsp.enable(servers)
	end,
}
