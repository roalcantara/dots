-- uvx --from mlx-lm==0.32.2 mlx_lm.generate --model <dir> --temp 0 --verbose False
-- --chat-template-config '{"enable_thinking": false}' --system-prompt "..." --prompt "..."
--
-- Runs the model in a short-lived process: nothing stays resident between requests,
-- at the cost of loading the weights (~1-3s) on every call.

local exec_cmd = require('core/etc/sys/exec_cmd')
local handle_provider = require('core/opt/llm/commons/handle_provider')

local models_dir = vim.fn.expand('~/.omlx/models')

local M = {
  config = {
    runner = { 'uvx', '--from', 'mlx-lm==0.32.2', 'mlx_lm.generate' },
    -- Tried in order. `exclude` lists weight files mlx-lm cannot load (oMLX's MTP
    -- speculative-decoding head); such models are loaded through a symlinked copy.
    models = {
      { path = models_dir .. '/Jundot/gemma-4-E2B-it-oQ4e-mtp', exclude = { 'model-mtp.safetensors' } },
      { path = models_dir .. '/mlx-community/Qwen3-4B-Instruct-2507-4bit' },
    },
    max_tokens = 300,
    temperature = 0,
  },
}

--- Resolve the directory to load a model from, building a symlinked copy without
--- the excluded files when needed.
--- @param model table { path = string, exclude = string[]|nil }
--- @return string
local function model_dir(model)
  if vim.fn.isdirectory(model.path) == 0 then
    error('Model not found: ' .. model.path, 0)
  end
  if not model.exclude or #model.exclude == 0 then
    return model.path
  end

  local dir = vim.fs.joinpath(vim.fn.stdpath('cache'), 'mlx-models', vim.fs.basename(model.path))
  vim.fn.mkdir(dir, 'p')
  for _, name in ipairs(vim.fn.readdir(model.path)) do
    local link = vim.fs.joinpath(dir, name)
    if not vim.tbl_contains(model.exclude, name) and not vim.uv.fs_lstat(link) then
      assert(vim.uv.fs_symlink(vim.fs.joinpath(model.path, name), link))
    end
  end
  return dir
end

--- Build mlx_lm.generate argv for a request (no execution).
--- @param model table { path = string, exclude = string[]|nil }
--- @param input string|table User input (string, or table with user/system keys)
--- @return string[]
function M.build_argv(model, input)
  local system, user = handle_provider.split_input(input)
  local argv = vim.list_extend({}, M.config.runner)
  vim.list_extend(argv, {
    '--model',
    model_dir(model),
    '--max-tokens',
    tostring(M.config.max_tokens),
    '--temp',
    tostring(M.config.temperature),
    '--verbose',
    'False',
    -- Gemma 4 / Qwen3.5 templates otherwise reason before answering.
    '--chat-template-config',
    vim.json.encode({ enable_thinking = false }),
  })
  if system and system ~= '' then
    vim.list_extend(argv, { '--system-prompt', system })
  end
  vim.list_extend(argv, { '--prompt', user })
  return argv
end

--- Generate a response with the first local MLX model that loads.
--- @param input string|table User input (string, or table with user/system keys)
--- @return string Response text
function M.messages(input)
  if vim.fn.executable(M.config.runner[1]) == 0 then
    error(M.config.runner[1] .. ' not found', 0)
  end
  local errors = {}
  for _, model in ipairs(M.config.models) do
    local ok, result = pcall(function()
      return exec_cmd(M.build_argv(model, input))
    end)
    if ok and result and result ~= '' then
      return handle_provider.strip_preamble(result)
    end
    table.insert(errors, vim.fs.basename(model.path) .. ': ' .. tostring(result))
  end
  error(table.concat(errors, '; '), 0)
end

return M
