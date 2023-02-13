system = {
  uname: vim.loop.os_uname!
  name: vim.loop.os_uname!.sysname
  isDarwin: vim.loop.os_uname!.sysname == 'Darwin'
}

return system
