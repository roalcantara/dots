local build
build = function(_, _, _)
  return vim.cmd([[autocmd CursorHold * lua vim.diagnostic.open_float(0, {scope="line"})]])
end
return build
