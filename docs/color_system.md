# Color System

Paper defines the shared palette and semantic mappings for manually themed tools.
Application configurations own runtime mappings; this document owns reusable color
meaning, not an inventory of installed applications. Removing a consumer does not
remove its tokens or mappings. Changes to tokens, meanings, or retained variants
require an explicit color-system decision under `COLOR-001` in `docs/contracts.md`.

## Application Rules

- Select a light appearance and use warm Paper surfaces with black primary text.
  Reserve the ambient backdrop for login, empty, or locked desktop space.
- Match semantic roles rather than similarly named options. Apply supported roles;
  leave unsupported roles unset. Specific mappings below take precedence over
  general defaults, and retained variants must be selected intentionally.
- Preserve exact RGB tokens in truecolor output. For ANSI-only controls, use the
  nearest ANSI mapping. Do not substitute syntax accents for the terminal palette
  or introduce new colors as an implementation shortcut.
- Keep important text high contrast. Use secondary or tertiary ink for readable
  metadata, disabled ink for low-emphasis UI, and inverse ink on strong dark
  surfaces. Background-only controls use background tokens; do not use fill tokens
  such as selection, search, or chrome as foreground colors.
- Keep broad surfaces Paper-colored. Use accents for syntax, identity, focus,
  selection, search, diagnostics, and other meaningful attention states.
- Use bold for active or high-attention UI and deliberate structure, including
  headings and the roles specified below. Avoid italics unless required by the
  target's syntax role. In tables, `none` means no color override or normal style;
  it does not mean transparent replacement.

## Core Palette

| Token | Hex | Role |
|---|---:|---|
| `paper.canvas` | `#f2eede` | Main background |
| `paper.float` | `#eee8d5` | Popup and floating surfaces |
| `paper.gutter` | `#e8e1cc` | Editor gutter and current-line surfaces |
| `paper.subtle` | `#d8d0b8` | Subtle structural surface |
| `paper.chrome` | `#c8c3b3` | Inactive chrome |
| `paper.chromeActive` | `#b8ad94` | Active chrome |
| `ambient.backdrop` | `#706957` | Login, empty, or locked desktop backdrop |
| `ink.primary` | `#000000` | Primary text |
| `ink.secondary` | `#303030` | Secondary text |
| `ink.tertiary` | `#555555` | Muted terminal foreground and secondary UI text |
| `ink.border` | `#777777` | Separators, borders, and guides |
| `ink.disabled` | `#aaaaaa` | Muted terminal white, disabled text, and low-emphasis borders |
| `ink.inverse` | `#ffffff` | Text on strong dark backgrounds |

## Accent Palette

| Token | Hex | Role |
|---|---:|---|
| `accent.blue` | `#1e6fcc` | Blue ANSI and technical metadata |
| `accent.go` | `#006f8a` | Darkened Gopher Blue for Go identity and navigation accents |
| `accent.green` | `#216609` | Success, strings, and Node.js |
| `accent.yellow` | `#b58900` | Warning base and Python |
| `accent.orange` | `#a55000` | Git state, Rust, and macro-like syntax |
| `accent.red` | `#cc3e28` | ANSI red and syntax error base |
| `accent.magenta` | `#5c21a5` | Directories and magenta ANSI |
| `accent.cyan` | `#158c86` | Cyan ANSI, Kubernetes, functions, properties, and links |
| `accent.comment` | `#2f5f8f` | Comments and CLI highlights |
| `accent.commentStrong` | `#254a70` | Strong comments |

## State Palette

| Token | Hex | Role |
|---|---:|---|
| `state.selection` | `#b7c9dc` | Standard selection and passive attention |
| `state.search` | `#ffd400` | Search and command messages |
| `state.searchActive` | `#9f3a30` | Active search and strong danger |
| `state.infoFg` | `#3f5f2a` | Informational diagnostic text |
| `state.infoBg` | `#d8e4c8` | Informational diagnostic background |
| `state.warnFg` | `#7a3f00` | Warning diagnostic text |
| `state.warnBg` | `#f2de91` | Warning diagnostic background |
| `state.errorBg` | `#7f1d1d` | Severe error background; also error text on light surfaces |
| `state.diffAdd` | `#c5d9b8` | Added diff background |
| `state.diffChange` | `#ffd866` | Changed diff background |
| `state.diffText` | `#ffb454` | Focused changed diff text |
| `state.diffDelete` | `#9f3a30` | Strong deleted diff background |
| `state.diffDeleteSoft` | `#ffebe9` | Syntax-safe deleted diff background |

