" Neovim's built-in CSV matches take precedence over Rainbow CSV's column matches.
if !exists(':RainbowDelim')
  finish
endif

for s:column in range(0, 8)
  execute 'syntax clear csvCol' . s:column
  execute 'syntax clear escCsvCol' . s:column
endfor
unlet s:column
