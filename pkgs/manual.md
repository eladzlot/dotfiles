# Things that don't come from `apt.txt`

Everything here needs hands. Keep it honest: if a step can't be automated,
write down enough that future-you can redo it without guessing.

## apt repositories (add these *before* running install.sh)

`apt.txt` assumes these are configured. Without them, R, Chrome and VS Code
either won't resolve or will install a stale version.

```bash
# R (newer than what Ubuntu 22.04 ships) and R packages as apt packages
sudo add-apt-repository ppa:marutter/rrutter4.0
sudo add-apt-repository ppa:c2d4u.team/c2d4u4.0+

# Google Chrome
wget -qO- https://dl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
http://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list

# VS Code - see https://code.visualstudio.com/docs/setup/linux
```

## TeX Live

**Not from apt.** Installed from the upstream installer to
`/usr/local/texlive/2024`, which is why `shell/bash_profile` hardcodes that
path. https://tug.org/texlive/quickinstall.html

Re-run the installer each year and bump the year in `bash_profile`.

## Zotero

Installed to `/opt/zotero` via the community deb repo:

```bash
wget -qO- https://raw.githubusercontent.com/retorquere/zotero-deb/master/install.sh | sudo bash
sudo apt update && sudo apt install zotero
```

Then install **Better BibTeX** by hand (Tools → Add-ons):
https://retorque.re/zotero-better-bibtex/

BBT is what exports `~/projects/zettlr/zotero.json`, which `bin/render` and
the vim citation completion both read. Nothing works without it.

## RStudio

Direct `.deb` download, no repo. Grab the current one rather than a pinned
URL: https://posit.co/download/rstudio-desktop/

## Node

`fnm` is installed by `install.sh` (upstream script, not packaged for
Ubuntu) into `~/.local/bin`, which is already on PATH.

It is deliberately **not** wired into shell startup - no `fnm env` in
`bash_profile` - so it costs nothing per shell. Run `fnm use <version>` in a
shell when you need a specific node.

Node currently still comes from the `bin/nvm` submodule, which is pinned to
2020 and costs ~300ms of shell startup. Swapping the two is a separate job:
`fnm install 24 && fnm default 24`, then drop the nvm lines from
`bash_profile` and deinit the submodule.

## R version

This box runs **R 4.1.2** (Ubuntu's own build) even though the marutter PPA
is configured and offers **4.6.1**. Consequences: some current CRAN packages
refuse to install - `MuMIn` needs R >= 4.4.

Upgrading is not just `apt install r-base`. R keeps its user library under a
version-specific path (`~/R/x86_64-pc-linux-gnu-library/4.1`), so a jump to
4.6 starts from an empty library and all ~260 installed packages need
reinstalling - several of which compile from source. Worth setting aside
time for rather than doing incidentally.

## Non-CRAN R packages

```r
remotes::install_github("rmcelreath/rethinking")
install.packages("cmdstanr", repos = c("https://stan-dev.r-universe.dev"))
```

## Apache serving ~/www

`apache2` is in `apt.txt`, but pointing it at `~/www` is manual:

```bash
mkdir -p ~/www
sudo chgrp -R www-data ~/www
chmod -R 750 ~/www
sudo sed -i "s|/var/www/html|$HOME/www|g" \
    /etc/apache2/sites-available/000-default.conf \
    /etc/apache2/sites-available/default-ssl.conf
```

Then append to `/etc/apache2/apache2.conf` (as root - a plain `sudo cat >>`
redirects as *your* user and silently fails, which is what the old
startup.sh got wrong):

```
<Directory /home/eladzlot/www>
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
```

```bash
sudo systemctl enable --now apache2
```

## Chrome extensions

Install from the Web Store; the old scripted-policy approach was more
trouble than four clicks.

- AdBlock Plus
- LastPass
- Google Scholar Button
- Zotero Connector

## Flatpak

```bash
flatpak install flathub com.spotify.Client
```

## HUJI VPN

`f5vpn` — deb from the university, not publicly mirrored. Re-download from
the HUJI IT pages when it breaks.
