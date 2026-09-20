" Load the editor half of the TPM-managed vim-tmux-navigator plugin.
let s:czsh_navigator = expand('~/.config/czsh/tmux/plugins/vim-tmux-navigator')
if isdirectory(s:czsh_navigator) && !exists('g:loaded_tmux_navigator')
  execute 'set runtimepath^=' . fnameescape(s:czsh_navigator)
  runtime plugin/tmux_navigator.vim
endif
unlet s:czsh_navigator
