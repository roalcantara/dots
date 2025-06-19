-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- VSCode-like keymaps following the exact schema from workflows/next.yml
-- ONLY implementing shortcuts that are highlighted in the schema
-- Non-highlighted shortcuts are commented out for future analysis
-- local h = require('core/map/helper').helpers
-- local map = require('core/map/helper').map
-- local cmd_and_map = require('core/map/helper').cmd_and_map

-- -- User Commands
-- require('config/commands')

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<leader>e', ':Ex<cr>', { desc = 'Open [E]xplorer' })

-- -- =============================================================================
-- -- LSP
-- -- =============================================================================

-- -- ⌘ . : Selects a code action available at cursor position
-- cmd_and_map('QuickFix', function() vim.lsp.buf.code_action() end, 'n', '<D-.>', '[⌘ .] Quick Fix')

-- -- ⌘ ⌥ ␣ : Displays signature information about the symbol under the cursor
-- cmd_and_map('TriggerParameterHints', function() vim.lsp.buf.signature_help() end, 'n', '<D-M-Space>',
--   '[⌘ ⌥ ␣] Parameter Hints')

-- -- ⌘ ⌥ ↵ : Renames all references to the symbol under the cursor
-- cmd_and_map('Rename', function() vim.lsp.buf.rename() end, 'n', '<D-M-CR>', '[⌘ ⌥ ↵] Rename Symbol')

-- -- ⌘ ⌥ d : Jumps to the declaration of the symbol under the cursor
-- cmd_and_map('GoToDeclaration', function() vim.lsp.buf.declaration() end, 'n', '<D-M-d>', '[⌘ ⌥ d] Go to Declaration')

-- -- ⌘ ⌥ f : Formats a buffer using the attached language server clients
-- cmd_and_map('FormatDocument', function() vim.lsp.buf.format() end, 'n', '<D-M-f>', '[⌘ ⌥ f] Format Document')

-- -- ⌘ ⌥ i : Jumps to the definition of the symbol under the cursor
-- cmd_and_map('GoToImplementation', function() vim.lsp.buf.implementation() end, 'n', '<D-M-i>',
--   '[⌘ ⌥ i] Go to Implementation')

-- -- ⌘ ⌥ ⇧ i : Lists all the implementations for the symbol under the cursor
-- cmd_and_map('FindImplementations', function() require('telescope.builtin').lsp_implementations() end, 'n', '<D-M-S-i>',
--   '[⌘ ⌥ ⇧ i] Find Implementations')

-- -- ⌘ ⌥ k : Displays hover information about the symbol under the cursor
-- cmd_and_map('ShowHover', function() vim.lsp.buf.hover() end, 'n', '<D-M-k>', '[⌘ ⌥ k] Show Hover')

-- -- ⌘ ⌥ r : Lists all the references to the symbol under the cursor
-- cmd_and_map('FindReferences', function() require('telescope.builtin').lsp_references() end, 'n', '<D-M-r>',
--   '[⌘ ⌥ r] Find References')

-- -- ⌘ ⌥ s : Lists all symbols in the current buffer
-- cmd_and_map('DocumentSymbols', function() require('telescope.builtin').lsp_document_symbols() end, 'n', '<D-M-s>',
--   '[⌘ ⌥ s] Document Symbols')

-- -- ⌘ ⌥ ⇧ s : Lists all symbols in the current workspace
-- cmd_and_map('WorkspaceSymbols', function() require('telescope.builtin').lsp_workspace_symbols() end, 'n', '<D-M-S-s>',
--   '[⌘ ⌥ ⇧ s] Workspace Symbols')

-- -- =============================================================================
-- -- NAVIGATION
-- -- =============================================================================

-- -- ⌘ t : Toggle Terminal
-- cmd_and_map('ToggleTerminal', function() vim.cmd('ToggleTerm') end, 'n', '<D-t>', '[⌘ t] Toggle Terminal')

-- -- =============================================================================
-- -- AI SHORTCUTS (from schema)
-- -- =============================================================================

-- -- ⌥ i : Copilot | Inline Chat
-- -- cmd_and_map('CopilotInlineChat', function() vim.cmd('CopilotChat') end, 'n', '<M-i>', '[⌥ i] Copilot Inline Chat')

-- -- =============================================================================
-- -- EDITING SHORTCUTS (from schema)
-- -- =============================================================================

