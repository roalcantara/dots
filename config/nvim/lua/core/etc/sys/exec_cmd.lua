return function(cmd)
  if type(cmd) ~= 'table' then
    cmd = { cmd }
  end
  Neo.debug(("'%s'"):format(vim.inspect(table.concat(cmd, ' '))), { title = 'exec_cmd' })
  local result = vim
    .system(cmd, {
      text = true,
      cwd = vim.fn.getcwd(),
    })
    :wait()
  if result then
    if result.stderr and result.stderr:len() > 0 then
      return error(result.stderr, result.code)
    end
    if result.stdout and result.stdout:len() > 0 then
      return vim.trim(result.stdout)
    end
  end
  return error('Unknown error')
end
