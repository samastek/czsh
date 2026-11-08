" Ctrl+h/j/k/l moves between Vim splits and, at the edge of Vim, on to the
" neighbouring tmux pane. dotfiles/tmux.conf holds the tmux half.
if exists('g:loaded_czsh_navigator')
  finish
endif
let g:loaded_czsh_navigator = 1

function! s:Navigate(direction) abort
  let l:window = winnr()
  execute 'wincmd ' . a:direction
  if winnr() == l:window && !empty($TMUX)
    call system('tmux select-pane -' . tr(a:direction, 'hjkl', 'LDUR'))
  endif
endfunction

for s:key in ['h', 'j', 'k', 'l']
  execute printf('nnoremap <silent> <C-%s> :<C-u>call <SID>Navigate(''%s'')<CR>', s:key, s:key)
endfor
