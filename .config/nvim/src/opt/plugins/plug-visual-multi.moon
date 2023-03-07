-- Multiple cursors plugin for vim/neovim
-- https://github.com/mg979/vim-visual-multi
-- VM Leader
-- https://github.com/mg979/vim-visual-multi/wiki/Mappings#vm-leader
-- To minimize chances for conflicts, a leader that is specific to VM is defined.
vim.g.VM_leader = '\\'

-- Permanent Mappings
-- https://github.com/mg979/vim-visual-multi/wiki/Mappings
--
--    C-n	              adds a word under cursor, keep pressing to find next occurrence
--    C-Down / C-Up	    start adding cursors downwards/upwards, skipping empty lines
--    S-Right / S-Left	start selecting right or left
--    leader-A	        select all words in the file
--    leader-/	        start regex search
--    leader-\	        add cursor at position
--    C-n	              add the visually selected region (as a new pattern)
--    leader-a	        add the visually selected region (without adding a pattern)
--    leader-f	        find all current search patterns (from the / register)
--    leader-c	        create a column of cursors

-- Customization
-- https://github.com/mg979/vim-visual-multi/wiki/Mappings#customization
vim.g.VM_default_mappings = 0 -- Disable permanent mappings
vim.g.VM_mouse_mappings = 1 -- Enable Mouse mappings
vim.g.VM_maps = {
  ['Move Right']: '<C-Tab>', -- move selection to right
  ['Move Left']: '<C-S-Tab>', -- move selection to left
  ['VM-Add-Cursor-Down']: '<D-A-Down>', -- start selecting down
  ['VM-Add-Cursor-Up']: '<D-A-Up>', -- start selecting up
  ['Find Under']: '<C-n>', -- adds a word under cursor, keep pressing to find next occurrence
  ['Find Subword Under']: '<C-d>', -- adds a word under cursor, keep pressing to find next occurrence
  ['Select Cursor Down']: '<M-C-Down>', -- start selecting down
  ['Select Cursor Up']: '<M-C-Up>', -- start selecting up
  ['Select All']: '\\A', -- select all words in the file
  ['Start Regex Searc']: '\\/', -- start regex search
  ['Add Cursor Down']: '<C-Down>', -- add cursor down
  ['Add Cursor Up']: '<C-Up>', -- add cursor up
  ['Add Cursor At Pos']: '\\\\',
  ['Visual Regex']: '\\/',
  ['Visual All']: '\\A',
  ['Visual Add']: '\\a',
  ['Visual Find']: '\\f',
  ['Visual Cursors']: '\\c',
  ['Erase Regions']: '\\gr',
  -- Mouse Mappings
  -- https://github.com/mg979/vim-visual-multi/wiki/Mappings#mouse-mappings
  ['Mouse Cursor']: '<C-LeftMouse>', -- add cursor at clicked position
  ['Mouse Word']: '<C-RightMouse>', -- select clicked word
  ['Mouse Column']: '<M-C-RightMouse>', -- create column of cursors
  -- Undo and Redo
  -- https://github.com/mg979/vim-visual-multi/wiki/Mappings#undo-and-redo
  -- Allows to undo/redo changes made in VM, and the regions will be restored as well
  ['Undo']: 'u',
  ['Redo']: '<C-r>',
  -- Buffer mappings
  -- https://github.com/mg979/vim-visual-multi/wiki/Mappings#buffer-mappings
  -- After VM has started, buffer mappings become available, and will be unmapped on exit.
  ['Switch Mode']: '<Tab>',
  ['Find Next']: ']',
  ['Find Prev']: '[',
  ['Goto Next']: '}',
  ['Goto Prev']: '{',
  ['Seek Next']: '<C-f>',
  ['Seek Prev']: '<C-b>',
  ['Skip Region']: 'q',
  ['Remove Region']: 'Q',
  ['Invert Direction']: 'o',
  ['Find Operator']: 'm',
  ['Surround']: 'S',
  ['Replace Pattern']: 'R',
  ['Tools Menu']: '\\`',
  ['Show Registers']: '\\"',
  ['Case Setting']: '\\c',
  ['Toggle Whole Word']: '\\w',
  ['Transpose']: '\\t',
  ['Align']: '\\a',
  ['Duplicate']: '\\d',
  ['Rewrite Last Searc']: '\\r',
  ['Merge Regions']: '\\m',
  ['Split Regions']: '\\s',
  ['Remove Last Region']: '\\q',
  ['Visual Subtract']: '\\s',
  ['Case Conversion Men']: '\\C',
  ['Search Menu']: '\\S',
  ['Run Normal']: '\\z',
  ['Run Last Normal']: '\\Z',
  ['Run Visual']: '\\v',
  ['Run Last Visual']: '\\V',
  ['Run Ex']: '\\x',
  ['Run Last Ex']: '\\X',
  ['Run Macro']: '\\@',
  ['Align Char']: '\\<',
  ['Align Regex']: '\\>',
  ['Numbers']: '\\n',
  ['Numbers Append']: '\\N',
  ['Zero Numbers']: '\\0n',
  ['Zero Numbers Appen']: '\\0N',
  ['Shrink']: '\\-',
  ['Enlarge']: '\\+',
  ['Toggle Block']: '\\<BS>',
  ['Toggle Single Regio']: '\\<CR>',
  ['Toggle Multiline']: '\\M'
}
