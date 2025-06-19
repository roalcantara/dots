# VSCode-like Autocompletion for Neovim (NATIVE ONLY)

This implementation provides VSCode-like autocompletion behavior in Neovim using **ONLY** the native Neovim 0.11+ LSP completion system. No external completion plugins (nvim-cmp, blink.cmp) are required or used.

## Key Benefits

✅ **Zero Dependencies**: Uses only built-in Neovim 0.11+ features
✅ **Lightweight**: No external completion engines
✅ **Native Performance**: Leverages Neovim's optimized completion system
✅ **Future-Proof**: Built on Neovim's official completion API

## Features Implemented

### ✅ Scenario: Dot triggers autocompletion

- **Given**: Editing a source file in INSERT MODE with a variable `scope` that has available methods/attributes
- **When**: Type `.` after the variable name (e.g., `scope.`)
- **Then**: All available completions are displayed for selection

### ✅ Scenario: Tab accepts selected completion

- **Given**: Autocompletion suggestions are displayed
- **When**: Press `<TAB>`
- **Then**: The selected suggestion is accepted and cursor is positioned after the completed text

### ✅ Scenario: Dot accepts completion and continues

- **Given**: Autocompletion suggestions are displayed and a suggestion is selected
- **When**: Press `.`
- **Then**:
  1. The selected suggestion is accepted
  2. Cursor is positioned after the completed text
  3. New completions are triggered for the accepted item

### ✅ Scenario: Escape dismisses autocompletion

- **Given**: Autocompletion suggestions are displayed
- **When**: Press `<ESC>`
- **Then**:
  1. The suggestion list is closed
  2. No suggestion is accepted
  3. Cursor remains at original position

## Technical Implementation

### Completion Engine

- **nvim-cmp**: Modern completion engine with extensive customization
- **nvim-lsp**: LSP completion source for intelligent code completion
- **LuaSnip**: Snippet engine for code templates
- **Multiple sources**: Buffer, path, and command-line completion

### Key Mappings

| Key           | Mode   | Action                                        |
| ------------- | ------ | --------------------------------------------- |
| `<Tab>`       | Insert | Accept selected completion                    |
| `.`           | Insert | Accept completion and trigger new completions |
| `<Esc>`       | Insert | Dismiss completion menu                       |
| `<C-Space>`   | Insert | Manually trigger completion                   |
| `<Up>/<Down>` | Insert | Navigate completion items                     |
| `<C-u>/<C-d>` | Insert | Scroll documentation                          |

### Trigger Characters

The following characters automatically trigger completion:

- `.` (dot notation for object properties/methods)
- `:` (namespace/module access)
- `->` (pointer dereferencing in languages like C/C++)
- `::` (scope resolution)
- `#` (preprocessor directives)
- `@` (decorators/annotations)

## Configuration Files

### `/lua/plugins/completions.lua`

Contains the main nvim-cmp configuration with:

- VSCode-like completion behavior
- Custom key mappings for all scenarios
- Source prioritization (LSP > Snippets > Buffer > Path)
- Visual appearance matching VSCode
- Ghost text support

### `/lua/config/keymaps.lua`

Additional keymaps that integrate with the completion system:

- Completion navigation shortcuts
- Documentation scrolling
- Manual completion triggers

### `/lua/core/lsp/helper.lua`

Enhanced LSP integration:

- Automatic completion enabling on LSP attach
- Trigger character configuration
- Context-aware completion triggering

## Testing

Use the provided `autocompletion_test.lua` file to test all scenarios:

1. Open the test file in Neovim
2. Enter INSERT mode
3. Type `test_object.` and observe completions
4. Test Tab, Dot, and Escape behaviors
5. Try other scenarios with `vim.`, `string.`, etc.

## Customization

The configuration is modular and can be customized by:

1. **Modifying trigger characters**: Edit the `trigger_chars` array in the LSP helper
2. **Changing key mappings**: Update the `mapping` table in completions.lua
3. **Adjusting completion sources**: Modify the `sources` configuration
4. **Customizing appearance**: Update the `formatting` and `window` settings

## Dependencies

Ensure these plugins are installed via your plugin manager:

- `hrsh7th/nvim-cmp`
- `hrsh7th/cmp-nvim-lsp`
- `hrsh7th/cmp-buffer`
- `hrsh7th/cmp-path`
- `hrsh7th/cmp-cmdline`
- `L3MON4D3/LuaSnip`
- `saadparwaiz1/cmp_luasnip`

## Integration with LazyVim

This configuration is designed to work seamlessly with LazyVim while providing the exact VSCode-like autocompletion experience specified in the requirements.
