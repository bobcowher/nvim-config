-- Leader must be set before lazy.setup and any <leader> mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.wo.relativenumber = true

vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.signcolumn = "yes"
vim.opt.tabstop = 4     -- display width of a literal tab
vim.opt.shiftwidth = 4  -- width of >>, <<, and auto-indent

-- Visual mode tab to indent, shift-tab to outdent
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true, silent = true })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true, silent = true })

-- Show Errors -- 
vim.keymap.set("n", "<S-e>", function()
  vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
end, { desc = "Show diagnostic under cursor" })

-- Comments --
-- Normal mode
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment line" })
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment line" })

-- Visual mode
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment selection" })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment selection" })

-- neovim tree toggle --
vim.api.nvim_set_keymap('n', '<C-t>', '<ESC>:NvimTreeToggle<CR>', { noremap = true, silent = true })

--- Launch OpenAI -- 
vim.api.nvim_set_keymap('n', '<C-S-g>', '<ESC>:GpChatToggle split<CR>', { noremap = true, silent = true })


-- Python Execute Code 
dofile(vim.fn.stdpath("config") .. "/python_runner.lua")
dofile(vim.fn.stdpath("config") .. "/build.lua")
dofile(vim.fn.stdpath("config") .. "/runner_close.lua")

-- Load Lazy
vim.opt.rtp:prepend("~/.config/nvim/lazy/lazy.nvim")

