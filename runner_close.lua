-- Shared close for the runner panes: python_runner.lua (b:term_run)
-- and build.lua (b:build_runner).
local function is_runner(buf)
  return vim.b[buf].term_run == true or vim.b[buf].build_runner == true
end

local function close_runner()
  -- Prefer the runner under the cursor, then any other open runner.
  local order = { vim.api.nvim_get_current_win() }
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= order[1] then table.insert(order, win) end
  end

  for _, win in ipairs(order) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_runner(buf) then
      local job = vim.b[buf].terminal_job_id
      if job then pcall(vim.fn.jobstop, job) end
      pcall(vim.api.nvim_win_close, win, true)
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
      return
    end
  end
end

vim.keymap.set("n", "<C-q>", close_runner,
  { desc = "Close runner pane", noremap = true, silent = true })
vim.keymap.set("t", "<C-q>", function()
  vim.cmd("stopinsert")
  close_runner()
end, { desc = "Close runner pane", noremap = true, silent = true })
