# Telescope Misc

A collection of telescope listings that might be missing from the official telescope plugin

## Installation

You can use your favorite plugin manager. Here's how you'd do it with [Lazy.nvim](https://github.com/folke/lazy.nvim):

```
{
    "Jeansidharta/telescope-misc.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("telescope").load_extension("telescope-misc")
    end
}
```

Note that you have to load the extension in Telescope.

## Usage

This plugin adds a few telescope subcommands. Here's an example on how to use one of them:

`:Telescope telescope-misc augroup`

All available subcommands are:

- augroup: Lists all defined augroups on current buffer using the `:augroup` command. Available custom keymaps are:
  - `i_C-d` or `n_d`: Deletes the selected augroup
- namespaces: Lists all defined namespaces on current buffer using the `vim.api.nvim_get_namespaces()` command. Available custom keymaps are:
  - `select`: puts the namespace name in the unnamed register (the `"` reg)
- syntax: Lists all defined syntaxes on current buffer using the `:syntax` command. Available custom keymaps are:
  - `i_C-x` or `n_x`: Deletes the selected syntax using `syntax clear`
  - `i_C-r` or `n_r`: Resets the selected syntax using the selected syntax using `syntax reset`
- option: Lists all options using the `vim.api.nvim_get_all_options_info()` function. This will include global, local and buffer options.
- extension: Lists all extensions loaded on telescope. Available custom keymaps are:
  - `select`: When an extension is selected, telescope will show all of it's subcommands. When a subcommand is then selected, the function will ba called.

## Configuration

There is currently no way to configure this plugin. If you want some configuration, open an issue about it :)

## Contributing

All issues and pull requests are welcome
