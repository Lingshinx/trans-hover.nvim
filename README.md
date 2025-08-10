# Trans-Hover.nvim

A simple translate plugin just for fun
show translation via lsp.hover

## Installation

```lua
return {
  "Lingshinx/trans-hover.nvim"
  opts = true,
  cmd = { "Trans", "TransToggle" },
  dependencies = { "folke/noice.nvim" }, -- optional
  keys = {
    { "<leader>ut", "<cmd>TransToggle<CR>", desc = "toggle trans" },
  },
}
```
