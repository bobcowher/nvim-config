-- Find the runner window/buffer, if one is open.
local function find_runner()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].term_run == true then
      return win, buf
    end
  end
  return nil, nil
end


vim.keymap.set("n", "<C-d>", function()
  local filename = vim.fn.expand("%:p")  -- full file path
  if filename == "" then return end

  -- Save the file if allowed
  if vim.bo.buftype == "" and vim.bo.modifiable then
    vim.cmd("w")
  end

  -- Build Python command
  local python_cmd = "python3"
  if vim.g.project_python_path then
    python_cmd = vim.g.project_python_path
  elseif vim.env.CONDA_PREFIX then
    python_cmd = vim.env.CONDA_PREFIX .. "/bin/python"
  end

  -- Reuse the existing runner window if one is open; otherwise open a split.
  local win, old_buf = find_runner()
  if win then
    vim.api.nvim_set_current_win(win)
    vim.cmd("enew")
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  else
    vim.cmd("botright split")
    vim.cmd("resize 15")
    vim.cmd("enew")
  end

  vim.cmd("terminal " .. python_cmd .. " " .. filename)
  vim.b.term_run = true
  vim.cmd("startinsert")
end, { desc = "Run Python (reused runner window)", noremap = true, silent = true })
