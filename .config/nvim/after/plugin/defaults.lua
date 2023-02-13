-- Configure File Search
-- remove the /usr/include folder from the search
-- and add all subdirectories in the current folder to the search
-- https://alpha2phi.medium.com/neovim-for-beginners-fuzzy-file-search-part-1-9df21c0e2c84
vim.opt.path:remove "/usr/include"
vim.opt.path:append "**"

-- perform a case-insensitive search like `:find PACKAGE.JSON`
-- https://alpha2phi.medium.com/neovim-for-beginners-fuzzy-file-search-part-1-9df21c0e2c84
vim.opt.wildignorecase = true
-- vim.cmd [[set path=.,,,$PWD/**]] -- Alternatively set the path
