--- Creating user commands
---@param options table<string, UserCommand> The user commands to create
---@return nil
---@see https://neovim.io/doc/user/lua-guide.html#lua-guide-commands-create
local function create_user_commands(options)
  local created = 1
  --- @async
  local init_co = coroutine.create(function()
    for command_name, command in pairs(options) do
      vim.api.nvim_create_user_command(command_name, command.command, command.opts)
      Neo.debug(('[%s] created (%d) ✔'):format(command_name, created), { title = 'UserCommands' })
      created = created + 1
    end
    coroutine.yield()
  end)

  local function resume_loading()
    if coroutine.status(init_co) ~= 'dead' then
      coroutine.resume(init_co)
      vim.defer_fn(resume_loading, 50)
    end
  end

  resume_loading()
end

--- @class UserCommandOptions
--- @field desc? string The description of the command
--- @field force? boolean Whether to force the command
--- @field nargs? string The number of arguments the command takes
--- @field range? number The range of the command
--- @field complete? function The function to call when the command is completed
--- @field bang? boolean Whether to use the bang flag
--- @field register? boolean Whether to register the command

--- @class UserCommand
--- @field command string|function The function to call when the command is executed
--- @field opts UserCommandOptions The options for the command

--- User commands are automatically loaded on the VeryLazy event
--- @param values table<string, UserCommand> The user commands to create
--- @return nil
--- @see https://neovim.io/doc/user/lua-guide.html#lua-guide-commands-create
local function setup_com_async(values)
  return create_user_commands(values)
end

return setup_com_async
