vim.schedule_wrap(function()
  --- lua-language-server: disable
  -- stylua: ignore
  require('core/vi/maps').set_keymaps(function(buf, pick, toggle, lsp, ev, setup)
    -- =============================================================================
    -- NATIVE COMMENTS (https://neovim.io/doc/user/various.html#commenting)
    -- nvim 0.10.0 has builtin support for commenting (:h commenting)
    -- But doesn't work when remapping with `vim.keymap.set` so we call directly...
    -- gc<motion> must to be used manually
    -- =============================================================================
    setup.toggle_comments_mappings('<D-/>')

    return {
      -- ===========================================================================
      -- EDITOR
      -- ===========================================================================
      ['<D-a>'] = { { n = 'ggVG', i = '<C-O>ggVG', v = '<ESC>ggVG' }, 'Select All' },
      ['<D-C-g>'] = { { n = '<Plug>(VM-Find-Under)', x = '<Plug>(VM-Find-Subword-Under)' }, 'Select All Occurrences' },
      ['<D-C-h>'] = { { v = 'y:%s#<C-R>=@"<CR>#' }, 'Replace the selected text' },
      ['<D-c>'] = { { n = '"+yy', i = '<C-O>"+yy', v = '"+y' }, 'Copy to Clipboard' },
      ['<D-n>'] = { { n = '<CMD>enew<CR>', i = '<C-O><CMD>enew<CR>', v = '<ESC><CMD>enew<CR>' }, 'New File' },
      ['<D-s>'] = { { n = '<CMD>w<CR>', i = '<C-O><CMD>w<CR>', v = '<C-O><CMD>w<CR>gv' }, 'Save File' },
      ['<D-S-s>'] = { { n = '<CMD>wa<CR>', i = '<C-O><CMD>wa<CR>', v = '<C-O><CMD>wa<CR>gv' }, 'Save All' },
      ['<D-v>'] = { { n = '"+p', i = '<C-O>"+p', v = '"+p' }, 'Paste' },
      ['<D-x>'] = { { n = '"+dd', i = '<C-O>"+dd', v = '"+d' }, 'Cut' },
      ['<D-y>'] = { { n = '<C-r>', i = '<C-O><C-r>', v = '<C-O><C-r>gv' }, 'Redo' },
      ['<D-z>'] = { { n = 'u', i = '<C-O>u', v = '<C-O>ugv' }, 'Undo' },
      ['<D-q>'] = { { n = '<CMD>q<CR>', i = '<Esc><CMD>q<CR>', v = '<Esc><CMD>q<CR>' }, 'Quit Editor' },
      ['<D-S-q>'] = { { n = '<CMD>q!<CR>', i = '<Esc><CMD>q!<CR>', v = '<Esc><CMD>q!<CR>' }, 'Force Quit Editor' },
      ['<D-M-q>'] = { { n = '<CMD>qa<CR>', i = '<Esc><CMD>qa<CR>', v = '<Esc><CMD>qa<CR>' }, 'Quit All Editors' },
      ['<D-S-M-q>'] = { { n = '<CMD>qa!<CR>', i = '<Esc><CMD>qa!<CR>', v = '<Esc><CMD>qa!<CR>' }, 'Force Quit All Editors' },
      ['<D-M-c>'] = { { n = '<CMD>let @+ = expand("%:p")<CR>', i = '<C-O><CMD>let @+ = expand("%:p")<CR>', v = '<ESC><CMD>let @+ = expand("%:p")<CR>' }, 'Copy File Path', { cmd = 'CopyFilePath' } },
      ['<D-M-v>'] = { { n = '"+p', i = '<C-O>"+p', v = '"+p' }, 'Paste File Path', { cmd = 'PasteFilePath' } },
      -- =============================================================================
      -- MOVING AROUND
      -- =============================================================================
      ['<A-Down>'] = { { n = "<CMD>execute 'move .+' . v:count1<CR>==", i = '<ESC><CMD>m .+1<CR>==gi', v = ":<C-u>execute \"'<,'>move '>+\" . v:count1<CR>gv=gv" }, 'Move Line Down' },
      ['<A-Up>'] = { { n = "<CMD>execute 'move .-' . (v:count1 + 1)<CR>==", i = '<ESC><CMD>m .-2<CR>==gi', v = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<CR>gv=gv" }, 'Move Line Up' },
      ['<C-a>'] = { { n = '0', i = '<C-O>0', v = '<C-O>0' }, 'Move to BoL' },
      ['<C-e>'] = { { n = '$', i = '<C-O>$', v = '<C-O>$' }, 'Move to EoL' },
      ['<D-Up>'] = { { n = 'gg', i = '<C-O>gg' }, 'Go to BoF' },
      ['<D-Down>'] = { { n = 'G', i = '<C-O>G' }, 'Go to EoF' },
      ['<D-Left>'] = { { n = '0', i = '<C-O>0' }, 'Move to BoL' },
      ['<D-Right>'] = { { n = '$', i = '<C-O>$' }, 'Move to EoL' },
      -- ===========================================================================
      -- INDENTATION
      -- ===========================================================================
      ['<Tab>'] = { { n = '>>', i = '<C-O>>>', v = '>gv' }, 'Indent Line/Selection' },
      ['<S-Tab>'] = { { n = '<<', i = '<C-O><<', v = '<gv' }, 'Outdent Line/Selection' },
      -- ===========================================================================
      -- SELECTION (SHIFT + ARROW KEYS for LINE selection)
      -- ===========================================================================
      ['<S-Down>'] = { { n = 'V<Down>', x = '<Down>', v = '<Down>', i = '<C-O>V<Down>' }, 'Select Line Down' },
      ['<S-Up>'] = { { n = 'V<Up>', x = '<Up>', v = '<Up>', i = '<C-O>V<Up>' }, 'Select Line Up' },
      ['<S-Right>'] = { { n = 'vw', v = 'w', x = '<Right>', i = '<C-O>vw' }, 'Expand Selection' },
      ['<S-Left>'] = { { n = 'vb', v = 'b', x = '<Left>', i = '<C-O>vb' }, 'Shrink Selection' },
      -- ===========================================================================
      -- SELECTION (CMD + SHIFT + ARROW KEYS for CHUNK selection)
      -- ===========================================================================
      ['<D-S-Left>'] = { { n = 'v0', v = '0', i = '<C-O>v0' }, 'Select to BoL' },
      ['<D-S-Right>'] = { { n = 'v$', v = '$', i = '<C-O>v$' }, 'Select to EoL' },
      ['<D-S-Up>'] = { { n = 'vgg', v = 'gg', i = '<C-O>vgg' }, 'Select to BoF' },
      ['<D-S-Down>'] = { { n = 'vG', v = 'G', i = '<C-O>vG' }, 'Select to EoF' },
      -- ===========================================================================
      -- SELECTION (ALT + SHIFT + ARROW KEYS for WORD selection)
      -- ===========================================================================
      ['<M-S-Right>'] = { { n = 've', v = 'e', i = '<C-O>ve' }, 'Select to EoW' },
      ['<M-S-Left>'] = { { n = 'vb', v = 'b', i = '<C-O>vb' }, 'Select to BoW' },
      ['<M-S-Down>'] = { { n = 'v}', v = '}', i = '<C-O>v}' }, 'Select to Next Paragraph' },
      ['<M-S-Up>'] = { { n = 'v{', v = '{', i = '<C-O>v{' }, 'Select to Previous Paragraph' },
      -- ===========================================================================
      -- FOLDING
      -- ===========================================================================
      ['<D-[>'] = { { n = 'zc', i = 'zc' }, 'Fold' },
      ['<D-]>'] = { { n = 'zo', i = 'zo' }, 'Unfold' },
      ['<D-M-[>'] = { { n = 'zM', i = 'zM' }, 'Fold All' },
      ['<D-M-]>'] = { { n = 'zR', i = 'zR' }, 'Unfold All' },
      -- =============================================================================
      -- SEARCH
      -- =============================================================================
      ['<D-p>'] = { { n = pick.smart, i = pick.smart }, 'Smart Search Files', { cmd = 'SmartSearch' } },
      ['<D-S-p>'] = { { n = pick.commands, i = pick.commands, v = pick.commands }, 'Command Palette', { cmd = 'CommandPalette' } },
      ['<D-M-p>'] = { { n = pick.files, i = pick.files, v = pick.files }, 'Search Files', { cmd = 'SearchFiles' } },
      ['<D-f>'] = { { n = pick.find, i = pick.find }, 'Find in File', { cmd = 'FindInFile' } },
      ['<D-S-f>'] = { { n = pick.grep, i = pick.grep, v = pick.grep }, 'Search in Files (Grep)', { cmd = 'Grep' } },
      ['<D-?>'] = { { n = ":let @/='<C-R>=expand('<cword>')<CR>' | set hls<CR>", v = "y:let @/='<C-R>=escape(@\",'/\\')<CR>' | set hls<CR>", x = "<Esc>/\\%V" }, 'Search word under cursor, the selected text or visual selection' },
      -- =============================================================================
      -- BUFFERS
      -- =============================================================================
      ['<D-M-Left>'] = { { n = '<CMD>BufferLineCyclePrev<CR>', i = '<C-O><CMD>BufferLineCyclePrev<CR>', v = '<ESC><CMD>BufferLineCyclePrev<CR>' }, 'Go to Previous Buffer (Left)' },
      ['<D-M-Right>'] = { { n = '<CMD>BufferLineCycleNext<CR>', i = '<C-O><CMD>BufferLineCycleNext<CR>', v = '<ESC><CMD>BufferLineCycleNext<CR>' }, 'Go to Next Buffer (Right)' },
      ['<D-M-C-Right>'] = { { n = '<CMD>buffer #<CR>', i = '<C-O><CMD>buffer #<CR>', v = '<ESC><CMD>buffer #<CR>' }, 'Go to Last Buffer (Right)' }, -- https://github.com/folke/snacks.nvim/blob/main/docs/buf.md#snacksbuflast
      ['<D-w>'] = { { n = buf.close, i = buf.close, v = buf.close }, 'Close Buffer' },
      ['<D-M-w>'] = { { n = buf.close_all, i = buf.close_all, v = buf.close_all }, 'Close All Buffer' },
      ['<D-S-w>'] = { { n = buf.close_others, i = buf.close_others, v = buf.close_others }, 'Close All Others Buffer' },
      ['<D-C-S-Left>'] = { { n = '<C-w>H', i = '<C-o><C-w>H', v = '<C-w>H' }, 'Move window left' },
      ['<D-C-S-Right>'] = { { n = '<C-w>L', i = '<C-o><C-w>L', v = '<C-w>L' }, 'Move window right' },
      ['<D-C-S-Up>'] = { { n = '<C-w>K', i = '<C-o><C-w>K', v = '<C-w>K' }, 'Move window top' },
      ['<D-C-S-Down>'] = { { n = '<C-w>J', i = '<C-o><C-w>J', v = '<C-w>J' }, 'Move window bottom' },
      ['<D-t>'] = { { n = toggle.term, i = toggle.term, v = toggle.term, t = toggle.term }, 'Toggle terminal' },
      -- =============================================================================
      -- PICKERS
      -- =============================================================================
      ['<D-b>'] = { { n = pick.buffers, i = pick.buffers, v = pick.buffers }, 'Neovim\'s Buffers', { cmd = 'Buffers' } },
      ['<D-;>'] = { { n = pick.help, i = pick.help, v = pick.help }, 'Toggle Help', { cmd = 'Help' } },
      ['<D-Bslash>'] = { { n = pick.explorer, i = pick.explorer, v = pick.explorer }, 'Toggle left side bar', { cmd = 'ToggleSideBarLeft' } },
      ['<D-S-Bslash>'] = { { n = toggle.new_scratch, i = toggle.new_scratch }, 'Open scratch playground', { cmd = 'ToggleNewScratch' } },
      ['<D-S-M-h>'] = { { n = pick.highlights, i = pick.highlights, v = pick.highlights }, 'Neovim`s Highlights', { cmd = 'Highlights' } },
      ['<D-S-M-l>'] = { { n = pick.lua_path_items, i = pick.lua_path_items, v = pick.lua_path_items }, 'Lua path items', { cmd = 'LuaPathItems' } },
      ['<D-S-M-m>'] = { { n = toggle.menus.n, i = toggle.menus.i, v = toggle.menus.v }, 'Toggle Menus', { cmd = 'ToggleMenus' } },
      ['<D-S-M-p>'] = { { n = toggle.news, i = toggle.news, v = toggle.news }, 'Neovim News', { cmd = 'NeovimNews' } },
      ['<D-S-M-r>'] = { { n = pick.runtimepath_items, i = pick.runtimepath_items, v = pick.runtimepath_items }, 'Runtimepath items', { cmd = 'RuntimepathItems' } },
      ['<D-S-M-t>'] = { { n = pick.filetypes, i = pick.filetypes, v = pick.filetypes }, 'Neovim`s FileTypes', { cmd = 'FileTypes' } },
      ['<D-S-M-k>'] = { { n = pick.keymaps, i = pick.keymaps }, 'Toggle Keymaps', { cmd = 'Maps' } },
      ['<D-S-M-c>'] = { { n = lsp.config, i = lsp.config, v = lsp.config }, 'LSP Configuration', { cmd = 'LspConfig' } },
      ['<D-S-M-a>'] = { { n = pick.autocmds, i = pick.autocmds, v = pick.autocmds }, 'Neovim`s Autocmds', { cmd = 'Autocmds' } },
      ['<D-S-M-o>'] = { { n = pick.options, i = pick.options, v = pick.options }, 'Neovim`s Options', { cmd = 'Options' } },
      ['<D-S-M-j>'] = { { n = pick.jumps, i = pick.jumps, v = pick.jumps }, 'Neovim`s Jumps', { cmd = 'Jumps' } },
      ['<D-S-M-s>'] = { { n = pick.move_buffer_split, i = pick.move_buffer_split, v = pick.move_buffer_split }, 'Move Buffer Split', { cmd = 'MoveBufferSplit' } },
      ['<D-S-M-z>'] = { { n = toggle.zen, i = toggle.zen, v = toggle.zen }, 'Toggle Zen Mode', { cmd = 'ToggleZen' } },
      -- ===========================================================================
      -- LSP
      -- ===========================================================================
      ['<D-.>'] = { { n = vim.lsp.buf.code_action, i = vim.lsp.buf.code_action }, 'Code Actions', { cmd = 'LspCodeActions' } },
      ['<D-M-k>'] = { { n = vim.lsp.buf.hover, i = vim.lsp.buf.hover }, 'Hover information on symbol under the cursor', { cmd = 'LspHover' } },
      ['<D-M-f>'] = { { n = vim.lsp.buf.format, i = vim.lsp.buf.format }, 'Format Document', { cmd = 'LspFormat' } },
      ['<D-S-M-f>'] = { { n = buf.format, i = buf.format }, 'Format Current Selection or buffer', { cmd = 'LspFormatRange', range = true } },
      ['<D-M-CR>'] = { { n = vim.lsp.buf.rename, i = vim.lsp.buf.rename }, 'Rename Symbol', { cmd = 'LspRename' } },
      ['<C-Space>'] = { { n = vim.lsp.completion.get, i = vim.lsp.completion.get }, 'Trigger Suggestion', { cmd = 'LspSuggestions' } },
      ['<D-M-Space>'] = { { n = lsp.signature_help, i = lsp.signature_help }, 'Signature Hints', { cmd = 'LspSignatureHelp' } },
      ['<D-d>'] = { { n = pick.diagnostics_buffer, i = pick.diagnostics_buffer, v = pick.diagnostics_buffer }, 'Toggle Problems (Local)', { cmd = 'LspToggleDiagnostics' } },
      ['<D-S-d>'] = { { n = pick.diagnostics, i = pick.diagnostics, v = pick.diagnostics }, 'Toggle Problems (Global)', { cmd = 'LspToggleDiagnosticsGlobal' } },
      ['<D-r>'] = { { n = lsp.symbols, i = lsp.symbols, v = lsp.symbols }, 'Document Symbols', { cmd = 'ToggleSymbols' } },
      ['<D-S-r>'] = { { n = lsp.workspace_symbols, i = lsp.workspace_symbols, v = lsp.workspace_symbols }, 'Workspace Symbols', { cmd = 'LspToggleSymbolsWorkspace' } },
      ['<D-i>'] = { { n = lsp.definitions, i = lsp.definitions, v = lsp.definitions }, 'Go to Definition', { cmd = 'GoToDefinition' } },
      ['<D-S-i>'] = { { n = lsp.type_definitions, i = lsp.type_definitions, v = lsp.type_definitions }, 'Find Type Definitions', { cmd = 'LspGoToTypeDefinitions' } },
      ['<D-M-i>'] = { { n = vim.lsp.buf.implementation, i = vim.lsp.buf.implementation, v = vim.lsp.buf.implementation }, 'Go to Implementation', { cmd = 'LspGoToImplementation' } },
      ['<D-S-M-i>'] = { { n = lsp.implementations, i = lsp.implementations, v = lsp.implementations }, 'Find Implementations', { cmd = 'LspGoToImplementations' } },
      ['<D-M-d>'] = { { n = vim.lsp.buf.declaration, i = vim.lsp.buf.declaration, v = vim.lsp.buf.declaration }, 'Go to Declaration', { cmd = 'LspGoToDeclaration' } },
      ['<D-S-M-d>'] = { { n = lsp.declarations, i = lsp.declarations, v = lsp.declarations }, 'Find Declarations', { cmd = 'LspGoToDeclarations' } },
      ['<D-M-r>'] = { { n = lsp.references, i = lsp.references, v = lsp.references }, 'Find References', { cmd = 'LspGoToReferences' } },
      -- ===========================================================================
      -- DEVELOPMENT
      -- https://github.com/mplusp/nvim-0.12-vim-pack-intro/blob/main/lua/config/keymap.lua
      -- ===========================================================================
      ['<D-S-C-n>'] = { { n = '<CMD>source $MYVIMRC<CR>', i = '<C-O><CMD>source $MYVIMRC<CR>', v = '<ESC><CMD>source $MYVIMRC<CR>' }, 'Reload [N]eovim config (init.lua)', { cmd = 'SourceNeovim' } },
      ['<D-S-C-f>'] = { { n = ev.src_vimrc_file, i = ev.src_vimrc_file, v = ev.src_vimrc_file }, '[R]eload Neovim & current file', { cmd = 'SourceNeovimAndEvalFile' } },
      ['<D-S-C-s>'] = { { n = '<CMD>source %<CR>', i = '<C-O><CMD>source %<CR>', v = '<ESC><CMD>source %<CR>' }, 'Source and evaluate [C]urrent File', { cmd = 'SourceAndEvalFile' } },
      ['<D-S-C-c>'] = { { n = '<CMD>lua vim.api.nvim_exec(vim.api.nvim_get_current_line(), false)<CR>', i = '<C-O><CMD>lua vim.api.nvim_exec(vim.api.nvim_get_current_line(), false)<CR>', v = '<ESC><CMD>lua vim.api.nvim_exec(vim.api.nvim_get_current_line(), false)<CR>' }, 'Evaluate current Line', { cmd = 'EvalLine' } },
      ['<D-S-C-v>'] = { { v = '"vy<CMD>lua vim.api.nvim_exec(@v, false)<CR>' }, 'Evaluate current Visual Selection', { cmd = 'EvalSelection' } },
    }
  end)
end)()