require("lazy").setup({
{
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      on_highlights = function(hl)
        -- Changed lines in diffs: tokyonight's DiffChange (#1f2231) is barely
        -- distinguishable from the background. Amber, as strong as add/delete.
        hl.DiffChange = { bg = "#4a3f1f" }
        hl.DiffText = { bg = "#7a6324" } -- the changed words within the line
      end,
    })
    vim.cmd("colorscheme tokyonight-night") -- or tokyonight-storm
  end
},
{
    "robitx/gp.nvim",
    config = function()
        local conf = {
            -- For customization, refer to Install > Configuration in the Documentation/Readme
        }
        require("gp").setup(conf)

        -- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
    end,
},
  -- Mason (LSP installer)
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "basedpyright", "pyright", "lemminx", "rust_analyzer", "taplo" },
        -- Servers are enabled explicitly below. Auto-enable would start every
        -- installed server: basedpyright alongside pyright, and a second
        -- rust_analyzer alongside rustaceanvim's.
        automatic_enable = false,
      })
    end
  },
  -- Language Server Protocol
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config('clangd', {
        cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
      })

      -- Python language server. Measured with bench/run.sh; see bench/README.md.
      --   NVIM_PYTHON_LS=pyright        (default) pyright with background analysis
      --   NVIM_PYTHON_LS=pyright-plain  stock pyright: rollback, ~1.5s completion lag
      --   NVIM_PYTHON_LS=basedpyright   for comparison: slower diagnostics when measured
      local python_ls = vim.env.NVIM_PYTHON_LS or "pyright"
      local python_path = vim.env.CONDA_PREFIX and (vim.env.CONDA_PREFIX .. "/bin/python") or "python3"
      local python_analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
        autoImportCompletions = false,
      }
      local pyright_dir = vim.fn.stdpath("data") .. "/mason/packages/pyright/node_modules/pyright"
      if python_ls == "pyright" and (vim.fn.isdirectory(pyright_dir) == 0 or vim.fn.executable("node") == 0) then
        python_ls = "pyright-plain"
      end

      -- Why background analysis matters: without it, pyright type-checks the
      -- whole file on its main thread after every keystroke (~1s on
      -- torch/transformers code) and completion requests wait behind that.
      -- Getting it to work in Neovim takes four things VS Code's client does:
      --   1. --cancellationReceive=file:<name>, or pyright never starts the worker
      --   2. the cancellation folder must exist; the *client* creates it. If it's
      --      missing, cancellation fails silently and the worker fully checks
      --      every stale keystroke version (diagnostics lag ~5s)
      --   3. push diagnostics: pull returns stale results in background mode
      --   4. (Mason's npm pyright only) pyright-bg.js, so the worker starts at all
      local cancel_name = "nvim-" .. vim.fn.getpid()
      local cancel_flag = "--cancellationReceive=file:" .. cancel_name
      if python_ls ~= "pyright-plain" then
        local cancel_dir = vim.fs.joinpath(vim.uv.os_tmpdir(), "python-languageserver-cancellation", cancel_name)
        vim.fn.mkdir(cancel_dir, "p")
        vim.api.nvim_create_autocmd("VimLeavePre", {
          callback = function() vim.fn.delete(cancel_dir, "rf") end,
        })
      end

      -- The main thread keeps its own type cache, so the first completion that
      -- touches a heavy import (transformers: ~4s) is slow once per session.
      -- One throwaway completion on attach pays that while you're still reading.
      local function prewarm(client, bufnr)
        client:request("textDocument/completion", {
          textDocument = { uri = vim.uri_from_bufnr(bufnr) },
          position = { line = vim.api.nvim_buf_line_count(bufnr) - 1, character = 0 },
        }, function() end, bufnr)
      end

      if python_ls == "basedpyright" then
        vim.lsp.config('basedpyright', {
          cmd = { "basedpyright-langserver", "--stdio", cancel_flag },
          init_options = { disablePullDiagnostics = true },
          on_attach = prewarm,
          settings = {
            python = { pythonPath = python_path },
            basedpyright = {
              analysis = vim.tbl_extend("force", python_analysis, {
                typeCheckingMode = "standard", -- basedpyright defaults to the much stricter "recommended"
              }),
            },
          },
        })
      else
        if python_ls == "pyright" then
          vim.lsp.config('pyright', {
            cmd = { "node", vim.fn.stdpath("config") .. "/pyright-bg.js", "--stdio", cancel_flag },
            cmd_env = { PYRIGHT_DIR = pyright_dir },
            init_options = { disablePullDiagnostics = true },
            on_attach = prewarm,
          })
        end
        python_ls = "pyright"
        vim.lsp.config('pyright', {
          settings = { python = { pythonPath = python_path, analysis = python_analysis } },
        })
      end

      local lemminx_cmd = vim.fn.expand("~/.local/share/nvim/mason/bin/lemminx")
      if vim.fn.executable(lemminx_cmd) == 1 then
        vim.lsp.config('lemminx', {
          cmd = { lemminx_cmd },
          settings = {
            xml = {
              validation = { noGrammar = "ignore" }
            }
          }
        })
        vim.lsp.enable('lemminx')
      end

      -- rust_analyzer is managed by rustaceanvim
      vim.lsp.enable({ 'clangd', python_ls, 'taplo' })
    end
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false,
    init = function()
      vim.g.rustaceanvim = {
        server = {
          standalone = false,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
              },
              check = {
                command = "clippy",
              },
            },
          },
        },
      }
    end,
  },
-- Lazy.nvim
  {
    "mg979/vim-visual-multi",
    branch = "master"
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip"
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
	  -- ["<CR>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<Tab>"] = cmp.mapping.confirm({ select = true }),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          {
            name = "nvim_lsp",
            entry_filter = function(entry)
              local item = entry.completion_item
              local text = item.textEdit and item.textEdit.newText or item.insertText
              if text and text:find("\n") then
                -- Strip multi-line override stub to just the method name
                if item.textEdit then
                  item.textEdit.newText = item.label
                end
                item.insertText = item.label
                item.insertTextFormat = 1  -- PlainText
              end
              return true
            end,
          },
          { name = "jupyter" },
          { name = "luasnip" },
        }),
	completion = {
	  autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged },
	  completeopt = "menu,menuone,noinsert",
	  keyword_length = 1,
	},
      })
	-- After cmp.setup(...)
	local cmp_autopairs = require("nvim-autopairs.completion.cmp")
	local cmp = require("cmp")

	cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end
  },
{
  "numToStr/Comment.nvim",
  event = "VeryLazy",
  config = function()
    require("Comment").setup()
  end,
},
  {
    "tpope/vim-fugitive",
     config = function()
     -- Optional: keybindings
     vim.keymap.set("n", "<leader>gs", ":Git<CR>", { desc = "Git status" })
    end
  },
  -- Treesitter (syntax highlighting)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local parsers = { "lua", "python", "bash", "json", "c", "cpp", "xml", "astro", "rust", "toml" }
      require("nvim-treesitter").install(parsers)

      local filetypes = { "lua", "python", "sh", "json", "c", "cpp", "xml", "astro", "rust", "toml" }
      local indent_disabled = { c = true, cpp = true, astro = true, python = true }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = filetypes,
        callback = function(args)
          vim.treesitter.start(args.buf)
          if not indent_disabled[vim.bo[args.buf].filetype] then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end
  },

  -- File explorer
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require("nvim-tree").setup({
				view = {
					width = 45,
				}
			})
    end
  },
