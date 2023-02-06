# rosetta.nvim

**rosetta.nvim** is a tool for polyglots and bidirectional writers.

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
      revert_before_saving = true, -- Disable bidi-mode before saving buffer contents.
   },
   keyboard = {
      enabled = true,
      user_commands = true, -- Generate usercommands for keyboard functions
      auto_switch_keyboard = true, -- Automatically switch to the language under the cursor.
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

| Command        | Action                                                                            |
|----------------|-----------------------------------------------------------------------------------|
| `:BidiDisable` | Display bidi text in current buffer.                                              |
| `:BidiEnable`  | Do not display bidi text in current buffer.                                       |
| `:BidiConvert` | Convert buffer contents to/from bidi.                                             |

Use `:BidiConvert` before saving to write buffer contents as bidi text.

If you load a bidi buffer and run `:BidiEnable`, the display will be incorrect unfortunately.
Just run `:BidiConvert` again to solve this issue.

## Keyboard

| Command             | Action                                                                      |
|---------------------|-----------------------------------------------------------------------------|
| `:Keyboard<lang>`   | Activate keyboard for the indicated language.                               |
| `:KeyboardMappings` | View mappings for current keyboard (if they exist).                         |

## See a problem?

Feel free to open an issue!

## Have a suggestion?

Feel free to open a discussion!
Once a matter is settled, PRs are always welcome.