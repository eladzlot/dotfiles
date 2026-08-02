## [Elad's](https://github.com/eladzlot) dotfiles

These are the base dotfiles that I start with when I set up a
new environment. For anything machine-specific I use `.local` files
(`~/.bash.local`, `~/.gitconfig.local`), which are sourced if present
and are not under version control.

These are heavily based on [Cătălin’s dotfiles](https://github.com/alrra/dotfiles).

## Setup

To setup the dotfiles just run the appropriate snippet in the
terminal:

(:warning: **DO NOT** run the setup snippet if you don't fully
understand [what it does](dotfiles). Seriously, **DON'T**!)

```bash
bash -c "$(curl -LsS https://raw.githubusercontent.com/eladzlot/dotfiles/master/dotfiles)"
```

That's it! :sparkles:

The setup process will:

* Download the dotfiles on your computer (by default it will suggest
  `~/projects/dotfiles`)
* [Symlink](os/create_symbolic_links.sh) the
  [git](git),
  [shell](shell), and
  [vim](vim) files
* Install [vim plugins](vim/vim/plugins)

## Update

To update the dotfiles you can either run the [`dotfiles`
script](dotfiles) or, if you want to just update one particular part,
run the appropriate [`os` script](os).

## Installed tools

[`pkgs/`](pkgs) records what is installed on the machine, and
[`install.sh`](install.sh) reconciles the machine with it. Both are safe to
re-run - they only ever install what is missing.

```bash
./install.sh --audit   # what's recorded but not installed?
./install.sh           # install missing apt packages
./install.sh --R       # install missing R packages (slow)
```

Add apt packages with the `apti` shell function rather than `apt install`,
so installing and recording stay the same action. Anything that doesn't come
from apt - TeX Live, Zotero, RStudio, the apt repos themselves - is written
down in [`pkgs/manual.md`](pkgs/manual.md).

## License

The code is available under the [MIT license](LICENSE.txt).
