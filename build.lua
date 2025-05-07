vim.keymap.set("n", "<C-B>", function()
  local term_name = "Task: build"
  local term_cmd = "./build.sh"

  -- Kill and delete old buffer if it exists
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match(term_name) then
      local chan_id = vim.b[buf].terminal_job_id
      if chan_id then
        vim.fn.jobstop(chan_id)
      end
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  -- Create a new terminal buffer
  vim.cmd("botright split")
  vim.cmd("resize 15")
  vim.cmd("enew")
  vim.api.nvim_buf_set_name(0, term_name)
  vim.cmd("terminal " .. term_cmd)
  vim.cmd("startinsert")
end, { desc = "Run build.sh", noremap = true, silent = true })

