# rosetta.nvim

**rosetta.nvim** is a tool for polyglots.

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
      rtl = false, -- Default text direction is LTR
   },
   module = {
      bidi = {
         enabled = true,
         user_commands = true, -- Generate usercommands for bidi functions
         revert_before_saving = true, -- Disable bidi-mode before saving buffer contents.
         auto_switch_keyboard = true, -- Automatically switch to the correct RTL language.
      },
      keyboard = {
         enabled = true,
         user_commands = true, -- Generate usercommands for keyboard functions.
         silent = false, -- Notify the user when keyboard is switched.
      },
   },
   lang = {}, -- Place language instances here. (See 'Usage' for an example.)
})
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
   },
}
```

## Usage

By default, Rosetta creates usercommands for easy switching.

## Bidi

| Command        | Action                                                                            |
|----------------|-----------------------------------------------------------------------------------|
| `:BidiDisable` | Disable Bidi mode for current buffer.                                             |
| `:BidiEnable`  | Enable Bidi mode for current buffer.                                              |
| `:BidiConvert` | Run buffer contents through `fribidi`. This will toggle bidi mode back and forth. |

**NOTE: When bidi mode is enabled, the buffer will still save in non-bidi mode.**
Use `:BidiConvert` before saving to write buffer contents.

## Keyboard

| Command             | Action                                                                      |
|---------------------|-----------------------------------------------------------------------------|
| `:Keyboard<lang>`   | Activate keyboard for the indicated language.                               |
| `:KeyboardMappings` | View mappings for current keyboard. (Nothing happens for default keyboard.) |
| `:KeyboardReset`    | Reset to default keyboard. (Equivalent to `set keymap=`.)                   |

## See an problem?

Feel free to open an issue!

## Have a suggestion?

Feel free to open a discussion.
Once a matter is settled, PRs are always welcome.