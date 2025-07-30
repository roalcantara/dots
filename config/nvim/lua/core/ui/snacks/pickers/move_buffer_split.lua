local function get_move_buffer_split_items()
  return {
    {
      id = 'split_down',
      icon = '',
      text = 'Split current buffer to bottom',
      cmd = '<C-w>J',
      value = 'leftabove split | bprev | wincmd j',
    },
    {
      id = 'split_up',
      icon = '',
      text = 'Split current buffer to top',
      cmd = '<C-w>K',
      value = 'rightbelow split | bprev | wincmd k',
    },
    {
      id = 'split_right',
      icon = '',
      text = 'Split current buffer to right',
      cmd = '<C-w>L',
      value = 'leftabove vsplit | bprev | wincmd l',
    },
    {
      id = 'split_left',
      icon = '',
      text = 'Split current buffer to left',
      cmd = '<C-w>H',
      value = 'rightbelow vsplit | bprev | wincmd h',
    },
    {
      id = 'swap_splits_horizontally',
      icon = '-',
      text = 'Swap Splits Horizontally',
      cmd = '<C-w>t<C-w>H',
      value = '<C-w>t<C-w>H',
    },
    {
      id = 'swap_splits_vertically',
      icon = '|',
      text = 'Swap Splits Vertically',
      cmd = '<C-w>t<C-w>L',
      value = '<C-w>t<C-w>L',
    },
    {
      id = 'rotate_window_rightwards',
      icon = '>',
      text = 'Rotate Windows Downwards/Rightwards',
      cmd = '<C-w>r',
      value = '<C-w>r',
    },
    {
      id = 'rotate_window_leftward',
      icon = '<',
      text = 'Rotate Windows Upwards/Leftward',
      cmd = '<C-w>R',
      value = '<C-w>R',
    },
    {
      id = 'focus_next_split',
      icon = '>',
      text = 'Focus Next Split',
      cmd = '<C-w>w',
      value = '<C-w>w',
    },
    {
      id = 'focus_previous_split',
      icon = '<',
      text = 'Focus Previous Split',
      cmd = '<C-w>W',
      value = '<C-w>W',
    },
    {
      id = 'equalize_splits',
      icon = '',
      text = 'Equalize Splits',
      cmd = '<C-w>=',
      value = '<C-w>=',
    },
  }
end

--- List the items on Neovim runtimepath
--- @return table Table with runtimepath items
--- @see https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
local function move_buffer_split()
  return Snacks.picker({
    title = 'Move Buffer Split',
    items = get_move_buffer_split_items(),
    layout = 'select',
    enter = true,
    focus = 'list',
    format = function(item)
      local a = Snacks.picker.util.align
      local ret = {}
      ret[#ret + 1] = { a(item.icon, 2), 'SnacksPickerIcon' }
      ret[#ret + 1] = { ' ' }
      ret[#ret + 1] = { a(item.text, 20), 'SnacksPickerIconSource' }
      ret[#ret + 1] = { ' ' }
      ret[#ret + 1] = { '[', 'SnacksPickerDelim' }
      ret[#ret + 1] = { a(item.cmd, 5), 'SnacksPickerIconName' }
      ret[#ret + 1] = { ']', 'SnacksPickerDelim' }
      ret[#ret + 1] = { ' ' }
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      Snacks.notify.info('Moving buffer split: ' .. item.text .. ' (' .. item.cmd .. '/' .. item.value .. ')')
      if item then
        vim.schedule(function()
          if vim.fn.mode() == 'i' then
            vim.cmd('<C-o>' .. item.cmd)
          else
            vim.cmd(item.value)
          end
        end)
      end
    end,
  })
end

return move_buffer_split
