## [Cătălin](https://github.com/alrra)’s dotfiles

These are the base dotfiles that I start with when I set up a
new environment. For more specific local needs I use the `.local`
files described in the [`Local Settings`](#local-settings) section.

## Setup

To setup the dotfiles just run the appropriate snippet in the
terminal:

(:warning: **DO NOT** run the setup snippet if you don't fully
understand [what it does](dotfiles). Seriously, **DON'T**!)

| OS | Snippet |
|:---:|:---|
| OS X | `bash -c "$(curl -LsS https://raw.github.com/eladzlot/dotfiles/master/dotfiles)"` |
| Ubuntu | `bash -c "$(wget -qO - https://raw.github.com/eladzlot/dotfiles/master/dotfiles)"` |

That's it! :sparkles:

The setup process will:

* Download the dotfiles on your computer (by default it will suggest
  `~/projects/dotfiles`)
* Create some additional [directories](os/create_directories.sh)
* [Symlink](os/create_symbolic_links.sh) the
  [git](git),
  [shell](shell), and
  [vim](vim) files
* Install applications / command-line tools for
  [OS X](os/os_x/installs/main.sh) /
  [Ubuntu](os/ubuntu/installs/main.sh)
* Set custom
  [OS X](os/os_x/preferences/main.sh) /
  [Ubuntu](os/ubuntu/preferences/main.sh) preferences
* Install [vim plugins](vim/vim/plugins)

## Update

To update the dotfiles you can either run the [`dotfiles`
script](dotfiles) or, if you want to just update one particular part,
run the appropriate [`os` script](os).

## License

The code is available under the [MIT license](LICENSE.txt).
