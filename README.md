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

## Keymaps

Default keymaps:

`<leader>tt` Runst the test under cursor  
`<leader>tl` Re-runs last test, if any  
`<leader>tc` Closes test output buffer

Reassigning keymaps:

Change the default keymaps to your liking like below

```lua
vim.api.nvim_set_keymap("n", "<leader>tt", "<cmd>lua require'runst'.run_test()<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap(
	"n",
	"<leader>tl",
	"<cmd>lua require'runst'.run_last_test()<cr>",
	{ noremap = true, silent = true }
)
vim.api.nvim_set_keymap("n", "<leader>tc", "<cmd>lua require'runst'.close()<cr>", { noremap = true, silent = true })
```