## Supplemental Palette

These existing Paper colors retain their original names. Their preservation does
not require assigning them to every new theme. The two unassigned colors remain
available without inventing a diagnostic or selection meaning for them.

| Token | Hex | Role |
|---|---:|---|
| `lbackground` | `#f7f3e3` | Lighter paper color; no prescribed mapping |
| `lgreen` | `#dfeacc` | Light green color; no prescribed mapping |
| `lgrey1` | `#d8d5c7` | Soft editor cursor background |
| `lgrey2` | `#bfbcaf` | Neutral editor tab background |

## Terminal ANSI Palette

These slots preserve the original Paper accents. Bright colors match normal
colors except for bright black. Some have low contrast on `paper.canvas`;
truecolor syntax renderers use explicit semantic mappings instead of changing
this shared palette.

| Index | Token | Hex | Contrast on `paper.canvas` | Role |
|---:|---|---:|---:|---|
| 0 | `terminal.black` | `#000000` | 18.06 | ANSI black |
| 1 | `terminal.red` | `#cc3e28` | 4.21 | ANSI red |
| 2 | `terminal.green` | `#216609` | 6.08 | ANSI green |
| 3 | `terminal.yellow` | `#b58900` | 2.76 | ANSI yellow |
| 4 | `terminal.blue` | `#1e6fcc` | 4.30 | ANSI blue |
| 5 | `terminal.magenta` | `#5c21a5` | 8.15 | ANSI magenta |
| 6 | `terminal.cyan` | `#158c86` | 3.52 | ANSI cyan |
| 7 | `terminal.white` | `#aaaaaa` | 2.00 | ANSI white |
| 8 | `terminal.brightBlack` | `#555555` | 6.41 | ANSI bright black / dim text |
| 9 | `terminal.brightRed` | `#cc3e28` | 4.21 | ANSI bright red |
| 10 | `terminal.brightGreen` | `#216609` | 6.08 | ANSI bright green |
| 11 | `terminal.brightYellow` | `#b58900` | 2.76 | ANSI bright yellow |
| 12 | `terminal.brightBlue` | `#1e6fcc` | 4.30 | ANSI bright blue |
| 13 | `terminal.brightMagenta` | `#5c21a5` | 8.15 | ANSI bright magenta |
| 14 | `terminal.brightCyan` | `#158c86` | 3.52 | ANSI bright cyan |
| 15 | `terminal.brightWhite` | `#aaaaaa` | 2.00 | ANSI bright white |

## Opacity and Overlays

Keep terminal backgrounds and full-window Paper surfaces opaque. A transient
overlay may retain a token's exact RGB while reducing its opacity so underlying
content remains visible. This does not replace the base token or authorize a new
RGB color.

Use 50% selection opacity for inactive selections, 40% for selection and symbol
references, 30% for subtle text references, and 60% for stronger references.
Secondary search, line, range, gutter, scrollbar, and chrome overlays may use
50%; an active scrollbar may use 60%. Diff overlays may use 50% for added or
changed lines, 20% for deleted lines, and 40% for deleted text.
Use opaque semantic colors when the target replaces both foreground and
background. Use `state.diffDeleteSoft` when syntax remains visible and an opaque
deletion background is needed.

For hexadecimal alpha, 30%, 40%, 50%, and 60% correspond to `4d`, `66`, `80`, and
`99`; 20% corresponds to `33`. Fully transparent shadows use zero alpha.
Assess contrast against the composited background, not the unblended RGB value.
Use 90% opacity for a floating editor panel, `ee` (approximately 93%) for a
launcher surface, and `dd` (approximately 87%) for a paper indicator over the
ambient backdrop. Do not confuse panel or indicator opacity with terminal
background transparency.

## Semantic Mappings

### Terminals

Map terminal colors directly:

| Tool concept | Token |
|---|---|
| default background | `paper.canvas` |
| default foreground | `ink.primary` |
| cursor text | `paper.canvas` |
| cursor body | `ink.primary` |
| selection text | `ink.primary` |
| selection background | `state.selection` |
| search match text | `ink.primary` |
| search match background | `state.search` |
| focused search text | `ink.inverse` |
| focused search background | `state.searchActive` |
| ANSI normal and bright colors | Terminal ANSI Palette |

#### Terminal Adapter Boundary

Terminal themes must preserve a fixed, opaque Paper surface. Disable automatic
light/dark switching, background transparency, blur, and bold-to-bright palette
remapping when the target exposes those controls.

