local function open_floating_terminal(opts)
  opts = opts or {}

  -- Calculate floating window size (80% by default)
  local win_width = opts.width or math.ceil(vim.o.columns * 0.8)
  local win_height = opts.height or math.ceil(vim.o.lines * 0.8)

  -- Calculate starting position to center the window
  local row = math.ceil((vim.o.columns - win_height) / 2)
  local col = math.ceil((vim.o.lines - win_width) / 2)

  -- Create a buffer for the terminal
  local buf = nil
  if opts.buf and vim.api.nvim_buf_Is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  -- Define window configuration
  local win_config = {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  }

  -- Create the floating window
  local win = vim.api.nvim_open_win(buf, true, win_config)

  -- Optional: Set up keymaps for the terminal window
  -- local opts_keymap = { buffer = buf }
  -- vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts_keymap)
  -- vim.keymap.set("n", "q", "<cmd>close<cr>", opts_keymap)

  return { buf = buf, win = win }
end

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

local function toggle_floating_terminal()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = open_floating_terminal({ buf = state.floating.buf })
    print(vim.inspect(state))

    if vim.bo[state.floating.buf].filetype ~= "terminal" then
      vim.cmd.terminal()
    end
  else
    -- If the floating terminal is already open, close it
    vim.api.nvim_win_hide(state.floating.win)
    state.floating = { buf = -1, win = -1 }
  end
end

-- Example usage:
-- Default size (80% of screen)
-- open_floating_terminal()

-- Custom size
-- open_floating_terminal({ width = 100, height = 30 })

vim.api.nvim_create_user_command("ToggleTerm", toggle_floating_terminal, {
  nargs = "*",
  desc = "Toggle floating terminal",
})

-- Optional: Create a keymap
-- vim.keymap.set("n", '<D-t>', toggle_floating_terminal, { desc = "Toggle floating terminal" })

-- return {
--  toggle_floating_terminal = toggle_floating_terminal,
-- }

return open_floating_terminal