-- Auto-pairing
{
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    require("nvim-autopairs").setup({})
  end
},
-- XML tag auto-closing
{
  "windwp/nvim-ts-autotag",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("nvim-ts-autotag").setup({
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true
      },
      per_filetype = {
        xml = {
          enable_close = true
        }
      }
    })
  end
},
-- Git: hunks in the gutter of the buffer you're editing
{
  "lewis6991/gitsigns.nvim",
  event = "BufReadPre",
  opts = {
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      -- Jump between hunks (falls back to native ]c/[c inside diff mode)
      map("n", "]c", function()
        if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
      end, "Next hunk")
      map("n", "[c", function()
        if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
      end, "Prev hunk")

      map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>ga", gs.stage_hunk, "Stage/unstage hunk")
      map("n", "<leader>gr", gs.reset_hunk, "Revert hunk")
      map("v", "<leader>ga", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selected lines")
      map("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Revert selected lines")
      map("n", "<leader>gR", gs.reset_buffer, "Revert whole file")
      map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
    end,
  },
},

-- Git: VS Code-style review of all changed files / branches / history
{
  "dlyongemallo/diffview-plus.nvim",
  version = "*",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggle" },
  opts = {
    hooks = {
      -- Show the whole file, not just changes with 6 lines of context.
      -- zi in a diff window turns the folds back on.
      -- nowrap keeps the panes aligned: the two panes differ in width, so a
      -- long line can wrap on one side only and push everything below down.
      diff_buf_win_enter = function()
        vim.opt_local.foldenable = false
        vim.opt_local.wrap = false
      end,
    },
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Review uncommitted changes" },
    { "<leader>gD", function()
        vim.ui.input({ prompt = "Diff against (e.g. main, main...HEAD): " }, function(rev)
          if rev and rev ~= "" then vim.cmd("DiffviewOpen " .. rev) end
        end)
      end, desc = "Diff against branch/rev" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "History of this file" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "History of repo" },
    { "<leader>gc", "<cmd>DiffviewClose<CR>", desc = "Close diffview" },
  },
},

  {
    "ray-x/lsp_signature.nvim",
    event = "InsertEnter",
    config = function()
      require("lsp_signature").setup({
        bind = true,
        auto_attach = true,
        hint_enable = false,
        floating_window = true,
        handler_opts = { border = "rounded" },
      })
    end,
  },
  {
    "bobcowher/neovim-graphics-viewer",
    tag = "v1.1.0",
    config = function()
      require("nvim-gfx").setup()
    end,
  },
  {
    dir = "~/rustprojects/neovim-jupyter",
    build = "./build.sh",
    config = function()
      require("nvim-jupyter").setup()
    end,
  },


})

vim.lsp.config('*', {
  flags = { debounce_text_changes = 50 }
})

vim.diagnostic.config({ update_in_insert = true })

vim.api.nvim_create_user_command("LspRestart", function()
  vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
  vim.cmd("e")
end, {})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local first_arg = vim.fn.argv(0)
    local is_dir = first_arg and vim.fn.isdirectory(first_arg) == 1

    if is_dir or #vim.fn.argv() == 0 then
      -- Prevent buffer from being replaced
      vim.cmd("enew")
      vim.cmd("NvimTreeToggle")
    end
  end
})
