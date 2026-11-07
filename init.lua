vim.wo.relativenumber = true

vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.signcolumn = "yes"

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
        ensure_installed = { "clangd", "pyright", "lemminx", "rust_analyzer", "taplo" }
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

      vim.lsp.config('pyright', {
        settings = {
          python = {
            pythonPath = vim.env.CONDA_PREFIX and (vim.env.CONDA_PREFIX .. "/bin/python") or "python3",
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "openFilesOnly",
              useLibraryCodeForTypes = true,
              autoImportCompletions = false,
            },
          },
        },
      })

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
      vim.lsp.enable({ 'clangd', 'pyright', 'taplo' })
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
{
  "lewis6991/gitsigns.nvim",
  event = "BufReadPre",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local gitsigns = require("gitsigns")
    vim.api.nvim_create_autocmd("BufWinEnter", {
      callback = function(args)
        local buf = args.buf
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        -- Only attach if this is a fugitive buffer or gitcommit/diff
        if ft == "fugitive" or ft == "gitcommit" or ft == "diff" then
          gitsigns.attach(buf)
        else
          gitsigns.detach(buf)
        end
      end
    })
  end,
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
