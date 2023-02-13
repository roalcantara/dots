-- https://neovim.io/doc/user/api.html#nvim_create_autocmd()
vim.api.nvim_create_autocmd('FileType', { pattern = 'json', command = [[syntax match Comment +\/\/.\+$+]] })
