set background=light

hi clear

if exists('g:syntax_on')
  syntax reset
endif

let g:colors_name = 'paper-custom'

" Function for creating a highlight group
"
" We use this function so we can use variables in our highlight groups, instead
" of having to repeat the same color codes in a bunch of places.
function! s:Hi(group, fg_name, bg_name, gui, ...)
  if a:fg_name == 'NONE'
    let fg = a:fg_name
  else
    let fg = s:colors[a:fg_name]
  endif

  if a:bg_name == 'NONE'
    let bg = a:bg_name
  else
    let bg = s:colors[a:bg_name]
  endif

  if empty(a:gui)
    let style = 'NONE'
  else
    let style = a:gui
  endif

  if a:0 == 1 && !empty(a:1)
    let sp = s:colors[a:1]
  else
    let sp = 'NONE'
  endif

  exe 'hi ' . a:group . ' guifg=' . fg . ' guibg=' . bg . ' gui=' . style . ' guisp=' . sp
endfunction

" A temporary command is used to make it easier/less verbose to define highlight
" groups. This command is removed at the end of this file.
command! -nargs=+ Hi call s:Hi(<f-args>)

" Available colors
let s:colors = {
\  'background': '#f2eede',
\  'lbackground': '#f7f3e3',
\  'black': '#000000',
\  'blue': '#1e6fcc',
\  'green': '#216609',
\  'lgreen': '#dfeacc',
\  'red': '#cc3e28',
\  'grey': '#777777',
\  'dgrey': '#555555',
\  'lgrey1': '#d8d5c7',
\  'lgrey2': '#bfbcaf',
\  'lgrey3': '#aaaaaa',
\  'yellow': '#b58900',
\  'lyellow': '#f2de91',
\  'orange': '#a55000',
\  'purple': '#5c21a5',
\  'white': '#ffffff',
\  'cyan': '#158c86',
\  'term_red': '#cc3e28',
\  'term_yellow': '#b58900',
\  'term_blue': '#1e6fcc',
\  'term_cyan': '#158c86',
\  'term_white': '#aaaaaa',
\  'term_bright_black': '#555555',
\  'term_bright_red': '#cc3e28',
\  'term_bright_green': '#216609',
\  'term_bright_yellow': '#b58900',
\  'term_bright_blue': '#1e6fcc',
\  'term_bright_magenta': '#5c21a5',
\  'term_bright_cyan': '#158c86',
\  'term_bright_white': '#aaaaaa',
\  'float': '#eee8d5',
\  'gutter': '#e8e1cc',
\  'subtle': '#d8d0b8',
\  'chrome': '#c8c3b3',
\  'chrome_active': '#b8ad94',
\  'secondary': '#303030',
\  'selection': '#b7c9dc',
\  'info_fg': '#3f5f2a',
\  'info_bg': '#d8e4c8',
\  'diff_add': '#c5d9b8',
\  'error_dark': '#7f1d1d',
\  'search_active': '#9f3a30',
\  'search': '#ffd400',
\  'diff_change': '#ffd866',
\  'diff_text': '#ffb454',
\  'warn_fg': '#7a3f00',
\  'comment': '#2f5f8f',
\  'comment_strong': '#254a70'
\ }

" We require/expect true colour support, and make no attempt at supporting UIs
" that don't have true colour support. Terminal ANSI colors remain explicit so
" terminal behavior can be audited separately from editor syntax accents.
if has('nvim')
  let g:terminal_color_0 = s:colors['black']
  let g:terminal_color_1 = s:colors['term_red']
  let g:terminal_color_2 = s:colors['green']
  let g:terminal_color_3 = s:colors['term_yellow']
  let g:terminal_color_4 = s:colors['term_blue']
  let g:terminal_color_5 = s:colors['purple']
  let g:terminal_color_6 = s:colors['term_cyan']
  let g:terminal_color_7 = s:colors['term_white']
  let g:terminal_color_8 = s:colors['term_bright_black']
  let g:terminal_color_9 = s:colors['term_bright_red']
  let g:terminal_color_10 = s:colors['term_bright_green']
  let g:terminal_color_11 = s:colors['term_bright_yellow']
  let g:terminal_color_12 = s:colors['term_bright_blue']
  let g:terminal_color_13 = s:colors['term_bright_magenta']
  let g:terminal_color_14 = s:colors['term_bright_cyan']
  let g:terminal_color_15 = s:colors['term_bright_white']
else
  let g:terminal_ansi_colors = [
  \   s:colors['black'],
  \   s:colors['term_red'],
  \   s:colors['green'],
  \   s:colors['term_yellow'],
  \   s:colors['term_blue'],
  \   s:colors['purple'],
  \   s:colors['term_cyan'],
  \   s:colors['term_white'],
  \   s:colors['term_bright_black'],
  \   s:colors['term_bright_red'],
  \   s:colors['term_bright_green'],
  \   s:colors['term_bright_yellow'],
  \   s:colors['term_bright_blue'],
  \   s:colors['term_bright_magenta'],
  \   s:colors['term_bright_cyan'],
  \   s:colors['term_bright_white']
  \ ]
