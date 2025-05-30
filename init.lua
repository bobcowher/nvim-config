vim.wo.relativenumber = true

vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
vim.opt.clipboard = "unnamedplus"

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

-- Visual mode
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment selection" })

-- neovim tree toggle --
vim.api.nvim_set_keymap('n', '<C-t>', '<ESC>:NvimTreeToggle<CR>', { noremap = true, silent = true })


-- Python Execute Code 
dofile(vim.fn.stdpath("config") .. "/python_runner.lua")
dofile(vim.fn.stdpath("config") .. "/build.lua")

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
  -- Language Server Protocol
  {
    "neovim/nvim-lspconfig",
    config = function()
	require("lspconfig").clangd.setup({
		cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },			
	})
	require("lspconfig").pyright.setup({
	  settings = {
	    python = {
	      pythonPath = vim.env.CONDA_PREFIX and (vim.env.CONDA_PREFIX .. "/bin/python") or "python3",
	      analysis = {
		autoSearchPaths = true,
		diagnosticMode = "openFilesOnly",
		useLibraryCodeForTypes = true,
	      },
	    },
	  },
	})

    end
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
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }),
	completion = {
	  autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged },
	  completeopt = "menu,menuone,noinsert",
	  keyword_length = 1,
	  entries_limit = 3, -- 🔥 Limit to top 3 results
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
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "bash", "json", "c", "cpp" },
        highlight = { enable = true },
        indent = { 
	 enable = true,
	 disable = {"c", "cpp"},
	},
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

})

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


