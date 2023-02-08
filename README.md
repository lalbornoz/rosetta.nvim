# rosetta.nvim

A tool for polyglots and bidirectional writers.

## Introduction

Rosetta is a tool born like most things—from two parents.
You can meet them if
you'd like.
Ah, here they come.
This is
**the-common-usage-of-greek-and-hebrew-in-biblical-studies**,
and this is
**the-increasing-rage-over-the-fact-that-emacs-has-bidi-support-and-neovim-does-not**.
You can really see Rosetta in both of them!

* * *

That pretty much sums it up. I love neovim and use it daily in my research and writing,
but the lack of good language management, especially bidirectional text, made it difficult to get stuff done.
So I did what most (neo)vimmers do.
Instead of looking for a different tool, I made a plugin.

## Features

- Seamless **bidirectional (bidi) text manipulation** in Neovim using [fribidi](fribidi/fribidi).
- Convenient **keyboard/keymap manager** for all your language needs.

## Requirements

- Neovim
- [fribidi](https://github.com/fribidi/fribidi) command-line tool
- A terminal/GUI *with RTL capabilities disabled*

## Installation

Download and install with your favorite package manager.

```lua
-- e.g., Packer
use({ "mcookly/rosetta.nvim" })
```

Then call

```lua
require("rosetta").setup()
```

somewhere in your `init` file.

## Configuration

Here the defaults.

```lua
require("rosetta").setup({
   options = {
      default = "english", -- Default language
   },
   bidi = {
      enabled = true,
      user_commands = true, -- Generate usercommands for bidi functions
      register = "b", -- Register which will paste bidi content.
      revert_before_saving = true, -- Disable bidi-mode before saving buffer contents.
   },
   keyboard = {
      enabled = true,
      user_commands = true, -- Generate usercommands for keyboard functions
      intuitive_delete = true, -- Swap `Delete` and `Backspace` keys in insert mode for RTL languages.
      silent = false, -- Notify the user when keyboard is switched.
   },
   lang = {  -- Place language instances here.
      english = {
         keymap = "",
         rtl = false,
         unicode_range = { "0020-007F" },
      },
   }
}
```

Languages can be configured like so:

```lua
lang = {
   greek = {
      keymap = "greek_utf-8", -- This name is identical to the one in `set keymap=`
      rtl = false,
      unicode_range = { "0370-03FF", "1F00-1FFF" }, -- Multiple ranges can be added for one language.
   },
   hebrew = { -- Keyboard commands are created for each language automatically if `user_commands` are enabled.
      keymap = "hebrew_utf-8",
      rtl = true,
      unicode_range = { "0590-05FF" },
      options = { -- `vim.o` options can be passed through here.
         delcombine = true,
      }
   },
}
```

## Usage

By default, Rosetta creates usercommands for easy switching.

## Bidi

| Command             | Action                                                                            |
|---------------------|-----------------------------------------------------------------------------------|
| `:BidiDisable`      | Do not display bidi text in current buffer using default base direction.          |
| `:BidiEnable`       | Display bidi text in current buffer using default base direction.                 |
| `:BidiDisable<DIR>` | Do not display bidi text in current buffer using `<DIR>` base direction.          | 
| `:BidiEnable<DIR>`  | Display bidi text in current buffer using `<DIR>` base direction.                 |

Rosetta also utilizes a specific register (`b` by default) which will also paste bidi contents yanked into `b`.
To convert some selected text, use `"bd`, `gv`, and `"bp`.
To convert the entire buffer, use `ggVG"bd` followed by `gv` and `"bp`.
I recommend creating a simple keymap for this process:

```lua
-- Bidi selection
vim.keymap.set("v", "<Leader>bc", "\"bygv\"bp", { noremap = true, silent = true })
-- Bidi contents when pasting from system keyboard
vim.keymap.set("n", "<Leader>bp", "\"+p[`v`]\"bdgv\"bp", { noremap = true, silent = true })
```

## Keyboard

| Command                | Action                                                                      |
|------------------------|-----------------------------------------------------------------------------|
| `:Keyboard<LANG>`      | Activate keyboard for the indicated language (and disable auto-switch)      |
| `:KeyboardAutoEnable`  | Auto-switch keyboard depending the language under the cursor.               |
| `:KeyboardAutoDisable` | Disable auto-switch.                                                        |
| `:KeyboardMappings`    | View mappings for current keyboard (if they exist).                         |

## See a problem?

Feel free to open an issue!
Once a matter is settled, PRs are always welcome.

## Have a suggestion?

Feel free to open a discussion!
Once a matter is settled, PRs are always welcome.