endif

" Set up all highlight groups.
"
" We use the custom Hi command for this. The syntax of this command is as
" follows:
"
"     Hi NAME FG BG GUI GUISP
"
" Where NAME is the highlight name, FG the foreground color, BG the background
" color, and GUI the settings for the `gui` option (e.g. bold). Since Hi is a
" command and not a function, quotes shouldn't be used. To refer to a color,
" simply use its name (e.g. "black").

" Generic highlight groups
Hi ColorColumn NONE subtle NONE
Hi Comment comment NONE NONE
Hi Conceal NONE NONE NONE
Hi Constant black NONE NONE
Hi Cursor NONE lgrey1 NONE
Hi CursorLine NONE gutter NONE
Hi CursorLineNr black chrome_active bold
Hi Directory purple NONE NONE
Hi ErrorMsg red NONE bold
Hi FoldColumn secondary subtle NONE
Hi Identifier black NONE NONE
Hi Include black NONE bold
Hi Keyword black NONE bold
Hi LineNr secondary gutter NONE
Hi Macro orange NONE NONE
Hi MatchParen black chrome_active bold
Hi MoreMsg black NONE NONE
Hi NonText secondary NONE NONE
Hi Normal black background NONE
Hi NormalFloat black float NONE
Hi Bold black NONE bold
Hi Number blue NONE NONE
Hi Operator black NONE NONE
Hi Pmenu black float NONE
Hi PmenuBorder grey float NONE
Hi PmenuSel black selection bold
Hi PreProc black NONE NONE
Hi Question black NONE NONE
Hi Regexp orange NONE NONE
Hi Search black search bold
Hi IncSearch white search_active bold
Hi Special black NONE NONE
Hi SpellBad red NONE bold,undercurl
Hi SpellCap purple NONE undercurl
Hi SpellLocal green NONE undercurl
Hi SpellRare purple NONE undercurl
Hi StatusLine black chrome_active bold
Hi StatusLineNC black chrome NONE
Hi String green NONE NONE
Hi TabLine dgrey lgrey2 NONE
Hi TabLineFill black lgrey2 NONE
Hi TabLineSel black background bold
Hi Title black NONE bold
Hi Todo grey NONE bold
Hi WarningMsg orange NONE bold
Hi Underlined NONE NONE underline
Hi DiagnosticInfo info_fg NONE NONE
Hi DiagnosticSignInfo info_fg NONE NONE
Hi DiagnosticWarn warn_fg NONE bold
Hi DiagnosticError error_dark NONE bold
Hi FloatBorder grey float NONE
Hi SpecialComment comment_strong NONE bold
Hi SignColumn black gutter NONE
Hi SpecialKey black NONE NONE
Hi Visual black selection NONE
Hi VisualNOS black selection NONE
Hi WinSeparator grey NONE NONE
Hi DiagnosticFloatingInfo black info_bg NONE
Hi DiagnosticFloatingWarn black lyellow bold
Hi DiagnosticFloatingError white error_dark bold
Hi DiagnosticVirtualTextInfo black info_bg NONE
Hi DiagnosticVirtualTextWarn black lyellow NONE
Hi DiagnosticVirtualTextError white error_dark NONE

hi! link Boolean Keyword
hi! link Character String
hi! link Error ErrorMsg
Hi Folded secondary subtle bold
hi! link Label Keyword
hi! link PmenuThumb PmenuSel
hi! link PreCondit Macro
hi! link Statement Keyword
hi! link StorageClass Keyword
hi! link Type Keyword
hi! link WildMenu PmenuSel
hi! link VertSplit WinSeparator

" LSP
Hi DiagnosticUnderlineError NONE NONE undercurl red
Hi DiagnosticUnderlineWarn NONE NONE undercurl yellow
Hi LspReferenceText NONE lyellow NONE
Hi LspInlayHint grey NONE NONE

" netrw
hi! link netrwClassify Identifier

" Git commit messages
hi! link gitCommitOverflow ErrorMsg
hi! link gitCommitSummary String

" Diffs
Hi DiffAdd black diff_add NONE
Hi DiffChange black diff_change NONE
Hi DiffDelete white search_active NONE
Hi DiffText black diff_text bold
Hi diffFile black NONE bold
Hi diffLine blue NONE NONE
hi! link diffAdded DiffAdd
hi! link diffChanged DiffChange
hi! link diffRemoved DiffDelete

delcommand Hi

" vim: et ts=2 sw=2
