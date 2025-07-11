# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Features

### LSP Hover Filter

The configuration includes a smart hover filter that automatically shows LSP hover documentation only for meaningful code elements, excluding simple strings, brackets, punctuation, and other basic elements.

#### How it works

The hover filter uses treesitter to analyze the syntax tree and determine whether to show hover documentation based on the element type under the cursor. This prevents unnecessary hover popups for basic syntax elements.

#### Default exclusions

The filter excludes the following element types:

- String literals (`string`, `string_literal`, `string_content`)
- Brackets and punctuation (`(`, `)`, `[`, `]`, `{`, `}`, `<`, `>`)
- Basic punctuation (`,`, `;`, `:`, `.`, `!`, `?`)
- Operators (`+`, `-`, `*`, `/`, `=`, `==`, `!=`, etc.)
- Comments (`comment`, `line_comment`, `block_comment`)
- Whitespace (`whitespace`, `indent`, `dedent`)
- Basic literals (`number`, `number_literal`)

#### Customization

You can customize the hover filter by modifying `lua/core/vi/ui/lsp/hover_filter.lua`:

```lua
-- Add more excluded types
local hover_filter = require("core/vi/ui/lsp/hover_filter")
table.insert(hover_filter.excluded_node_types, "new_type_to_exclude")

-- Add filetype-specific exclusions
hover_filter.filetype_exclusions.lua = { "local", "end", "then" }
hover_filter.filetype_exclusions.javascript = { "const", "let", "var" }
```

#### Enhanced Hover Support

The LSP hover system now supports enhanced hover with a configurable delay. This allows you to see documentation after a brief delay when the cursor moves (via mouse or keyboard), while still maintaining the existing cursor hold functionality.

##### Configuration

- **Default delay**: 500ms
- **Configurable via**: `vim.g.lsp_hover_mouse_delay` (in milliseconds)
- **Command**: `:LspHoverMouseDelay <milliseconds>` to change the delay

##### Usage

1. **Cursor movement**: Move your cursor (via mouse or keyboard) over a code element and wait for the configured delay
2. **Cursor hold**: Continue using cursor hold (when cursor remains stationary)
3. **Adjust delay**: Use `:LspHoverMouseDelay 250` for faster response or `:LspHoverMouseDelay 1000` for slower response

##### Commands

- `:LspHoverMouseDelay` - Show current delay setting
- `:LspHoverMouseDelay <ms>` - Set new delay (e.g., `:LspHoverMouseDelay 300`)
- `:DebugHoverFilter` - Debug hover filter for current cursor position

#### Debugging

Use the `:DebugHoverFilter` command to see information about the current node under the cursor, including:

- Node type
- Node text
- Whether hover would be shown

This is useful for understanding what element types are being filtered and for fine-tuning the exclusions.

### Toggle Options Picker

A powerful picker that allows you to view and toggle Neovim options with both buffer and global scopes.

#### Toggle Options Usage

- **Command**: `:ToggleOptions`
- **Keymap**: `<D-M-u>` (Cmd+Alt+U)

#### Main Features

- Shows a list of commonly used Neovim options
- Displays both buffer and global values for each option
- Provides option documentation in the preview
- Allows toggling options through an interactive menu
- Supports both boolean and numeric options

#### Supported Options

The picker includes these commonly used options:

- `wrap` - Wrap long lines
- `linebreak` - Wrap at breakable characters
- `spell` - Enable spell checking
- `relativenumber` - Show relative line numbers
- `number` - Show line numbers
- `cursorline` - Highlight current line
- `cursorcolumn` - Highlight current column
- `list` - Show whitespace characters
- `ignorecase` - Ignore case in search
- `smartcase` - Smart case matching
- `hlsearch` - Highlight search results
- `incsearch` - Incremental search highlighting
- `autoindent` - Auto-indent new lines
- `expandtab` - Use spaces instead of tabs
- `scrollbind` - Synchronize scrolling
- `cursorbind` - Synchronize cursor movement
- `diff` - Show differences
- `foldenable` - Enable folding
- `conceallevel` - Text concealment level
- `signcolumn` - Sign column display

#### How to Use

1. Open the picker with `:ToggleOptions` or `<D-M-u>`
2. Navigate through the options using arrow keys
3. Press Enter on an option to see its documentation and toggle options
4. Choose from the action menu:
   - `b`: Toggle buffer option
   - `g`: Toggle global option
   - `r`: Refresh the list (reopen picker to see changes)

#### Example

```markdown
| Item           | Buffer | Global |
| -------------- | ------ | ------ |
| wrap           | on     | on     |
| linebreak      | on     | on     |
| spell          | off    | off    |
| relativenumber | on     | on     |
```

When you select `spell` and choose to toggle the buffer option, it will change to:

```markdown
| Item           | Buffer | Global |
| -------------- | ------ | ------ |
| wrap           | on     | on     |
| linebreak      | on     | on     |
| spell          | on     | off    |
| relativenumber | on     | on     |
```

## File Structure Guide Lines

This Neovim configuration follows a structured approach inspired by both Neovim best practices and the Linux Filesystem Hierarchy Standard (FHS) for logical organization.

### Directory Structure