The mappings include settings that change color interpretation. Glyph rasterization,
gamma, color management, interface structure, and unsupported derived dim colors
are outside this specification. Truecolor output uses the same semantic roles
directly.

### Editors

Use these mappings for text editors and IDEs:

| Editor concept | Foreground | Background | Style |
|---|---|---|---|
| main editor | `ink.primary` | `paper.canvas` | none |
| floating window or popup | `ink.primary` | `paper.float` | none |
| floating or popup border | `ink.border` | `paper.float` | none |
| popup selected row | `ink.primary` | `state.selection` | bold |
| gutter, signs, cursor line | content-dependent | `paper.gutter` | none |
| line numbers | `ink.secondary` | `paper.gutter` | none |
| current line number | `ink.primary` | `paper.chromeActive` | bold |
| color column and folds | `ink.secondary` where needed | `paper.subtle` | folds bold |
| soft editor cursor | inherited | `lgrey1` | none |
| neutral inactive tab | `ink.tertiary` | `lgrey2` | none |
| neutral tab-strip fill | `ink.primary` | `lgrey2` | none |
| neutral active tab | `ink.primary` | `paper.canvas` | bold |
| separators | `ink.border` | none | none |
| outer frame integrated with the gutter | `ink.primary` | `paper.gutter` | none |
| active statusline | `ink.primary` | `paper.chromeActive` | bold |
| inactive statusline | `ink.primary` | `paper.chrome` | none |
| visual selection | `ink.primary` | `state.selection` | none |
| search match | `ink.primary` | `state.search` | bold |
| focused search match | `ink.inverse` | `state.searchActive` | bold |
| matching delimiter | `ink.primary` | `paper.chromeActive` | bold |
| comments | `accent.comment` | none | none |
| strong comments | `accent.commentStrong` | none | bold |

The neutral tab and soft cursor rows are retained variants of chrome-colored tabs
and the black cursor. The color column uses only `paper.subtle`; fold text uses
secondary ink in bold, while the fold column uses the same colors at normal weight.
Directories and type-like navigation use `accent.magenta`.

Richer syntax renderers use the following roles without requiring every editor to
add language-specific rules:

| Syntax role | Foreground | Style |
|---|---|---|
| strings | `accent.green` | normal |
| numbers and highlighted constants | `accent.blue` | normal |
| keywords and storage | `ink.primary` | bold |
| operators and punctuation | `ink.primary` | normal |
| functions and methods | `accent.cyan` | bold |
| types and namespaces | `accent.magenta` | bold |
| properties and attributes | `accent.cyan` | normal |
| readonly variables and enum members | `accent.blue` | normal |
| macros, decorators, and regular expressions | `accent.orange` | normal |
| links | `accent.cyan` | underline |

Diagnostic undercurls may use `accent.red` for errors and `accent.yellow` for
warnings independently of diagnostic text colors. Use `state.warnBg` for a pale
symbol-reference highlight and `ink.border` for an unobtrusive inlay hint.

Ordinary variables may remain `ink.primary`; a more colorful syntax renderer may
use `accent.blue`. Keep that choice explicit instead of treating either variant
as a missing mapping.

### Desktop and Controls

Use `ink.inverse` on `accent.blue` for primary actions and strong focus indicators.
Use `ink.primary` on `state.selection` for selected or urgent items, and
`ink.inverse` on `accent.red` for critical desktop alerts. These compact state
surfaces are deliberate exceptions to avoiding broad accent backgrounds.

Use `ink.primary` on `state.search` for warning and active-mode surfaces, and
`ink.inverse` on `ink.primary` for a compact power or session-ending control.
Muted, disconnected, and unavailable states use `ink.tertiary` without adding a
background. A destructive control may use a Paper background with an
`accent.red` border at rest, then `ink.inverse` on `accent.red` when focused or
hovered. A critical notification may keep its Paper surface and use only the red
border when a filled alert would be too dominant.

Use `ink.border` for ordinary separators, `ink.primary` for strong enclosing
borders, and `ink.disabled` for low-emphasis control borders. An editor frame may
use `paper.chromeActive` borders and `accent.blue` focus outlines. A gutter-colored
outer frame may include title, activity, and ordinary status surfaces; debugging,
warning, and error states keep their own semantic colors. Popups may use either
`paper.float` or an opaque `paper.canvas` panel according to the surrounding UI.

Transparent outer wrappers may expose the owning Paper surface instead of
introducing another panel color. Transparency must not make primary text or
controls depend on an unknown desktop background.

