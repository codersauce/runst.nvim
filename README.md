# runst.nvim

Run rust tests from Neovim with one key mapping.

## Features

- Run test under cursor
- Repeat last test run
- Display test results in a dedicated read-only buffer

## Status

This plugin is in early stages. Right now it only uses simple heuristics to determine the full cargo test command
for the line under cursor.

The idea is to expand this and maybe even leverage [rust-analyzer](https://rust-analyzer.github.io/)'s [runnables](https://github.com/rust-lang/rust-analyzer/blob/master/crates/ide/src/runnables.rs#L195).

## Installation

Use your favorite package manager:

```lua
-- lazy.nvim
{
    "codersauce/runst.nvim",
    lazy = false,
    opts = {},
    config = function()
        require("runst").setup()
    end
}
```

```lua
-- packer.nvim
use({
    "codersauce/runst.nvim",
    config = function()
        require("runst").setup()
    end
})
```