-- -- ⌥ ↓ : Move Line Down
-- map('n', '<M-Down>', "<cmd>execute 'move .+' . v:count1<cr>==", '[⌥ ↓] Move Line Down')
-- vim.keymap.set('i', '<M-Down>', '<esc><cmd>m .+1<cr>==gi', '[⌥ ↓] Move Line Down')
-- map('v', '<M-Down>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", '[⌥ ↓] Move Lines Down')

-- -- ⌥ ↑ : Move Line Up
-- map('n', '<M-Up>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", '[⌥ ↑] Move Line Up')
-- vim.keymap.set('i', '<M-Up>', '<esc><cmd>m .-2<cr>==gi', '[⌥ ↑] Move Line Up')
-- map('v', '<M-Up>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", '[⌥ ↑] Move Lines Up')

-- -- ⌃ a : Move to beginning of line
-- map('n', '<C-a>', '0', '[⌃ a] Move to BOL')
-- vim.keymap.set('i', '<C-a>', '<C-o>0', '[⌃ a] Move to BOL')

-- -- ⌃ e : Move to end of line
-- map('n', '<C-e>', '$', '[⌃ e] Move to EOL')
-- vim.keymap.set('i', '<C-e>', '<C-o>$', '[⌃ e] Move to EOL')

-- -- ⌃ f : Format Document
-- cmd_and_map('FormatDocumentCtrl', function() vim.lsp.buf.format() end, 'n', '<C-f>', '[⌃ f] Format Document')

-- -- ⌃ g : Go to line
-- cmd_and_map('GoToLine',
--   function() vim.ui.input({ prompt = 'Go to line: ' }, function(input) if input then vim.cmd(input) end end) end, 'n',
--   '<C-g>', '[⌃ g] Go to Line')

-- -- ⌘ ↑ : Go to the top of the file
-- map('n', '<D-Up>', 'gg', '[⌘ ↑] Go to Top of File')
-- vim.keymap.set('i', '<D-Up>', '<C-o>gg', '[⌘ ↑] Go to Top of File')

-- -- ⌘ ↓ : Go to the bottom of the file
-- map('n', '<D-Down>', 'G', '[⌘ ↓] Go to Bottom of File')
-- vim.keymap.set('i', '<D-Down>', '<C-o>G', '[⌘ ↓] Go to Bottom of File')

-- -- ⌘ ← : Move to BOL
-- map('n', '<D-Left>', '0', '[⌘ ←] Move to BOL')
-- vim.keymap.set('i', '<D-Left>', '<C-o>0', '[⌘ ←] Move to BOL')

-- -- ⌘ → : Move to EOL
-- map('n', '<D-Right>', '$', '[⌘ →] Move to EOL')
-- vim.keymap.set('i', '<D-Right>', '<C-o>$', '[⌘ →] Move to EOL')

-- -- ⌘ \ : Toggle left side bar
-- cmd_and_map('ToggleSidebar', function() vim.cmd('Neotree toggle') end, 'n', '<D-\\>', '[⌘ \\] Toggle Sidebar')

-- -- ⌘ / : Toggle comment line
-- map('n', '<D-/>', '<Plug>(comment_toggle_linewise_current)', '[⌘ /] Toggle Comment')
-- map('v', '<D-/>', '<Plug>(comment_toggle_linewise_visual)', '[⌘ /] Toggle Comment')

-- -- ⌘ [ : Fold
-- map('n', '<D-[>', 'zc', '[⌘ [] Fold')

-- -- ⌘ ] : Unfold
-- map('n', '<D-]>', 'zo', '[⌘ ]] Unfold')

-- -- ⌘ a : Select all
-- cmd_and_map('SelectAll', h.edit.select_all, 'n', '<D-a>', '[⌘ a] Select All')

-- -- ⌘ c : Copy selection to clipboard
-- cmd_and_map('Copy', h.edit.copy, 'n', '<D-c>', '[⌘ c] Copy')

-- -- ⌘ d : Toggle Problems
-- cmd_and_map('ToggleProblems', function() require('trouble').toggle('diagnostics') end, 'n', '<D-d>',
--   '[⌘ d] Toggle Problems')

-- -- ⌘ f : Find in files
-- cmd_and_map('FindInFile', h.pick.find, 'n', '<D-f>', '[⌘ f] Find in File')

-- -- ⌘ i : Go to Definition
-- cmd_and_map('GoToDefinition', function() vim.lsp.buf.definition() end, 'n', '<D-i>', '[⌘ i] Go to Definition')

-- -- ⌘ n : New File
-- cmd_and_map('NewFile', h.edit.new, 'n', '<D-n>', '[⌘ n] New File')

-- -- ⌘ p : Search files by name
-- cmd_and_map('SearchFiles', h.pick.files, 'n', '<D-p>', '[⌘ p] Search Files')

-- -- ⌘ v : Paste
-- cmd_and_map('Paste', h.edit.paste, 'n', '<D-v>', '[⌘ v] Paste')

-- -- ⌘ w : Close Editor
-- cmd_and_map('CloseEditor', h.buf.close, 'n', '<D-w>', '[⌘ w] Close Editor')

-- -- ⌘ x : Cut selection to clipboard
-- cmd_and_map('Cut', h.edit.cut, 'n', '<D-x>', '[⌘ x] Cut')

-- -- ⌘ y : Redo
-- cmd_and_map('Redo', h.edit.redo, 'n', '<D-y>', '[⌘ y] Redo')

-- -- ⌘ z : Undo
-- cmd_and_map('Undo', h.edit.undo, 'n', '<D-z>', '[⌘ z] Undo')

-- -- ⌘ ⌥ ← : Go to tab at left
-- cmd_and_map('PrevTab', h.go_to.buf.prev, 'n', '<D-M-Left>', '[⌘ ⌥ ←] Previous Tab')

-- -- ⌘ ⌥ → : Go to tab at right
-- cmd_and_map('NextTab', h.go_to.buf.next, 'n', '<D-M-Right>', '[⌘ ⌥ →] Next Tab')

-- -- ⌘ ⌥ [ : Fold All
-- map('n', '<D-M-[>', 'zM', '[⌘ ⌥ [] Fold All')

-- -- ⌘ ⌥ ] : Unfold All
-- map('n', '<D-M-]>', 'zR', '[⌘ ⌥ ]] Unfold All')

-- -- ⌘ ⌥ m : Toggle Keymaps
-- cmd_and_map('ToggleKeymaps', h.pick.keymaps, 'n', '<D-M-m>', '[⌘ ⌥ m] Toggle Keymaps')

-- -- ⌘ ⇧ f : Search in files
-- cmd_and_map('SearchInFiles', h.pick.grep, 'n', '<D-S-f>', '[⌘ ⇧ f] Search in Files')

-- -- ⌘ ⇧ p : Show command palette
-- cmd_and_map('CommandPalette', h.pick.commands, 'n', '<D-S-p>', '[⌘ ⇧ p] Command Palette')

-- -- ⌘ ⌃ g : Replace All Occurrences
-- cmd_and_map('ReplaceAll', h.edit.replace_all, 'n', '<D-C-g>', '[⌘ ⌃ g] Replace All')

-- -- ⌘ ⌃ z : Toggle Zen Mode
-- cmd_and_map('ToggleZenMode', function() require('zen-mode').toggle() end, 'n', '<D-C-z>', '[⌘ ⌃ z] Toggle Zen Mode')

-- =============================================================================
-- COMMENTED OUT - NON-HIGHLIGHTED SHORTCUTS FOR FUTURE ANALYSIS
-- =============================================================================

-- The following shortcuts were in the original config but not highlighted in the schema:

-- cmd_and_map('ShowExplorer', function() vim.cmd('Neotree show') end, 'n', '<D-S-x>', '[⌘ ⇧ x] Show Explorer')
-- cmd_and_map('ReplaceInFiles', function() require('telescope').extensions.live_grep_args.live_grep_args() end, 'n', '<D-S-h>', '[⌘ ⇧ h] Replace in Files')

-- =============================================================================
-- ADDITIONAL SHORTCUTS NOT IN SCHEMA - COMMENTED OUT FOR FUTURE ANALYSIS
-- =============================================================================

-- SOURCE CONTROL (GIT)
-- cmd_and_map('GitStatus', function() require('telescope.builtin').git_status() end, 'n', '<D-S-g>', '[⌘ ⇧ g] Git Status')

-- BREADCRUMBS AND OUTLINE
-- cmd_and_map('ToggleOutline', function() vim.cmd('SymbolsOutline') end, 'n', '<D-S-]>', '[⌘ ⇧ ]] Toggle Outline')

-- PROBLEMS/DIAGNOSTICS (F-keys not in schema)
-- cmd_and_map('NextProblem', function() vim.diagnostic.goto_next() end, 'n', '<F8>', '[F8] Next Problem')
-- cmd_and_map('PrevProblem', function() vim.diagnostic.goto_prev() end, 'n', '<S-F8>', '[⇧ F8] Previous Problem')

-- TERMINAL (backtick shortcuts not in schema)
-- cmd_and_map('NewTerminal', function() vim.cmd('ToggleTerm direction=float') end, 'n', '<D-S-`>', '[⌘ ⇧ `] New Terminal')

-- TABS AND SPLIT MANAGEMENT (not in schema)
-- cmd_and_map('CloseTab', function() vim.cmd('bdelete') end, 'n', '<D-S-w>', '[⌘ ⇧ w] Close Tab')
-- cmd_and_map('ReopenTab', function() vim.cmd('edit #') end, 'n', '<D-S-t>', '[⌘ ⇧ t] Reopen Closed Tab')

-- Split management (conflicts with sidebar toggle)
-- cmd_and_map('SplitRight', function() vim.cmd('vsplit') end, 'n', '<D-\\>', '[⌘ \\] Split Right')
-- cmd_and_map('SplitDown', function() vim.cmd('split') end, 'n', '<D-S-\\>', '[⌘ ⇧ \\] Split Down')

-- Navigate between splits (conflicts with tab navigation)
-- cmd_and_map('FocusLeft', '<C-w>h', 'n', '<D-M-Left>', '[⌘ ⌥ ←] Focus Left Split')
-- cmd_and_map('FocusRight', '<C-w>l', 'n', '<D-M-Right>', '[⌘ ⌥ →] Focus Right Split')
-- cmd_and_map('FocusUp', '<C-w>k', 'n', '<D-M-Up>', '[⌘ ⌥ ↑] Focus Up Split')
-- cmd_and_map('FocusDown', '<C-w>j', 'n', '<D-M-Down>', '[⌘ ⌥ ↓] Focus Down Split')

-- FORMATTING (conflicts with schema LSP ⌘ ⌥ f)
-- cmd_and_map('FormatDocument', function() vim.lsp.buf.format() end, 'n', '<D-S-i>', '[⌘ ⇧ i] Format Document')
-- cmd_and_map('FormatSelection', function() vim.lsp.buf.format() end, 'v', '<D-S-i>', '[⌘ ⇧ i] Format Selection')

-- PEEK DEFINITION (not in schema)
-- cmd_and_map('PeekDefinition', function()
--   require('trouble').toggle('lsp_definitions')
-- end, 'n', '<M-F12>', '[⌥ F12] Peek Definition')

-- ORGANIZE IMPORTS (conflicts with schema ⌘ ⌥ s)
-- cmd_and_map('OrganizeImports', function()
--   vim.lsp.buf.code_action({
--     context = { only = { "source.organizeImports" } },
--     apply = true,
--   })
-- end, 'n', '<D-S-o>', '[⌘ ⇧ o] Organize Imports')

-- REFACTOR (not in schema)
-- cmd_and_map('ExtractMethod', function()
--   vim.lsp.buf.code_action({
--     context = { only = { "refactor.extract" } },
--     apply = false,
--   })
-- end, 'v', '<D-S-r>', '[⌘ ⇧ r] Extract Method')

-- BOOKMARKS (not in schema)
-- cmd_and_map('ToggleBookmark', function() vim.cmd('normal! mm') end, 'n', '<D-M-k>', '[⌘ ⌥ k] Toggle Bookmark')
-- cmd_and_map('NextBookmark', function() vim.cmd('normal! ]m') end, 'n', '<D-M-l>', '[⌘ ⌥ l] Next Bookmark')
-- cmd_and_map('PrevBookmark', function() vim.cmd('normal! [m') end, 'n', '<D-M-j>', '[⌘ ⌥ j] Previous Bookmark')

-- EDITOR SETTINGS (not in schema)
-- cmd_and_map('ToggleWordWrap', function() vim.o.wrap = not vim.o.wrap end, 'n', '<M-z>', '[⌥ z] Toggle Word Wrap')
-- cmd_and_map('ToggleWhitespace', function() vim.o.list = not vim.o.list end, 'n', '<D-S-w>', '[⌘ ⇧ w] Toggle Whitespace')

-- PROJECT MANAGEMENT (not in schema)
-- cmd_and_map('RecentProjects', function() require('telescope.builtin').oldfiles() end, 'n', '<D-r>', '[⌘ r] Recent Files')

-- FILE OPERATIONS (not in schema)
-- cmd_and_map('DuplicateFile', function()
--   local filename = vim.fn.expand('%:t')
--   if filename ~= '' then
--     local new_name = vim.fn.input('Duplicate as: ', filename)
--     if new_name ~= '' and new_name ~= filename then
--       vim.cmd('saveas ' .. new_name)
--     end
--   end
-- end, 'n', '<D-S-d>', '[⌘ ⇧ d] Duplicate File')

-- WINDOW MANAGEMENT (conflicts with schema ⌘ ⌥ ↵)
-- cmd_and_map('MaximizeWindow', function()
--   vim.cmd('resize')
--   vim.cmd('vertical resize')
-- end, 'n', '<D-M-Enter>', '[⌘ ⌥ ↵] Maximize/Restore Window')

-- INTELLISENSE AND COMPLETIONS (conflicts with schema ⌘ ⌥ ␣)
-- vim.keymap.set('i', '<D-Space>', function() vim.lsp.buf.completion() end, '[⌘ ␣] Trigger Suggestion')
-- vim.keymap.set('i', '<D-S-Space>', function() vim.lsp.buf.signature_help() end, '[⌘ ⇧ ␣] Trigger Parameter Hints')

-- BREADCRUMBS NAVIGATION (not in schema)
-- cmd_and_map('FocusBreadcrumbs', function()
--   require('telescope.builtin').lsp_document_symbols()
-- end, 'n', '<D-S-;>', '[⌘ ⇧ ;] Focus Breadcrumbs')

-- USER SETTINGS (not in schema)
-- cmd_and_map('OpenSettings', function()
--   vim.cmd('edit ' .. vim.fn.stdpath('config') .. '/init.lua')
-- end, 'n', '<D-,>', '[⌘ ,] User Settings')

-- MINI-MAP TOGGLE (conflicts with schema ⌘ ⌥ m)
-- cmd_and_map('ToggleMinimap', function()
--   -- This would require a minimap plugin like minimap.vim
--   vim.cmd('Minimap')
-- end, 'n', '<D-M-m>', '[⌘ ⌥ m] Toggle Minimap')

-- Additional file management shortcuts (conflicts with schema ⌘ ⌥ s)
-- cmd_and_map('SaveAll', function() vim.cmd('wa') end, 'n', '<D-M-s>', '[⌘ ⌥ s] Save All')
-- cmd_and_map('CloseAllEditors', function() vim.cmd('%bdelete') end, 'n', '<D-K-w>', '[⌘ K w] Close All Editors')

-- Toggle different panels like VSCode (not in schema)
-- cmd_and_map('TogglePanel', function()
--   -- This would toggle bottom panel (terminal, problems, etc.)
--   vim.cmd('ToggleTerm')
-- end, 'n', '<D-j>', '[⌘ j] Toggle Panel')

-- VSCode-like selection expansion (not in schema)
-- map('n', '<M-S-Right>', 'vw', '[⌥ ⇧ →] Expand Selection')
-- map('v', '<M-S-Right>', 'w', '[⌥ ⇧ →] Expand Selection')
-- map('n', '<M-S-Left>', 'vb', '[⌥ ⇧ ←] Shrink Selection')
-- map('v', '<M-S-Left>', 'b', '[⌥ ⇧ ←] Shrink Selection')

-- DUPLICATE LINE (not in schema)
-- map('n', '<M-S-Down>', 'yyp', '[⌥ ⇧ ↓] Duplicate Line Down')
-- map('n', '<M-S-Up>', 'yyP', '[⌥ ⇧ ↑] Duplicate Line Up')
-- map('v', '<M-S-Down>', 'y`>p', '[⌥ ⇧ ↓] Duplicate Selection Down')
-- map('v', '<M-S-Up>', 'y`<P', '[⌥ ⇧ ↑] Duplicate Selection Up')

-- COLUMN SELECTION (not in schema)
-- map('v', '<M-S-i>', function()
--   require('multicursor-nvim').addCursor()
-- end, '[⌥ ⇧ i] Insert Cursor at End of Each Line')

-- BLOCK COMMENT (not in schema)
-- map('v', '<M-S-a>', 'gc', '[⌥ ⇧ a] Toggle Block Comment')

-- =============================================================================
-- COMMENTED OUT - SHORTCUTS NOT IN SCHEMA OR CONFLICTING
-- =============================================================================

-- DEBUG (not in schema)
-- cmd_and_map('Scratch', h.toggle.scratch, 'n', '<D-S-s>', '[⌘ ⇧ s] Open Scratch Buffer')
-- cmd_and_map('Notifications', h.pick.notifications, 'n', '<D-S-n>', '[⌘ ⇧ n] Notifications')

-- These navigation shortcuts are now handled by vscode-keymaps.lua following the schema
-- NAVIGATION (keeping commented as they conflict with schema)
-- cmd_and_map('GoToBOL', h.go_to.BoL, 'n', '<D-Left>', '[⌘ ←]  Move Cursor to BOL')
-- cmd_and_map('GoToEOL', h.go_to.EoL, 'n', '<D-Right>', '[⌘ →] Move Cursor to EOL')
-- cmd_and_map('GoToBOF', h.go_to.BoF, 'n', '<D-Up>', '[⌘ ↑] Move Cursor to BOF')
-- cmd_and_map('GoToEOF', h.go_to.EoF, 'n', '<D-Down>', '[⌘ ↓]  Move Cursor to EOF')
-- cmd_and_map('BufferPrev', h.go_to.buf.prev, 'n', '<D-M-Left>', '[⌥ ⌘ ←] Prev Buffer')
-- cmd_and_map('BufferNext', h.go_to.buf.next, 'n', '<D-M-Right>', '[⌥ ⌘ →] Next Buffer')

-- These are now handled by vscode-keymaps following the schema
-- map('n', '<D-Up>', 'gg', '[⌘ ↑] Move Cursor to BOF')
-- map('v', '<D-Up>', 'gg', '[⌘ ↑] Move Cursor to BOF')
-- vim.keymap.set('i', '<D-Up>', '<Esc>ggi', '[⌘ ↑] Move Cursor to BOF')

-- EDIT (save is not in schema, commenting out to avoid conflicts)
-- map('n', '<D-s>', ':w<CR>', '[⌘ s] Save File')
-- vim.keymap.set('i', '<D-s>', '<C-o>:w<CR>', '[⌘ s] Save File')
-- map('v', '<D-s>', '<Esc>:w<CR>gv', '[⌘ s] Save File')

-- Quit shortcuts (not in schema)
-- map('n', '<D-q>', ':q<CR>', '[⌘ q] Quit')
-- vim.keymap.set('i', '<D-q>', '<C-o>:q<CR>', '[⌘ q] Quit')
-- map('v', '<D-q>', '<Esc>:q<CR>', '[⌘ q] Quit')
-- map('n', '<D-M-q>', ':q!<CR>', '[⌘ q] Quit (force!)')
-- vim.keymap.set('i', '<D-M-q>', '<C-o>:q!<CR>', '[⌘ q] Quit (force!)')
-- map('v', '<D-M-q>', '<Esc>:q!<CR>', '[⌘ q] Quit (force!)')

-- =============================================================================
-- SELECTION SHORTCUTS (not in schema - commented out for future analysis)
-- =============================================================================

-- SHIFT + ARROW KEYS for LINE SELECTION (VSCode-like behavior)
-- Start line selection from normal mode
-- map('n', '<S-Down>', 'V<Down>', '[⇧ ↓] Select line down')
-- map('n', '<S-Up>', 'V<Up>', '[⇧ ↑] Select line up')

-- Extend line selection in visual mode (linewise)
-- map('x', '<S-Down>', '<Down>', '[⇧ ↓] Extend selection down')
-- map('x', '<S-Up>', '<Up>', '[⇧ ↑] Extend selection up')

-- In visual line mode, continue selecting lines
-- map('v', '<S-Down>', 'j', '[⇧ ↓] Extend selection down')
-- map('v', '<S-Up>', 'k', '[⇧ ↑] Extend selection up')

-- SHIFT + LEFT/RIGHT for CHARACTER SELECTION
-- map('n', '<S-Left>', 'v<Left>', '[⇧ ←] Select character left')
-- map('n', '<S-Right>', 'v<Right>', '[⇧ →] Select character right')
-- map('x', '<S-Left>', '<Left>', '[⇧ ←] Extend selection left')
-- map('x', '<S-Right>', '<Right>', '[⇧ →] Extend selection right')
-- map('v', '<S-Left>', 'h', '[⇧ ←] Extend selection left')
-- map('v', '<S-Right>', 'l', '[⇧ →] Extend selection right')

-- ALT + SHIFT + ARROW KEYS to SELECT until the end of the next word
-- map('n', '<A-S-Down>', 'v}', '[⌥ ⇧ ↓] Select to next paragraph')
-- map('n', '<A-S-Up>', 'v{', '[⌥ ⇧ ↑] Select to previous paragraph')
-- map('n', '<A-S-Right>', 've', '[⌥ ⇧ →] Select to end of word')
-- map('n', '<A-S-Left>', 'vb', '[⌥ ⇧ ←] Select to beginning of word')
-- map('v', '<A-S-Down>', '}', '[⌥ ⇧ ↓] Extend to next paragraph')
-- map('v', '<A-S-Up>', '{', '[⌥ ⇧ ↑] Extend to previous paragraph')
-- map('v', '<A-S-Right>', 'e', '[⌥ ⇧ →] Extend to end of word')
-- map('v', '<A-S-Left>', 'b', '[⌥ ⇧ ←] Extend to beginning of word')

-- CMD + SHIFT + ARROW KEYS to SELECT TO START/END OF LINE/FILE
-- map('n', '<D-S-Left>', 'v0', '[⌘ ⇧ ←] Select to beginning of line')
-- map('n', '<D-S-Right>', 'v$', '[⌘ ⇧ →] Select to end of line')
-- map('n', '<D-S-Up>', 'vgg', '[⌘ ⇧ ↑] Select to beginning of file')
-- map('n', '<D-S-Down>', 'vG', '[⌘ ⇧ ↓] Select to end of file')
-- map('v', '<D-S-Left>', '0', '[⌘ ⇧ ←] Extend to beginning of line')
-- map('v', '<D-S-Right>', '$', '[⌘ ⇧ →] Extend to end of line')
-- map('v', '<D-S-Up>', 'gg', '[⌘ ⇧ ↑] Extend to beginning of file')
-- map('v', '<D-S-Down>', 'G', '[⌘ ⇧ ↓] Extend to end of file')

-- =============================================================================
-- SHORTCUTS NOW HANDLED BY VSCODE-KEYMAPS FOLLOWING SCHEMA
-- =============================================================================

-- These shortcuts are now handled properly in vscode-keymaps.lua following the exact schema:
-- cmd_and_map('Close', h.buf.close, 'n', '<D-w>', '[⌘ w] Close Current Editor')
-- cmd_and_map('Cut', h.edit.cut, 'n', '<D-x>', '[⌘ x] Cut selection to clipboard')
-- cmd_and_map('Copy', h.edit.copy, 'n', '<D-c>', '[⌘ c] Copy selection to clipboard')
-- cmd_and_map('Paste', h.edit.paste, 'n', '<D-v>', '[⌘ v] Paste selection to clipboard')
-- cmd_and_map('Undo', h.edit.undo, 'n', '<D-z>', '[⌘ z] Undo')
-- cmd_and_map('SelectAll', h.edit.select_all, 'n', '<D-a>', '[⌘ a] Select all')
-- cmd_and_map('Redo', h.edit.redo, 'n', '<D-y>', '[⌘ y] Redo')
-- cmd_and_map('New', h.edit.new, 'n', '<D-n>', '[⌘ n] New File')

-- =============================================================================
-- CONFLICTING SHORTCUTS - COMMENTED OUT
-- =============================================================================

-- These conflict with the schema shortcuts:
-- cmd_and_map('ReplaceAll', h.edit.replace_all, 'n', '<D-g>', '[⌘ g] Replace all occurrences') -- conflicts with ⌃ g
-- cmd_and_map('RenameFile', h.edit.undo, 'n', '<D-bslash>', '[⌘ \\] Toggle Sidebar Left') -- conflicts with sidebar toggle

-- SEARCH and PICKERS (conflicts with schema)
-- cmd_and_map('Grep', h.pick.grep, 'n', '<D-F>', '[⌘ F] Find in Project Files') -- conflicts with ⌘ f
-- cmd_and_map('Find', h.pick.find, 'n', '<D-f>', '[⌘ f] Find in Current File') -- now handled by schema
-- cmd_and_map('Files', h.pick.files, 'n', '<D-p>', '[⌘ p] Search files by name') -- now handled by schema
-- cmd_and_map('Smart', h.pick.smart, 'n', '<D-M-p>', '[⌘ ⌥ p] Smart Find Files') -- not in schema
-- cmd_and_map('Commands', h.pick.commands, 'n', '<D-S-p>', '[⌘ ⇧ P] Command Palette') -- now handled by schema
-- cmd_and_map('Maps', h.pick.keymaps, 'n', '<D-M-m>', '[⌘ ⌥ m] Toggle Keymaps') -- now handled by schema
-- cmd_and_map('Help', h.pick.help, 'n', '<D-;>', '[⌘ ;] Toggle Help') -- not in schema
-- cmd_and_map('Menus', h.toggle.menus, 'n', '<D-m>', '[⌘ m] Toggle Menus') -- not in schema
-- cmd_and_map('Ftypes', h.pick.filetype, 'n', '<D-l>', '[⌘ l] Pick FileTypes') -- not in schema
-- cmd_and_map('News', h.toggle.news, 'n', '<D-M-n>', '[⌘ ⌥ n] Neovim News') -- not in schema

-- UI (now handled by schema)
-- map('n', '<D-[>', 'zc', '[⌘ [ ] Fold Region') -- now handled by schema
-- map('n', '<D-]>', 'zo', '[⌘ [ ] Unfold Region') -- now handled by schema
-- map('n', '<D-S-[>', 'zM', '[⌘ ⇧ [ ] Fold All Region') -- conflicts with schema
-- map('n', '<D-S-]>', 'zR', '[⌘ ⇧ ] ] Unfold All Region') -- conflicts with schema

-- INDENTING (not in schema)
-- VISUAL MODE: indent with Tab and Shift+Tab
-- map('v', '<Tab>', '>gv', 'Indent Right')
-- map('v', '<S-Tab>', '<gv', 'Indent Left')
-- NORMAL MODE: indent current line with Tab and Shift+Tab
-- map('n', '<Tab>', '>>', 'Indent Line Right')
-- map('n', '<S-Tab>', '<<', 'Indent Line Left')

-- COMMENTING (now handled by schema)
-- map('n', '<D-/>', '<Plug>(comment_toggle_linewise_current)', 'Add Comment Above') -- now handled by schema
-- map('v', '<D-/>', '<Plug>(comment_toggle_linewise_visual)', 'Add Comment Above') -- now handled by schema

-- DIAGNOSTICS (conflicts with schema ⌘ d)
-- cmd_and_map('Diagnostics', h.toggle.diagnostics, 'n', '<D-M-d>', '[⌘ ⌥ d] Toggle Diagnostics') -- conflicts with ⌘ ⌥ d
-- cmd_and_map('DiagnosticsWorkspace', h.toggle.diagnostics_in_wks, 'n', '<D-C-S-D>', '[⌘ ^ ⇧ D] Toggle Diagnostics in Wks') -- not in schema
-- cmd_and_map('ToggleZenMode', h.toggle.zen_mode, 'n', '<D-C-z>', '[⌘ ⌃ z] Toggle Zen Mode') -- now handled by schema
-- cmd_and_map('ToggleSideBarLeft', h.toggle.sidebar_left, 'n', '<D-\\>', '[⌘ \\] Toggle SideBar left (Explorer)') -- now handled by schema

-- LSP (conflicts with schema)
-- map('n', '<D-M-f>', h.lsp.format, '[⌘ ⌃ f] Format Document') -- conflicts with ⌘ ⌥ f
-- map('n', '<D-M-Enter>', h.lsp.rename, '[⌘ ⌥ ↵] Rename symbol (calls <Space>cr)') -- now handled by schema
-- cmd_and_map('LspDefinitions', h.lsp.definitions, 'n', '<D-i>', '[⌘ i] Go to Definitions') -- now handled by schema
-- cmd_and_map('LspDeclarations', h.lsp.declarations, 'n', '<D-M-d>', '[⌘ ⌥ D] Go to Declaration') -- now handled by schema
-- cmd_and_map('LspImplementations', h.lsp.implementations, 'n', '<D-M-i>', '[⌘ ⌥ i] Go to Implementation') -- now handled by schema

-- =============================================================================
-- REMAINING LSP SHORTCUTS - SOME CONFLICT WITH SCHEMA
-- =============================================================================

-- These conflict with schema shortcuts:
-- cmd_and_map('LspTypeDefinitions', h.lsp.type_definitions, 'n', '<D-M-t>', '[⌘ ⌥ t] Go to Type Definition') -- not in schema
-- cmd_and_map('LspReferences', h.lsp.references, 'n', '<D-M-r>', '[⌘ ⌥ r] Find All References') -- now handled by schema
-- cmd_and_map('LspToggleCodeActions', h.lsp.code_actions, 'n', '<D-.>', '[⌘ .] Toggle Code Actions') -- now handled by schema
-- cmd_and_map('LspSymbols', h.lsp.syms, 'n', '<D-t>', '[⌘ t] Symbols in File') -- conflicts with ⌘ t Terminal
-- cmd_and_map('LspSymbolsWks', h.lsp.syms_in_wks, 'n', '<D-M-w>', '[⌘ ⌥ w] Symbols in Workspace') -- not in schema
-- cmd_and_map('Restart', [[nvim -c ":lua vim.cmd('edit ' .. vim.v.oldfiles[1])" -c ":lua vim.cmd(vim.fn.histget(':', -3))"]], 'n', '<D-S-r>', '[⌘ ⇧ r] Restart Neovim with last command and file') -- not in schema

-- =============================================================================
-- AUTOCOMPLETION (VSCode-like behavior using NATIVE Neovim 0.11+ completion)
-- =============================================================================

-- These keymaps integrate with the native completion configuration in plugins/completions.lua
-- to provide VSCode-like autocompletion behavior WITHOUT external plugins

-- The following behaviors are implemented in the completion plugin configuration:
-- - Dot (.) triggers autocompletion and accepts current selection
-- - Tab accepts selected completion
-- - Escape dismisses autocompletion without accepting
-- - Ctrl+Space manually triggers completion

-- Additional completion navigation shortcuts (insert mode only)
local function setup_native_completion_keymaps()
  -- Only set up these keymaps if we're using native completion
  if vim.fn.has('nvim-0.11') == 1 or vim.fn.has('nvim-0.10') == 1 then
    -- ⌃ ␣ : Manually trigger completion (VSCode-like)
    vim.keymap.set('i', '<C-Space>', function()
      if vim.fn.pumvisible() == 1 then
        return '<C-e>'      -- Close if visible
      else
        return '<C-x><C-o>' -- Trigger omnifunc completion
      end
    end, { desc = '[⌃ ␣] Trigger Completion', expr = true })

    -- ↑ / ↓ : Navigate completion items when menu is visible (enhanced behavior)
    vim.keymap.set('i', '<Up>', function()
      if vim.fn.pumvisible() == 1 then
        return '<C-p>'
      else
        return '<Up>'
      end
    end, { desc = '[↑] Previous Completion', expr = true })

    vim.keymap.set('i', '<Down>', function()
      if vim.fn.pumvisible() == 1 then
        return '<C-n>'
      else
        return '<Down>'
      end
    end, { desc = '[↓] Next Completion', expr = true })

    -- Enhanced navigation that doesn't conflict with existing keymaps
    vim.keymap.set('i', '<C-n>', function()
      return vim.fn.pumvisible() == 1 and '<C-n>' or '<C-x><C-o>'
    end, { desc = '[Ctrl-n] Next Completion', expr = true })

    vim.keymap.set('i', '<C-p>', function()
      return vim.fn.pumvisible() == 1 and '<C-p>' or '<C-x><C-o>'
    end, { desc = '[Ctrl-p] Previous Completion', expr = true })
  end
end

-- Call the setup function
setup_native_completion_keymaps()

-- =============================================================================
-- REMAINING SHORTCUTS - SOME CONFLICT WITH SCHEMA
-- =============================================================================

-- These conflict with schema shortcuts:
-- cmd_and_map('LspTypeDefinitions', h.lsp.type_definitions, 'n', '<D-M-t>', '[⌘ ⌥ t] Go to Type Definition') -- not in schema
-- cmd_and_map('LspReferences', h.lsp.references, 'n', '<D-M-r>', '[⌘ ⌥ r] Find All References') -- now handled by schema
-- cmd_and_map('LspToggleCodeActions', h.lsp.code_actions, 'n', '<D-.>', '[⌘ .] Toggle Code Actions') -- now handled by schema
-- cmd_and_map('LspSymbols', h.lsp.syms, 'n', '<D-t>', '[⌘ t] Symbols in File') -- conflicts with ⌘ t Terminal
-- cmd_and_map('LspSymbolsWks', h.lsp.syms_in_wks, 'n', '<D-M-w>', '[⌘ ⌥ w] Symbols in Workspace') -- not in schema
-- cmd_and_map('Restart', [[nvim -c ":lua vim.cmd('edit ' .. vim.v.oldfiles[1])" -c ":lua vim.cmd(vim.fn.histget(':', -3))"]], 'n', '<D-S-r>', '[⌘ ⇧ r] Restart Neovim with last command and file') -- not in schema

-- =============================================================================
-- REMAINING SHORTCUTS - NO CONFLICT WITH SCHEMA
-- =============================================================================

-- These shortcuts do not conflict with the schema and are available for use:
-- cmd_and_map('Close', h.buf.close, 'n', '<D-w>', '[⌘ w] Close Current Editor')
-- cmd_and_map('Cut', h.edit.cut, 'n', '<D-x>', '[⌘ x] Cut selection to clipboard')
-- cmd_and_map('Copy', h.edit.copy, 'n', '<D-c>', '[⌘ c] Copy selection to clipboard')
-- cmd_and_map('Paste', h.edit.paste, 'n', '<D-v>', '[⌘ v] Paste selection to clipboard')
-- cmd_and_map('Undo', h.edit.undo, 'n', '<D-z>', '[⌘ z] Undo')
-- cmd_and_map('SelectAll', h.edit.select_all, 'n', '<D-a>', '[⌘ a] Select all')
-- cmd_and_map('Redo', h.edit.redo, 'n', '<D-y>', '[⌘ y] Redo')
-- cmd_and_map('New', h.edit.new, 'n', '<D-n>', '[⌘ n] New File')

-- =============================================================================
-- CONFLICTING SHORTCUTS - COMMENTED OUT
-- =============================================================================

-- These conflict with the schema shortcuts:
-- cmd_and_map('ReplaceAll', h.edit.replace_all, 'n', '<D-g>', '[⌘ g] Replace all occurrences') -- conflicts with ⌃ g
-- cmd_and_map('RenameFile', h.edit.undo, 'n', '<D-bslash>', '[⌘ \\] Toggle Sidebar Left') -- conflicts with sidebar toggle

-- SEARCH and PICKERS (conflicts with schema)
-- cmd_and_map('Grep', h.pick.grep, 'n', '<D-F>', '[⌘ F] Find in Project Files') -- conflicts with ⌘ f
-- cmd_and_map('Find', h.pick.find, 'n', '<D-f>', '[⌘ f] Find in Current File') -- now handled by schema
-- cmd_and_map('Files', h.pick.files, 'n', '<D-p>', '[⌘ p] Search files by name') -- now handled by schema
-- cmd_and_map('Smart', h.pick.smart, 'n', '<D-M-p>', '[⌘ ⌥ p] Smart Find Files') -- not in schema
-- cmd_and_map('Commands', h.pick.commands, 'n', '<D-S-p>', '[⌘ ⇧ P] Command Palette') -- now handled by schema
-- cmd_and_map('Maps', h.pick.keymaps, 'n', '<D-M-m>', '[⌘ ⌥ m] Toggle Keymaps') -- now handled by schema
-- cmd_and_map('Help', h.pick.help, 'n', '<D-;>', '[⌘ ;] Toggle Help') -- not in schema
-- cmd_and_map('Menus', h.toggle.menus, 'n', '<D-m>', '[⌘ m] Toggle Menus') -- not in schema
-- cmd_and_map('Ftypes', h.pick.filetype, 'n', '<D-l>', '[⌘ l] Pick FileTypes') -- not in schema
-- cmd_and_map('News', h.toggle.news, 'n', '<D-M-n>', '[⌘ ⌥ n] Neovim News') -- not in schema

-- UI (now handled by schema)
-- map('n', '<D-[>', 'zc', '[⌘ [ ] Fold Region') -- now handled by schema
-- map('n', '<D-]>', 'zo', '[⌘ [ ] Unfold Region') -- now handled by schema
-- map('n', '<D-S-[>', 'zM', '[⌘ ⇧ [ ] Fold All Region') -- conflicts with schema
-- map('n', '<D-S-]>', 'zR', '[⌘ ⇧ ] ] Unfold All Region') -- conflicts with schema

-- INDENTING (not in schema)
-- VISUAL MODE: indent with Tab and Shift+Tab
-- map('v', '<Tab>', '>gv', 'Indent Right')
-- map('v', '<S-Tab>', '<gv', 'Indent Left')
-- NORMAL MODE: indent current line with Tab and Shift+Tab
-- map('n', '<Tab>', '>>', 'Indent Line Right')
-- map('n', '<S-Tab>', '<<', 'Indent Line Left')

-- COMMENTING (now handled by schema)
-- map('n', '<D-/>', '<Plug>(comment_toggle_linewise_current)', 'Add Comment Above') -- now handled by schema
-- map('v', '<D-/>', '<Plug>(comment_toggle_linewise_visual)', 'Add Comment Above') -- now handled by schema

-- DIAGNOSTICS (conflicts with schema ⌘ d)
-- cmd_and_map('Diagnostics', h.toggle.diagnostics, 'n', '<D-M-d>', '[⌘ ⌥ d] Toggle Diagnostics') -- conflicts with ⌘ ⌥ d
-- cmd_and_map('DiagnosticsWorkspace', h.toggle.diagnostics_in_wks, 'n', '<D-C-S-D>', '[⌘ ^ ⇧ D] Toggle Diagnostics in Wks') -- not in schema
-- cmd_and_map('ToggleZenMode', h.toggle.zen_mode, 'n', '<D-C-z>', '[⌘ ⌃ z] Toggle Zen Mode') -- now handled by schema
-- cmd_and_map('ToggleSideBarLeft', h.toggle.sidebar_left, 'n', '<D-\\>', '[⌘ \\] Toggle SideBar left (Explorer)') -- now handled by schema

-- LSP (conflicts with schema)
-- map('n', '<D-M-f>', h.lsp.format, '[⌘ ⌃ f] Format Document') -- conflicts with ⌘ ⌥ f
-- map('n', '<D-M-Enter>', h.lsp.rename, '[⌘ ⌥ ↵] Rename symbol (calls <Space>cr)') -- now handled by schema
-- cmd_and_map('LspDefinitions', h.lsp.definitions, 'n', '<D-i>', '[⌘ i] Go to Definitions') -- now handled by schema
-- cmd_and_map('LspDeclarations', h.lsp.declarations, 'n', '<D-M-d>', '[⌘ ⌥ D] Go to Declaration') -- now handled by schema
-- cmd_and_map('LspImplementations', h.lsp.implementations, 'n', '<D-M-i>', '[⌘ ⌥ i] Go to Implementation') -- now handled by schema

-- =============================================================================
-- REMAINING LSP SHORTCUTS - SOME CONFLICT WITH SCHEMA
-- =============================================================================

-- These conflict with schema shortcuts:
-- cmd_and_map('LspTypeDefinitions', h.lsp.type_definitions, 'n', '<D-M-t>', '[⌘ ⌥ t] Go to Type Definition') -- not in schema
-- cmd_and_map('LspReferences', h.lsp.references, 'n', '<D-M-r>', '[⌘ ⌥ r] Find All References') -- now handled by schema
-- cmd_and_map('LspToggleCodeActions', h.lsp.code_actions, 'n', '<D-.>', '[⌘ .] Toggle Code Actions') -- now handled by schema
-- cmd_and_map('LspSymbols', h.lsp.syms, 'n', '<D-t>', '[⌘ t] Symbols in File') -- conflicts with ⌘ t Terminal
-- cmd_and_map('LspSymbolsWks', h.lsp.syms_in_wks, 'n', '<D-M-w>', '[⌘ ⌥ w] Symbols in Workspace') -- not in schema
-- cmd_and_map('Restart', [[nvim -c ":lua vim.cmd('edit ' .. vim.v.oldfiles[1])" -c ":lua vim.cmd(vim.fn.histget(':', -3))"]], 'n', '<D-S-r>', '[⌘ ⇧ r] Restart Neovim with last command and file') -- not in schema

-- Replace the word cursor is on globally
-- vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
--   { desc = "Replace word cursor is on globally" })
