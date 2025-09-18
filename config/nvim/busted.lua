-- Busted configuration file
-- This file configures the Busted test runner

return {
  -- Test output format
  output = 'TAP',

  -- Verbose output
  verbose = true,

  -- Test directory
  tests = 'spec/',

  -- Lua path for module loading
  lua_path = 'lua/?.lua;lua/?/init.lua;?.lua;?/init.lua;;',

  -- Coverage settings (if using luacov)
  coverage = false,

  -- Randomize test order
  shuffle = false,

  -- Stop on first failure
  stop_on_failure = false,

  -- Timeout for tests (in seconds)
  timeout = 30,

  -- Initial file to load before running tests
  load_file = 'spec/tools/spec_helper.lua',
}