### Launchers and Session Surfaces

| Concept | Foreground | Background or border | Style |
|---|---|---|---|
| launcher surface | `ink.primary` | `paper.canvas` at approximately 93% opacity | none |
| launcher prompt or placeholder | `ink.tertiary` | inherited | none |
| launcher match or focus | `accent.blue` | inherited | none |
| launcher selection | `ink.primary` | `state.selection` | none |
| launcher focus border | none | `accent.blue` | none |
| session backdrop | `paper.canvas` | `ambient.backdrop` | none |
| lock indicator | `ink.primary` | `paper.canvas` at approximately 87% opacity | none |
| lock clear or verification state | `ink.primary` | `state.selection` | none |
| lock input or verification ring | none | `accent.blue` | none |
| lock failure state | `ink.inverse` | `accent.red` | none |

Text directly on the ambient backdrop uses `paper.canvas`. Paper panels on that
backdrop reset their text to `ink.primary` to preserve form readability.

Keep unused lock lines and separators fully transparent. Use `ink.tertiary` for
the neutral ring, `accent.red` for rejected input and backspace feedback, and
`accent.blue` for accepted input feedback.

### Media and Annotation

Readable subtitles may use opaque `ink.inverse` text over a 70% `ink.primary`
per-line box. Keep the separate background and shadow transparent when the box
provides the contrast. This black-and-white overlay is a legibility exception for
video content rather than a Paper application surface.

Use opaque `accent.red` as the default drawing or annotation color when the tool
exposes only one custom color.

### Diagnostics

| Diagnostic concept | Foreground | Background | Style |
|---|---|---|---|
| info text or sign | `state.infoFg` | none | none |
| warning text or sign | `state.warnFg` | none | bold |
| error text or sign | `state.errorBg` | none | bold |
| info float or virtual text | `ink.primary` | `state.infoBg` | none |
| warning float or virtual text | `ink.primary` | `state.warnBg` | float bold, virtual text normal |
| error float or virtual text | `ink.inverse` | `state.errorBg` | float bold, virtual text normal |

### Diffs

| Diff concept | Foreground | Background | Style |
|---|---|---|---|
| added lines | `ink.primary` | `state.diffAdd` | none |
| changed lines | `ink.primary` | `state.diffChange` | none |
| deleted lines | `ink.inverse` | `state.diffDelete` | none |
| focused changed text | `ink.primary` | `state.diffText` | bold |
| deleted lines with syntax-colored text | `ink.primary` | `state.diffDeleteSoft` | none |

Syntax overlays may replace the base foreground on deleted lines. The light
deletion background preserves readability in that case. Changed syntax-diff
tokens may be bold while a whole changed-line surface remains normal weight.

### Prompt, Status, and CLI Tools

Use `paper.chrome` for inactive prompt/status blocks and `paper.chromeActive`
for the active or identity-defining block. Use `ink.primary` for text on both.
Use `ink.secondary` for time, metadata, and unselected items.
Use `state.selection` for passive background-task attention, and `ink.primary`
on `state.search` for command messages.

In a shell prompt, use ANSI red (`31`) for a failed exit status and bold ANSI
black (`1;30`) for path and connection context, then reset the attributes. This
assumes bold text does not remap to the bright ANSI palette.

Use `state.searchActive` with `ink.inverse` for root, read-only, destructive,
or high-risk states. Use `accent.orange` for git state, `accent.cyan` for
Kubernetes or cluster context, `accent.blue` for Docker or technical metadata,
and `accent.comment` for fuzzy-finder prompts and highlights.

For fuzzy finders, prefer `paper.canvas` as the base background,
`state.selection` for the selected row, `paper.chromeActive` for borders, and
`accent.comment` for prompt, pointer, marker, and match highlights.

Use `accent.go` for navigation accents such as the current directory, table
columns, and key chords. File permissions may use `accent.green` for type,
`accent.yellow` for read, `accent.red` for write, and `accent.cyan` for execute.

For GNU file listings, use bold `terminal.blue` for directories and writable or
sticky directories, `terminal.cyan` for symbolic links, and `terminal.green` for
executables. Shell scripts, Java files, and archives use `terminal.red`; Rust,
TOML, and YAML use `terminal.yellow`; C and C++ sources use `terminal.blue`; and
headers and JSON use `terminal.cyan`.

Retain `LSCOLORS=gxfxcxdxbxegedabagacad` as the BSD `ls` color mapping for tools
that accept that format. It is a color reference, not a platform-support or shell
configuration requirement.
