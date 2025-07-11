return {
  -- Yanky | Yank history
  -- https://lazyvim.org/extras/coding/yanky#yankynvim-1
  {
    "gbprod/yanky.nvim",
    keys = {
      -- stylua: ignore
      { "y",         "<Plug>(YankyYank)",      mode = { "n", "x" }, desc = "Yank Text" },
      { "p",         "<Plug>(YankyPutAfter)",  mode = { "n", "x" }, desc = "Put Text After Cursor" },
      { "P",         "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Cursor" },
      -- disable the default keymaps
      { "<leader>p", mode = { "n", "x" },      false },
      { "gp",        mode = { "n", "x" },      false },
      { "gP",        mode = { "n", "x" },      false },
      { "[y",        mode = { "n", "x" },      false },
      { "]y",        mode = { "n", "x" },      false },
      { "]p",        mode = { "n", "x" },      false },
      { "[p",        mode = { "n", "x" },      false },
      { "]P",        mode = { "n", "x" },      false },
      { "[P",        mode = { "n", "x" },      false },
      { ">p",        mode = { "n", "x" },      false },
      { "<p",        mode = { "n", "x" },      false },
      { ">P",        mode = { "n", "x" },      false },
      { "<P",        mode = { "n", "x" },      false },
      { "=p",        mode = { "n", "x" },      false },
      { "=P",        mode = { "n", "x" },      false },
    },
  },

  -- Todo Comments | Todo comments
  -- https://github.com/folke/todo-comments.nvim
  {
    "folke/todo-comments.nvim",
    keys = {
      -- disable the default keymaps
      { "<leader>st", mode = { "n", "x" }, false },
      { "<leader>sT", mode = { "n", "x" }, false },
    },
  },

  -- WhichKey | A popup that displays available keybindings in Neovim
  -- https://github.com/folke/which-key.nvim
  {
    "folke/which-key.nvim",
    keys = {
      -- disable the default keymaps
      { "<leader><tab>", mode = { "n", "v" }, false },
      { "<leader>d",     mode = { "n", "v" }, false },
      { "<leader>dp",    mode = { "n", "v" }, false },
      { "<leader>f",     mode = { "n", "v" }, false },
      { "<leader>g",     mode = { "n", "v" }, false },
      { "<leader>gh",    mode = { "n", "v" }, false },
      { "<leader>q",     mode = { "n", "v" }, false },
      { "<leader>s",     mode = { "n", "v" }, false },
      { "<leader>u",     mode = { "n", "v" }, false },
      { "<leader>x",     mode = { "n", "v" }, false },
      { "<leader>b",     mode = { "n", "v" }, false },
      { "<leader>w",     mode = { "n", "v" }, false },
      { "<c-w><space>",  mode = { "n", "v" }, false },
      { "<leader>?",     mode = { "n", "v" }, false },
      { "gx",            mode = { "n", "v" }, false },
      { "[",             mode = { "n", "v" }, false },
      { "]",             mode = { "n", "v" }, false },
      { "g",             mode = { "n", "v" }, false },
      { "gs",            mode = { "n", "v" }, false },
      { "z",             mode = { "n", "v" }, false },
    },
  },

  -- Mini Comment |
  -- https://github.com/echasnovski/mini.nvim/blob/main/doc/mini-comment.txt
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    dependencies = {
      -- Neovim treesitter plugin for setting the commentstring based on the cursor location in a file.
      -- https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#minicomment
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = {
          enable_autocmd = false,
        },
      },
    },
    opts = {
      options = {
        custom_commentstring = function()
          return require("ts_context_commentstring").calculate_commentstring() or vim.bo.commentstring
        end,
      },
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Toggle comment (like `gcip` - comment inner paragraph) for both
        -- Normal and Visual modes
        comment = "<D-/>",

        -- Toggle comment on current line
        comment_line = "<D-/>",

        -- Toggle comment on visual selection
        comment_visual = "<D-/>",

        -- Define 'comment' textobject (like `dgc` - delete whole comment block)
        -- Works also in Visual mode if mapping differs from `comment_visual`
        textobject = "<D-/>",
      },
    },
  },

  -- Fzf-Lua | Improved fzf.vim written in lua
  -- https://github.com/ibhagwan/fzf-lua | https://lazyvim.org/extras/editor/fzf
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    cmd = "FzfLua",
    dependencies = { "echasnovski/mini.icons" },
  },
}
