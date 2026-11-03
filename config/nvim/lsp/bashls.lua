return {
  cmd = { 'bash-language-server', 'start' },
  filetypes = { 'sh' },
  root_markers = { '.git' },
  settings = {
    bashIde = {
      shellcheckArguments = { '--shell=bash', '--exclude=SC1090', '--exclude=SC1091' },
      shellcheckExternalSources = false,
      shfmt = {
        caseIndent = true,
      },
    },
  },
}
