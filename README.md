# Dotfiles

These files are the configuration for a Linux computer.
They contain the configuration for bash, git, vim and Claude Code.
They also contain a record of the installed software.

## Installation

1. Install git.
2. Get the files:

   ```bash
   git clone git@github.com:eladzlot/dotfiles.git ~/projects/dotfiles
   ```

3. Go to the new directory:

   ```bash
   cd ~/projects/dotfiles
   ```

4. Start the installation:

   ```bash
   make all
   ```

The `make all` command makes the symbolic links, installs the vim plugins,
and installs the software.

## Commands

| Command | Result |
|:---|:---|
| `make` | Shows the list of commands. |
| `make all` | Does the three steps below. |
| `make link` | Makes the symbolic links only. |
| `make vim` | Installs the vim plugins only. |
| `make pkgs` | Installs the missing software only. |
| `make audit` | Shows the missing software. Changes nothing. |

## Symbolic links

The `make link` command makes symbolic links in your home directory.
Each link points to a file in this repository.
Thus you edit the files here, and the changes are immediate.

Most links go to `~/.<name>`.
Some links go to a different location, because the program reads a different
path. For example, git reads `~/.config/git/ignore`.
The file `os/create_symbolic_links.sh` contains the two lists.

## Todo files

Vim gives its own highlighting to each file with the name `todo.md`.
It shows the tasks, the tags and the due dates, and it makes a late date red.
It also adds three keys: `,n` for a new task, `,d` to complete a task,
and `,u` to set a due date.
While typing a task, Enter starts the next one and Tab shifts it in or out.

For more information, start vim and type `:help todo-md`.

## Software record

The `pkgs` directory contains a record of the installed software:

| File | Content |
|:---|:---|
| `pkgs/apt.txt` | The apt packages. |
| `pkgs/R.txt` | The R packages. |
| `pkgs/manual.md` | The software that you must install manually. |

The `install.sh` script reads these files.
It installs only the missing software.
Thus it is safe to start the script again at any time.

To add an apt package, use the `apti` command in place of `apt install`.
The `apti` command installs the package and adds it to `pkgs/apt.txt`.
This keeps the record correct.

Some software is not in the apt repositories.
The `install.sh` script gets `fnm`, `zoxide` and `delta` from GitHub.
It puts them in `~/.local/bin`.

Read `pkgs/manual.md` for the software that needs your attention.
This includes TeX Live, Zotero and RStudio.

## Configuration for one computer

Two files contain the configuration that applies to one computer only.
Git does not record these files:

- `~/.bash.local`
- `~/.gitconfig.local`

Make these files if you need them.
The bash and git configuration read them automatically.

## License

The code is available under the [MIT license](LICENSE.txt).
