vim.cmd[[
" Enable spellchecking
setlocal spell

" Automatically wrap at 80 characters
setlocal textwidth=80

" Markdown Writing and Previewing in Neovim
" https://jdhao.github.io/2019/01/15/markdown_edit_preview_nvim/
augroup pandoc_syntax
  au! BufNewFile,BufFilePre,BufRead *.md set filetype=markdown.pandoc
augroup END
]]
