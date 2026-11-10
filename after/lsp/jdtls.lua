-- High-performance JDTLS configuration using nvim-jdtls plugin
-- Provides fast, accurate Java LSP with Maven/Gradle support, Lombok, debugging

local jdtls = require("jdtls")
local mason_registry = require("mason-registry")

-- Helper to get Mason package install path
local function mason_pkg_path(pkg_name)
  local ok, pkg = pcall(mason_registry.get_package, pkg_name)
  if not ok then
    return nil
  end
  return pkg:get_install_path()
end

-- Find the JDTLS installation (Mason installs it)
local jdtls_path = mason_pkg_path("jdtls")
if not jdtls_path then
  vim.notify("JDTLS not found in Mason. Run :MasonInstall jdtls", vim.log.levels.ERROR)
  return {}
end

-- Find java-debug bundles for debugging support (optional, install java-debug-adapter via Mason if needed)
local bundles = {}
local java_debug_path = mason_pkg_path("java-debug-adapter")
if java_debug_path then
  local debug_jars = vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true)
  vim.list_extend(bundles, debug_jars)
end

-- Lombok support (auto-download if not present)
local lombok_path = jdtls_path .. "/lombok.jar"
if vim.fn.filereadable(lombok_path) == 0 then
  -- Download lombok silently in background
  vim.system({
    "curl", "-L", "-o", lombok_path,
    "https://projectlombok.org/downloads/lombok.jar"
  }, function(obj)
    if obj.code == 0 then
      vim.schedule(function()
        vim.notify("Lombok downloaded successfully", vim.log.levels.INFO)
      end)
    end
  end)
end

-- Determine project root (Maven/Gradle/git)
local root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", ".git" }
local root_dir = jdtls.setup.find_root(root_markers) or vim.fn.getcwd()

-- Unique workspace directory per project (for shared indexes)
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

-- JVM arguments optimized for performance
local jvm_args = {
  "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  "-Dosgi.bundles.defaultStartLevel=4",
  "-Declipse.product=org.eclipse.jdt.ls.core.product",
  "-Dlog.level=WARNING",
  "-Xmx2G",                      -- Heap size (adjust based on RAM)
  "-Xms512m",                    -- Initial heap
  "-XX:+UseZGC",                 -- Modern low-latency GC (Java 15+)
  "-XX:+UseStringDeduplication", -- Reduce memory for duplicate strings
  "--add-modules=ALL-SYSTEM",
  "--add-opens", "java.base/java.util=ALL-UNNAMED",
  "--add-opens", "java.base/java.lang=ALL-UNNAMED",
  "--add-opens", "java.base/java.io=ALL-UNNAMED",
  "-javaagent:" .. lombok_path,  -- Lombok agent
}

-- JDTLS server configuration
local config = {
  cmd = {
    "java",
    table.unpack(jvm_args),
    "-jar",
    vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
    "-configuration",
    jdtls_path .. "/config_linux",
    "-data",
    workspace_dir,
  },

  root_dir = root_dir,

  -- Performance-critical settings
  settings = {
    java = {
      -- Signature help
      signatureHelp = { enabled = true },

      -- Content provider (for javadoc)
      contentProvider = { preferred = "fernflower" },

      -- Completion settings
      completion = {
        favoriteStaticMembers = {
          "org.junit.jupiter.api.Assertions.*",
          "org.junit.jupiter.api.Assumptions.*",
          "org.mockito.Mockito.*",
          "org.mockito.ArgumentMatchers.*",
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
        importOrder = {
          "java",
          "javax",
          "org",
          "com",
        },
        -- Use faster completion
        guessMethodArguments = true,
        maxResults = 50,
      },

      -- Code generation
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },

      -- Format settings (google-java-format via conform.nvim handles formatting)
      format = {
        enabled = false, -- Let conform.nvim handle formatting
      },

      -- Organize imports
      saveActions = {
        organizeImports = true,
      },

      -- Maven/Gradle integration
      maven = {
        downloadSources = true,
        downloadJavadoc = true,
        updateSnapshots = true,
      },
      gradle = {
        downloadSources = true,
        downloadJavadoc = true,
        wrapper = {
          enabled = true,
        },
      },

      -- Project settings
      configuration = {
        updateBuildConfiguration = "interactive",
        runtimes = {
          {
            name = "JavaSE-21",
            path = vim.fn.expand("$JAVA_HOME"),
            default = true,
          },
          {
            name = "JavaSE-17",
            path = vim.fn.expand("$JAVA_17_HOME"),
          },
        },
      },

      -- Performance: disable expensive features unless needed
      references = {
        includeDecompiledSources = false,
      },
      inlayHints = {
        parameterNames = {
          enabled = "literals", -- Only for literals, not all params
        },
      },

      -- Eclipse-specific optimizations
      eclipse = {
        downloadSources = true,
      },

      -- Cleanup on save
      cleanup = {
        actionsOnSave = {
          "organizeImports",
        },
      },
    },
  },

  -- Initialization options for bundles (debugging, testing)
  init_options = {
    bundles = bundles,
    extendedClientCapabilities = jdtls.extendedClientCapabilities,
  },

  -- Capabilities for blink.cmp
  capabilities = require("blink.cmp").get_lsp_capabilities(),

  -- on_attach function for keymaps and extra setup
  on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

    -- JDTLS-specific keymaps
    local opts = { buffer = bufnr, silent = true }
    local map = vim.keymap.set

    -- Java-specific: organize imports
    map("n", "<leader>oi", jdtls.organize_imports, vim.tbl_extend("force", opts, { desc = "Organize Imports" }))

    -- Java-specific: extract variable/constant/method
    map("v", "<leader>ev", jdtls.extract_variable, vim.tbl_extend("force", opts, { desc = "Extract Variable" }))
    map("v", "<leader>ec", jdtls.extract_constant, vim.tbl_extend("force", opts, { desc = "Extract Constant" }))
    map("v", "<leader>em", jdtls.extract_method, vim.tbl_extend("force", opts, { desc = "Extract Method" }))

    -- Java-specific: test commands (require java-test bundle)
    -- map("n", "<leader>jt", jdtls.test_nearest_method, vim.tbl_extend("force", opts, { desc = "Test Nearest Method" }))
    -- map("n", "<leader>jT", jdtls.test_class, vim.tbl_extend("force", opts, { desc = "Test Class" }))

    -- Java-specific: update project config
    map("n", "<leader>ju", jdtls.update_projects_config, vim.tbl_extend("force", opts, { desc = "Update Project Config" }))

    -- DAP integration (optional: install java-debug-adapter via Mason to enable)
    local ok, dap = pcall(require, "dap")
    if ok and #bundles > 0 then
      jdtls.setup_dap({ hotcodereplace = "auto" })
      jdtls.setup_dap_main_class_configs()
    end
  end,

  -- Flags for performance
  flags = {
    allow_incremental_sync = true,
    debounce_text_changes = 150,
  },
}

-- Start JDTLS
jdtls.start_or_attach(config)

return config