-- ~/.config/nvim/build.lua  —  single clean build pane
vim.keymap.set("n", "<C-b>", function()
  local term_cmd  = "./build.sh"
  local orig_win  = vim.api.nvim_get_current_win()

  ---------------------------------------------------------------------------
  -- 1. find *any* buffer that has b.build_runner == true -------------------
  ---------------------------------------------------------------------------
  local build_buf, build_win = nil, nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].build_runner then
      build_buf = buf
      break
    end
  end
  if build_buf then
    -- locate the window that shows it (could be hidden)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == build_buf then
        build_win = win
        break
      end
    end
  end

  ---------------------------------------------------------------------------
  -- 2. stop old job and wipe old buffer + window ---------------------------
  ---------------------------------------------------------------------------
  if build_buf then
    local job = vim.b[build_buf].terminal_job_id
    if job then vim.fn.jobstop(job) end
    if build_win then vim.api.nvim_win_close(build_win, true) end
    vim.api.nvim_buf_delete(build_buf, { force = true })
  end

  ---------------------------------------------------------------------------
  -- 3. create a fresh bottom split and run ./build.sh ----------------------
  ---------------------------------------------------------------------------
  vim.cmd("botright split | resize 10 | enew")
  build_buf = vim.api.nvim_get_current_buf()
  vim.b.build_runner = true                           -- <── tag it

  local chan = vim.fn.termopen(term_cmd, { cwd = vim.fn.getcwd() })
  vim.b[build_buf].terminal_job_id = chan
  vim.cmd("startinsert | stopinsert")

  ---------------------------------------------------------------------------
  -- 4. return focus to the editing window (skip NvimTree) ------------------
  ---------------------------------------------------------------------------
  if vim.api.nvim_win_is_valid(orig_win) then
    local ft = vim.bo[vim.api.nvim_win_get_buf(orig_win)].filetype
    if ft ~= "NvimTree" then
      vim.api.nvim_set_current_win(orig_win)
    end
  end
end,
{ desc = "Run ./build.sh (single reusable pane)", noremap = true, silent = true })

