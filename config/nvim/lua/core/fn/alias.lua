---Makes an alias that exapands to another word when space is pressed
---@param from string The alias name that will be used
---@param to string The word that will replace the alias when space is pressed
---@example
--- 1. Define an alias: alias('bar', 'DevWindows')
--- 2. [N] Then type `:wq<CR>` to quit and reload Neovim
--- 2. [N] Then type `:` to enter in COMMAND MODE
--- 2. [C] When type `bar` and press <SPC>
--- 3. [C] Then `bar` will be replaced with `DevWindows`
local function alias(from, to)
  vim.cmd(string.format('cabbrev %s %s', from, to))
end

return alias
