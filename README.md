<img align=left width=175px height=175px
src="https://raw.githubusercontent.com/simnalamburt/i/master/shellder/shellder.png">

shellder
========
1. **No solarized** ― xterm256 colors are beautiful enough
2. **Speed** ― Carefully optimized for slow environments like MSYS2

&nbsp;

![screenshot image of shellder](https://raw.githubusercontent.com/simnalamburt/i/master/shellder/screenshot.png)

Installation
------------
You can install shellder via various plugin managers.

### Fish, [fisher]
```yaml
# ~/.config/fish/fish_plugins
psafont/shellder
```

### Fish, [chips]
```yaml
# ~/.config/chips/plugin.yaml
github:
- psafont/shellder
```

&nbsp;

Configuration
-------

To control path shrinking in fish shell, set `fish_prompt_pwd_dir_length` or `fish_prompt_pwd_full_dirs` environment variable. See [prompt_pwd](https://fishshell.com/docs/current/cmds/prompt_pwd.html) for the further details.

&nbsp;

## Fonts
You'll need a powerline patched font. If you don't have one, download one or
patch some fonts on you own.

- https://github.com/powerline/fonts
- https://github.com/ryanoasis/nerd-fonts

&nbsp;

--------
*shellder* is primarily distributed under the terms of both the [MIT license]
and the [Apache License (Version 2.0)]. See [COPYRIGHT] for details.

[fisher]: https://github.com/oh-my-fish/oh-my-fish
[chips]: https://github.com/xtendo-org/chips
[MIT license]: LICENSE-MIT
[Apache License (Version 2.0)]: LICENSE-APACHE
[COPYRIGHT]: COPYRIGHT
