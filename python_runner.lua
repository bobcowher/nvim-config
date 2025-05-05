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

  -- Check for existing terminal buffer with this file
  local term_buf_name = "TermRun:" .. filename
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:find(term_buf_name, 1, true) then
        vim.cmd("buffer " .. buf)  -- switch to it
        vim.cmd("startinsert")
        return
      end
    end
  end

-- Open a 15-line bottom split and run Python
vim.cmd("botright split")
vim.cmd("resize 15")
vim.cmd("enew")
vim.api.nvim_buf_set_name(0, term_buf_name)
vim.cmd("terminal " .. python_cmd .. " " .. filename)
vim.cmd("startinsert")
	
end, { desc = "Run Python (reused terminal)", noremap = true, silent = true })

