--- Search and pick for Neovim filetypes
return function()
  local get_filetypes = require('core/vi/buffers').get_filetypes

  Snacks.picker.select(get_filetypes(), {
    prompt = 'Select a filetype',
  }, function(choice)
    if choice then
      vim.bo.filetype = choice
      Snacks.notify.info('Filetype set to ' .. choice)
    end
  end)
end
