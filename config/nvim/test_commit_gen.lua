-- Minimal script to test commit message generation (run from repo root).
-- Usage: nvim -u NONE --headless --cmd "set rtp^=$PWD/config/nvim" -c "luafile config/nvim/test_commit_gen.lua" -c "qa"

_G.Neo = {
  debug = function() end,
  info = function() end,
  warn = function() end,
  error = function() end,
}

local ok, r = pcall(function()
  return require('core.ui.git.commits').generate_conventional_commit_message()
end)

if ok and r and r.response then
  print('PROVIDER:', r.provider)
  print('MESSAGE:')
  print(r.response)
else
  print('OK:', ok)
  print('RESULT:', vim.inspect(r))
end