```tree
~/.config/nvim/
.
├── init.lua                            # Entry point - bootstraps the configuration
├── lsp                                 # LSP configurations
│   ├── jsonls.lua
│   ├── lua_ls.lua
│   ├── vtsls.lua
│   └── yamlls.lua
├── lua                                 # Main Lua configuration directory
│   ├── config                          # Core configuration
│   │   ├── lazy.lua                    # Lazy.nvim setup (bootstrap!)
│   │   ├── autocmds.lua                # Auto-commands
│   │   ├── commands.lua                # Custom user commands
│   │   ├── keymaps.lua                 # Key mappings
│   │   └── options.lua                 # Neovim options
│   ├── core                            # Core utilities
│   │   ├── init.lua
│   │   ├── etc                         # Miscellaneous utilities
│   │   │   ├── init.lua
│   │   │   ├── fn                      # Function utilities
│   │   │   │   ├── init.lua
│   │   │   │   └── safe_require.lua
│   │   │   └── sys                     # System utilities
│   │   │       ├── init.lua
│   │   │       └── os.lua
│   │   ├── opt                         # Options utilities
│   │   │   ├── init.lua
│   │   │   └── homebrew.lua
│   │   └── vi                          # Vi-specific utilities
│   │       ├── init.lua
│   │       ├── fn                      # Vi-specific functions
│   │       │   ├── init.lua
│   │       │   ├── if_loaded.lua
│   │       │   ├── is_tty.lua
│   │       │   ├── paths.lua
│   │       │   └── ver.lua
│   │       ├── lib                     # Vi-specific libraries
│   │       │   ├── init.lua
│   │       │   ├── keymap.lua
│   │       │   └── u_command.lua
│   │       └── ui                      # Vi-specific UI helpers
│   │           ├── init.lua
│   │           ├── snacks_scratch.lua
│   │           ├── snacks.lua
│   │           └── term.lua
│   └── plugins                         # Plugin configurations
│       ├── coding.lua
│       ├── lsp.lua
│       └── ui.lua
├── tests/                              # Unit tests directory
│   ├── init.lua                        # Test initialization
│   └── test_to_tb.lua                  # Tests for M.to_tb function
├── Dockerfile.test                     # Docker image for testing
├── docker-compose.test.yml             # Docker Compose for tests
├── stylua.toml                         # Formatting configuration
├── LICENSE                             # License information
└── README.md                           # Project documentation
```

### Design Principles

1. Neovim Best Practices

   - Clear separation of concerns
   - Modular plugin organization
   - Consistent naming conventions
   - Easy to navigate and understand

2. Scalability

   - Easy to add new plugins in appropriate categories
   - Clear import paths
   - Minimal coupling between modules

### Usage Patterns

1. Importing Libraries

    ```lua
    -- Import all utilities
    local fn = require("core/vi/fn")
    local version = fn.ver.get_nvim_version()

    -- Import specific utility modules
    local paths = require("core/vi/fn/paths")
    local config_path = paths.get_stdpaths().config
    ```

2. File Naming Conventions

    - Use `snake_case` for file names
    - Use descriptive names that indicate purpose
    - Group related functionality in subdirectories
    - Use `init.lua` for directory entry points

## Testing

This project includes comprehensive unit tests using [Busted](https://github.com/Olivine-Labs/busted), a popular testing framework for Lua. Tests are designed to run in a Docker container to ensure consistent environments.

### Test Structure

- `tests/init.lua` - Test initialization and mock setup
- `tests/test_to_tb.lua` - Unit tests for the `M.to_tb` function
- `Dockerfile.test` - Docker image with LuaJIT and Busted
- `docker-compose.test.yml` - Docker Compose configuration for tests

### Running Tests

#### Using Mise (Recommended)

The project uses [Mise](https://mise.jdx.dev/) for task management. Available test commands:

```bash
# Run all tests
mise run test

# Build test image only
mise run test-build

# Run tests with existing image
mise run test-run

# Run tests with force rebuild
mise run test-watch
```

#### Using Docker Directly

```bash
# Build the test image
docker build -f tools/Dockerfile -t nvim-tests .

# Run tests
docker run --rm -v $(pwd)/specs:/app/specs -v $(pwd)/lua:/app/lua nvim-tests

# Using Docker Compose
docker compose -f tools/docker-compose.test.yml up --build --abort-on-container-exit --remove-orphans
```

#### Using Busted Locally (if installed)

```bash
# Install Busted locally
luarocks install busted

# Run tests
busted --verbose specs/
```

### Test Coverage

The current test suite covers the `M.to_tb` function with comprehensive test cases:

- **Basic functionality** - Core behavior verification
- **Mode handling** - Single, multiple, and empty mode arrays
- **Function handling** - Various function return types and behaviors
- **Edge cases** - Nil inputs and error conditions
- **Integration** - Interaction with `M.cmd` function
- **Documentation verification** - Ensures examples work as documented

### Example Test Case

The `M.to_tb` function is tested based on its documented example:

```lua
-- Function: M.to_tb(fn, modes)
-- Example: fn=pick.lsp.symbols, modes={n,i} => { n = M.cmd(pick.lsp.symbols), i = M.cmd(pick.lsp.symbols) }

local result = M.to_tb(pick_lsp_symbols, {"n", "i"})
-- Result: { n = function() return "pick.lsp.symbols" end, i = function() return "pick.lsp.symbols" end }
```

### Adding New Tests

To add tests for new functions:

1. Create a new test file in `tests/` directory
2. Follow the existing test structure and naming conventions
3. Use the provided mocks for `vim` and `Snacks` globals
4. Run tests to ensure they pass

### SUMMARY

This structure provides a solid foundation for a maintainable and scalable Neovim configuration with comprehensive testing capabilities.
