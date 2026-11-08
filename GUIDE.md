# Using this Neovim

A guide to this config specifically: the keys it adds, the plugins it loads,
and the places where it changes Vim's normal behavior. Generic Vim knowledge
lives in `:help` and `:Tutor`. This covers what's particular to this setup.

Every key in this guide was checked against a running copy of the config
(Neovim 0.12, November 2026). If a key here doesn't work, run
`:verbose map <key>` to see what it's bound to and which file bound it.

## Contents

1. [The basics: leader, commands, finding keys](#1-the-basics)
2. [Changes to normal Vim behavior](#2-changes-to-normal-vim-behavior)
3. [Editing](#3-editing)
4. [Files: the tree](#4-files-the-tree)
5. [Running code](#5-running-code)
6. [Completion and the language server](#6-completion-and-the-language-server)
7. [Git](#7-git)
8. [Jupyter notebooks](#8-jupyter-notebooks)
9. [Images, video and PDFs](#9-images-video-and-pdfs)
10. [AI chat (gp.nvim)](#10-ai-chat-gpnvim)
11. [What's in this repo](#11-whats-in-this-repo)

---

## 1. The basics

### The leader key is Space

Many keys in this guide start with `<leader>`. The leader is a prefix key for
your own commands, so they don't clash with Vim's built-in keys. This config
sets it to **Space** (top of `init.lua`), so `<leader>gd` means: tap Space,
tap `g`, tap `d`. Press them one after another, not together. You have one
second between keys before Neovim gives up and treats the Space as an
ordinary keypress.

Space makes a good leader because its normal job (move right one character)
duplicates `l`. Ctrl can't be a leader: it's a modifier, and the terminal
never sends Ctrl on its own.

### Every key has a command version

Most keys in this guide run a `:Command`. When the command is easier to
remember, use it:

- **Tab completion.** Type `:Diffv` and press Tab to cycle through the
  matching commands. Many commands also complete their arguments, such as
  branch names after `:DiffviewOpen `.
- **History search.** Type the start of a command, such as `:Diffv`, then
  press **Up**. Neovim steps back through earlier commands that start with
  that text.
- **Running a normal-mode key as a command.** `:normal zR` runs `zR`.
  `:windo normal zR` runs it in every window of the tab.

### Finding out what a key does

| Command | Shows |
|---|---|
| `:map <leader>` | every leader mapping |
| `:verbose map ]c` | what `]c` does here, and which file set it |
| `:nmap` / `:imap` / `:vmap` | mappings for normal / insert / visual mode |
| `g?` | the key list, inside nvim-tree, diffview and fugitive |

Mappings can be **buffer-local**, meaning they only exist in certain files.
`]c` means "next git hunk" in a normal file but "next cell" in a notebook.
`:verbose map` always tells you which one applies in the current buffer.

---

## 2. Changes to normal Vim behavior

These keys do something different from stock Vim. Tutorials and Stack
Overflow answers will assume the stock behavior, so this is the list to check
when something "doesn't work like the docs say".

| Key | Stock Vim | Here |
|---|---|---|
| `Ctrl-D` | scroll half a page down | **runs the current Python file** ([§5](#5-running-code)) |
| `Ctrl-T` | jump back in the tag stack | **toggles the file tree** ([§4](#4-files-the-tree)) |
| `Ctrl-Q` | same as `Ctrl-V` | **closes the run/build pane** |
| `E` (Shift-e) | jump to end of WORD | **shows the error under the cursor** |
| `Tab` / `Shift-Tab` in visual mode | nothing useful | indent / outdent, keeping the selection |
| `Tab` in insert mode with the menu open | inserts a tab | **accepts the completion** |
| `Enter` in a notebook (normal mode) | move down a line | **runs the cell** |

Scrolling still works with `Ctrl-U` (half page up), `Ctrl-F` / `Ctrl-B` (full
page), and `Ctrl-E` / `Ctrl-Y` (one line).

**Ctrl-Shift keys need a modern terminal.** `Ctrl-Shift-B` and `Ctrl-Shift-G`
only work in a terminal that speaks the Kitty keyboard protocol, such as
Kitty or Ghostty. Older terminals send them as plain `Ctrl-B` / `Ctrl-G`.

---

## 3. Editing

| Key | Mode | Action |
|---|---|---|
| `Ctrl-/` | normal | comment / uncomment this line |
| `Ctrl-/` | visual | comment / uncomment the selection |
| `gcc`, `gc{motion}` | normal | the same, built into Neovim (`gcap` = comment paragraph) |
| `Tab` / `Shift-Tab` | visual | indent / outdent and keep the selection, so you can press it again |
| `[<Space>` / `]<Space>` | normal | add an empty line above / below without moving |

Brackets and quotes close automatically (nvim-autopairs). In XML and HTML,
typing `<tag>` adds the `</tag>`, and renaming an opening tag renames its
closing tag (nvim-ts-autotag).

The clipboard is shared with the system (`clipboard=unnamedplus`): `y` copies
to the system clipboard, and `p` pastes from it.

### Multiple cursors (vim-visual-multi)

| Key | Action |
|---|---|
| `Ctrl-N` | select the word under the cursor; press again to add the next match |
| `n` / `N` | (while selecting) add the next / previous match |
| `q` | skip this match and go to the next one |
| `Q` | remove the current cursor |
| `Ctrl-Down` / `Ctrl-Up` | add a cursor on the line below / above |
| `\\A` | select every match of the word in the file |
| `Esc` | back to one cursor |

Once you have several cursors, edit normally: `c`, `i`, `a` and `d` act at
every cursor. This plugin's leader is `\\` (two backslashes), not Space.

---

## 4. Files: the tree

Opening `nvim` with no file, or on a directory (`nvim .`), opens the tree on
the left automatically.

| Key | Action |
|---|---|
| `Ctrl-T` | show / hide the tree (from a file window) |

Inside the tree:

| Key | Action |
|---|---|
| `Enter` or `o` | open file / expand folder |
| `Ctrl-V` / `Ctrl-X` | open in a vertical / horizontal split |
| `a` | create a file (end the name with `/` for a folder) |
| `r` | rename |
| `d` | delete |
| `x` / `c` / `p` | cut / copy / paste |
| `y` / `gy` | copy the file name / full path |
| `H` | show / hide dotfiles |
| `I` | show / hide git-ignored files |
| `f` / `F` | filter by name / clear the filter |
| `W` / `E` | collapse / expand everything |
| `-` | move the tree root up a folder |
| `Ctrl-]` | make the folder under the cursor the root |
| `R` | refresh |
| `q` | close the tree |
| `g?` | all tree keys |

> **Gotcha:** inside the tree, `Ctrl-T` doesn't hide the tree. nvim-tree uses
> it for "open in a new tab". Close the tree with `q`, or move to a file window
> first (`Ctrl-W l`) and press `Ctrl-T` there.

---

## 5. Running code

Both runners open a terminal pane at the bottom. Running again reuses that
pane instead of stacking new ones.

| Key | Action |
|---|---|
| `Ctrl-D` | save, then run the current file with Python |
| `Ctrl-Shift-B` | run `./build.sh` from Neovim's working directory |
| `Ctrl-Q` | close the run/build pane and stop its process (works from inside the pane too) |

**Which Python runs:** `vim.g.project_python_path` if you've set it, otherwise
the active conda env (`$CONDA_PREFIX/bin/python`), otherwise `python3`.
Activate the conda env **before** starting `nvim`. The language server uses
the same rule to find your packages.

`Ctrl-D` leaves you in the terminal in insert mode, so a script waiting for
input gets your typing. To scroll the output, press `Ctrl-\ Ctrl-N` to switch
the pane to normal mode, then move as usual.

The build pane runs `./build.sh` relative to Neovim's working directory, not
the current file. Check it with `:pwd` and change it with `:cd`.

---

## 6. Completion and the language server

### The completion menu

The menu appears as you type, one character in.

| Key | Action |
|---|---|
| `Tab` or `Enter` | accept the selected item |
| `Shift-Tab` | select the previous item |
| `Ctrl-N` / `Ctrl-P` | next / previous item |
| `Ctrl-E` | close the menu without accepting |
| `Ctrl-S` | show the function signature (insert mode) |

When you type a function's name, a signature popup shows its parameters
(lsp_signature).

Accepting an override suggestion while typing `def …` inserts just the method
name, not pyright's multi-line stub. That's on purpose (the `entry_filter` in
the cmp setup).

### Language server keys

These are Neovim's built-in LSP keys. They work in any file with a language
server: Python (pyright), C/C++ (clangd), Rust (rust-analyzer), TOML (taplo)
and XML (lemminx).

| Key | Action |
|---|---|
| `K` | documentation for the thing under the cursor |
| `Ctrl-]` | go to definition (`Ctrl-O` to come back) |
| `grr` | list references |
| `grn` | rename everywhere |
| `gra` | code actions (quick fixes) |
| `gri` | go to implementation |
| `grt` | go to type definition |
| `gO` | list the symbols in this file |
| `E` | show the error / warning under the cursor in a popup |
| `]d` / `[d` | next / previous diagnostic |
| `]D` / `[D` | last / first diagnostic |
| `:LspRestart` | restart the language servers for this file |

Diagnostics update while you type (`update_in_insert`), so errors show up
before you leave insert mode.

### The Python server

Python uses pyright with background analysis, which keeps completion at about
70 ms even in torch/transformers code. The details, and why it took four
pieces to get working, are in the comments of the Python block in `init.lua`.
To switch servers, set `NVIM_PYTHON_LS` when you start Neovim:

```sh
NVIM_PYTHON_LS=pyright-plain nvim file.py   # stock pyright: rollback if something breaks
NVIM_PYTHON_LS=basedpyright nvim file.py    # for comparison
```

If completion feels slow or errors stop appearing, measure before changing
settings:

```sh
~/.config/nvim/bench/run.sh path/to/file.py <conda-env>
```

`bench/README.md` explains the output. A `TIMEOUT` on the diagnostics line
means errors have stopped working, even if completion looks fast. That's the
expected symptom if a Mason update to pyright breaks `pyright-bg.js`.

---

## 7. Git

Three plugins cover git, each at a different scale:

| Tool | Scope | Use it for |
|---|---|---|
| gitsigns | one change in the file you're editing | stage or revert one hunk, preview, blame |
| diffview | every changed file, side by side | review before committing, compare branches, history |
| fugitive | the whole repo | status, commit, push, any `git` command |

### Hunks in the file you're editing (gitsigns)

The left column marks lines added, changed or deleted since the last commit.
These keys only exist in files tracked by git.

| Key | Mode | Action |
|---|---|---|
| `]c` / `[c` | normal | next / previous hunk |
| `<leader>gp` | normal | preview the hunk: popup of the old version |
| `<leader>ga` | normal | stage the hunk (press again to unstage) |
| `<leader>ga` | visual | stage only the selected lines |
| `<leader>gr` | normal | revert the hunk to the last commit |
| `<leader>gr` | visual | revert only the selected lines |
| `<leader>gR` | normal | revert the whole file |
| `<leader>gb` | normal | blame: who changed this line, in which commit |

A revert is undoable: `u` brings the change back, as long as you haven't
closed the file.

To revert part of a hunk, select the lines you want gone with `V`, then press
`<leader>gr`.

### Reviewing changes side by side (diffview)

```vim
:DiffviewOpen                     " uncommitted changes          <leader>gd
:DiffviewOpen main...HEAD         " what my branch adds (PR view)
:DiffviewOpen main...feature      " what feature adds
:DiffviewOpen main..feature       " exact difference between the two tips
:DiffviewOpen main                " main vs. my files on disk
:DiffviewClose                    "                              <leader>gc
```

`<leader>gD` asks for the revision at a prompt and runs `:DiffviewOpen` with
it.

**Two dots or three?** `main...feature` (three) shows only what `feature`
changed since it split off from `main`, which is what a pull request shows.
`main..feature` (two) shows the exact difference between the two branches
right now. If `main` has moved on, everything new on `main` also appears,
reversed, as though your branch had deleted it. Use three dots unless you
really want the snapshot comparison.

**Editing while you review:** add `--imply-local`, as in
`:DiffviewOpen main...HEAD --imply-local`. Your side of the diff becomes the
real file on disk, so the language server, completion and `:w` all work in
it. Without the flag, both sides are read-only copies.

Colors: green is added, red is deleted, and amber is a changed line, with the
changed words in brighter amber. (The amber is set in the tokyonight block of
`init.lua`; the theme's own color for changed lines was nearly invisible.)

Inside diffview:

| Key | Action |
|---|---|
| `Tab` / `Shift-Tab` | next / previous file |
| `]c` / `[c` | next / previous change in this file |
| `[F` / `]F` | first / last file |
| `<leader>e` | jump to the file list |
| `<leader>b` | show / hide the file list |
| `gf` | open this file in a normal window |
| `]x` / `[x` | next / previous merge conflict |
| `g?` | every diffview key |

In the file list:

| Key | Action |
|---|---|
| `Enter` or `o` | open that file's diff |
| `-` or `s` | stage / unstage the file |
| `S` / `U` | stage all / unstage all |
| `X` | restore the file to the left-hand version (discards changes) |
| `R` | refresh |

**Where did the rest of the file go?** The unchanged parts are folded, not
missing. Each fold shows as a line like `+-- 142 lines`. To see the whole
file:

| Key | Command | Action |
|---|---|---|
| `zR` | `:%foldopen!` | open all folds |
| `zM` | `:%foldclose` | close all folds |
| `zo` / `zc` | `:foldopen` / `:foldclose` | open / close the fold here |
| `za` | | toggle the fold here |
| `zi` | `:set foldenable!` | turn folding on / off for the window |
| | `:windo set nofoldenable` | whole file in **both** panes at once |

The keys only affect the window the cursor is in. Use the `:windo` form to
change both sides of the diff.

### History

```vim
:DiffviewFileHistory %                       " this file's commits       <leader>gh
:DiffviewFileHistory                         " the whole repo's commits  <leader>gH
:DiffviewFileHistory --range=main...HEAD     " just my branch's commits
```

Choose a commit to see its diff. `L` shows the commit message and details.
`X` restores the file to how it was in that commit.

### Status and commits (fugitive)

`:Git` (or `<leader>gs`) opens a status window. Move to a file and press:

| Key | Action |
|---|---|
| `s` / `u` | stage / unstage the file (or hunk) under the cursor |
| `-` | toggle staged |
| `U` | unstage everything |
| `=` | show the diff inline (on a hunk inside it, `s` stages that hunk) |
| `dv` | side-by-side diff of this file |
| `X` | discard the change under the cursor |
| `o` | open the file in a split |
| `cc` | commit (write the message, then `:wq`) |
| `ca` | amend the last commit and edit its message |
| `ce` | amend the last commit, keep its message |
| `gq` | close the status window |
| `g?` | every key |

Any git command also works as `:Git <args>`: `:Git push`, `:Git log --oneline`,
`:Git checkout -b feature`, `:Git blame`.

---

## 8. Jupyter notebooks

Opening a `.ipynb` file loads it as a buffer of cells (nvim-jupyter, your
own plugin at `~/rustprojects/neovim-jupyter`). `:w` saves it back to
`.ipynb`. Output appears under each cell. This needs a terminal with the
Kitty graphics protocol (Kitty or Ghostty).

| Key | Mode | Action |
|---|---|---|
| `Enter` | normal | run the cell |
| `Ctrl-Enter` | normal / insert | run the cell |
| `Shift-Enter` | normal / insert | run the cell and move to the next (adds one at the end) |
| `Alt-Enter` | normal / insert | run the cell and add a new one below |
| `]c` / `[c` | normal | next / previous cell |
| `<leader>b` / `<leader>a` | normal | add a cell below / above |
| `<leader>d` | normal | delete the cell |
| `<leader>m` | normal | toggle code / markdown |

Ghostty uses `Ctrl-Enter` itself by default. Use `Enter` or `Shift-Enter`
there, or unbind it in Ghostty's settings.

| Command | Action |
|---|---|
| `:JupyterKernel` | pick the kernel |
| `:JupyterRunAll` | run every cell |
| `:JupyterRunAbove` / `:JupyterRunBelow` | run every cell above / below |
| `:JupyterInterrupt` | stop a running cell (like Ctrl-C) |
| `:JupyterRestartKernel` | restart the kernel |
| `:JupyterKernelStatus` | is the kernel busy or idle? |
| `:JupyterClearOutput` / `:JupyterClearAll` | clear this cell's / every cell's output |
| `:JupyterShowOutput` | full output of this cell in a split |
| `:JupyterHover` | kernel's documentation for the name under the cursor |
| `:JupyterBuild` | rebuild the Rust backend |

`:JupyterRun…` and `:JupyterExecute…` are the same commands under two names.

> **In notebooks, `]c` means cells, not git hunks.** Notebook buffers don't
> get the gitsigns keys or a language server, so for a notebook's git
> changes, use `:DiffviewOpen` or `:Git`.

---

## 9. Images, video and PDFs

Opening an image (png, jpg, webp), video (mp4, mkv, webm, mov, avi, m4v) or
PDF shows it in Neovim (nvim-gfx, from your neovim-graphics-viewer repo). You
can also open one from the tree, or with `:ViewImage path/to/file`.

| Key | Image | PDF | Video |
|---|---|---|---|
| `q` | close | close | close |
| `+` or `=` / `-` | zoom in / out | zoom in / out | zoom in / out |
| `h j k l` or arrows | pan | pan | seek: `h`/`l` 1 s, `j`/`k` 10 s |
| `r` | reset view | reset view | rewind to start |
| `J` / `K` (or PgDn / PgUp) | | next / previous page | |
| `gg` / `G` | | first / last page | |
| `p` or Space | | | play / pause |

`:NvimGfxBuild` rebuilds the viewer's Rust binary.

---

## 10. AI chat (gp.nvim)

Needs `OPENAI_API_KEY` set in the shell you start `nvim` from.

| Key / command | Action |
|---|---|
| `Ctrl-Shift-G` | open / close the chat in a split |
| `:GpChatNew` | start a new chat |
| `:GpChatFinder` | search old chats |

Inside a chat buffer, type under the last `💬:` line, then:

| Key | Action |
|---|---|
| `Ctrl-G Ctrl-G` | send |
| `Ctrl-G s` | stop the response |
| `Ctrl-G c` | new chat |
| `Ctrl-G d` | delete this chat |

The commands that work on code take a visual selection. Select lines with `V`,
then type `:` and the command:

| Command | Action |
|---|---|
| `:GpRewrite` | asks for an instruction, then replaces the selection |
| `:GpAppend` / `:GpPrepend` | adds the response after / before the selection |
| `:GpImplement` | treats the selection's comments as instructions and writes the code |
| `:GpChatPaste` | pastes the selection into the chat |
| `:GpNextAgent` | switches the model / agent |
| `:GpStop` | stops any running response |

---

## 11. What's in this repo

| File | What it is |
|---|---|
| `init.lua` | everything: options, keys, plugin list (lazy.nvim), LSP setup |
| `python_runner.lua` | `Ctrl-D` runner |
| `build.lua` | `Ctrl-Shift-B` runner |
| `runner_close.lua` | `Ctrl-Q`, closes either runner |
| `pyright-bg.js` | launcher that makes pyright's background analysis work under Mason ([§6](#the-python-server)) |
| `bench/` | completion and diagnostics speed benchmark |
| `lazy-lock.json` | exact plugin versions (gitignored) |
| `GUIDE.md` | this file |

**Plugins** are installed by lazy.nvim. `:Lazy` shows them; in that window,
`U` updates and `S` syncs. **Language servers** are installed by Mason, and
`:Mason` manages them. After updating pyright through Mason, run the bench
once (see [§6](#the-python-server)).

**Rolling back.** The config is a git repo, so `git log` and `git checkout`
work on it as on any other. Commit before a big change, and you can always
return to that point.
