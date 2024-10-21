# dual-pane.yazi

[dual-pane.yazi](https://github.com/dawsers/dual-pane.yazi) provides simple
dual pane navigation for [Yazi](https://github.com/sxyazi/yazi/), in a similar
fashion to [Vifm](https://github.com/vifm/vifm) or [Midnight Commander](https://midnight-commander.org/).

## Requirements

- [Yazi nightly build](https://github.com/sxyazi/yazi/releases/tag/nightly) is required ATM.

## Installation

```sh
ya pack -a dawsers/dual-pane
```

Modify your `~/.config/yazi/init.lua` to include:

```lua
require("dual-pane"):setup()
```

## Options

The plugin supports the following options, which can be assigned during setup:

1. `enabled`: If true, the plugin is enabled at yazi's startup. The default value is false.

``` lua
require("dual-pane"):setup({
  enabled = true,
})
``````

## Usage

The plugin needs to overwrite several key bindings to work well.

Choose your own key bindings or use these in your `~/.config/yazi/keymap.toml`:

```toml
[manager]
prepend_keymap = [
    { on = "B", run = "plugin --sync dual-pane --args=toggle", desc = "Dual-pane: toggle" },
    { on = "b", run = "plugin --sync dual-pane --args=toggle_zoom", desc = "Dual-pane: toggle zoom" },
    { on = "<Tab>", run = "tab_switch 1 --relative",  desc = "Dual-pane: switch to the other pane" },
    { on = "[", run = "plugin --sync dual-pane --args='tab_switch -1 --relative'",  desc = "Dual-pane: switch active to previous tab" },
    { on = "]", run = "plugin --sync dual-pane --args='tab_switch 1 --relative'",  desc = "Dual-pane: switch active to next tab" },
    { on = "t", run = "plugin --sync dual-pane --args='tab_create --current'",  desc = "Dual-pane: create a new tab with CWD" },
    { on = "<F5>", run = "plugin --sync dual-pane --args='copy_files --follow'",  desc = "Dual-pane: copy selected files from active to inactive pane" },
    { on = "<F6>", run = "plugin --sync dual-pane --args='move_files --follow'",  desc = "Dual-pane: move selected files from active to inactive pane" },
]
```

### Commands

| Command       | Arguments                       | Description                                                                                                                             |
| ------------- | ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `toggle`      |                                 | Enable/disable dual pane                                                                                                                |
| `toggle_zoom` |                                 | While in dual pane, zoom into the active pane                                                                                           |
| `tab_switch`  | `[n]` and possibly `--relative` | Same as Yazi's `tab_switch`                                                                                                             |
| `tab_create`  | `[path]`, `--current` or none   | Same as Yazi's `tab_create`                                                                                                             |
| `copy_files`  | `--force`, `--follow`           | Arguments like Yazi's `paste`. Copies the selected or hovered file(s) from the current pane to the other one                            |
| `move_files`  | `--force`, `--follow`           | Arguments like Yazi's `paste`. Moves the selected or hovered file(s) from the current pane to the other one, deleting the original ones |

### Tutorial

This short tutorial is based on the key bindings above, but you can create
your own.

When you start Yazi, you can start _dual-pane_ by pressing `B`. It will create
a dual pane view with the current directory on both panes if there is only one
tab open, or the first and second tabs if there are more than one.

`B` will exit _dual-pane_ again (it is a toggle), while pressing `b` will still
keep you in dual pane mode, but zooming the active pane for better visibility.
For example, you could use [toggle-view.yazi](https://github.com/dawsers/toggle-view.yazi)
to toggle on/off the preview or parent directory if you want more details.

`<Tab>` will change the active pane on each press. The header of the active
pane will be colored differently for better visibility.

While in one of the panes, `[` and `]` will move the active tab back and
forth. The tab indicator for each pane will mark the selected one.

`t` will create a new tab with the current directory as _cwd_.

`<F5>` will copy the selected files (or the hovered one if there are none
selected) from the active pane, to the current directory of the other pane.

`<F6>` will move the selected files (or the hovered one if there are none
selected) from the active pane, to the current directory of the other pane.

I also use global _marks_ defined in _keymap.toml_ to navigate quickly to
frequent directories, like this:

```toml
[namager]
prepend_keymap = [
    { on = [ "'", "<Space>" ], run = "cd --interactive",   desc = "Go to a directory interactively" },
    { on = [ "'", "h" ],       run = "cd ~",   desc = "Go to the home directory" },
    { on = [ "'", "c" ],       run = "cd ~/.config",   desc = "Go to the config directory" },
    { on = [ "'", "d" ],       run = "cd ~/Downloads",   desc = "Go to the Downloads directory" },
    { on = [ "'", "D" ],       run = "cd ~/Documents",   desc = "Go to the Documents directory" },
]
```

backward and forward keys like in vim:

```toml
[namager]
prepend_keymap = [
    # Backward/Forward
    { on = "<C-o>", run = "back",    desc = "Go back to the previous directory" },
    { on = "<C-i>", run = "forward", desc = "Go forward to the next directory" },
]
```

[fuse-archive.yazi](https://github.com/dawsers/fuse-archive.yazi)

```toml
[namager]
prepend_keymap = [
    # fuse-archive
    { on   = [ "<Right>" ], run = "plugin fuse-archive --args=mount", desc = "Mount selected archive" },
    { on   = [ "<Left>" ], run = "plugin fuse-archive --args=unmount", desc = "Unmount selected archive" },
]
```

and [toggle-view.yazi](https://github.com/dawsers/toggle-view.yazi)

```toml
[namager]
prepend_keymap = [
    { on = "<C-1>", run = "plugin --sync toggle-view --args=parent", desc = "Toggle parent" },
    { on = "<C-2>", run = "plugin --sync toggle-view --args=current", desc = "Toggle current" },
    { on = "<C-3>", run = "plugin --sync toggle-view --args=preview", desc = "Toggle preview" },
]
```

There may be some incompatibilities between _dual-pane_ and certain plugins or
Yazi commands. The reason is this plugin is not integrated in the core, and needs
to hijack certain procedures to work as seamlessly as possible.

## Additional Plugins for Extended Functionality

[fuse-archive.yazi](https://github.com/dawsers/fuse-archive.yazi) if you want to
navigate compressed archives as if they were part of the file system.

[toggle-view.yazi](https://github.com/dawsers/toggle-view.yazi) to quickly
toggle on/off the parent, current or preview panels.
