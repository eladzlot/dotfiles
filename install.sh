#!/usr/bin/env bash
#
# Reconcile this machine with pkgs/*.txt. Safe to re-run: it only ever
# installs what is missing, and does nothing at all when everything matches.
#
#   ./install.sh            install missing apt packages, fnm and zoxide
#   ./install.sh --R        install missing R packages (slow)
#   ./install.sh --audit    report drift, change nothing
#
# Third-party apt repos must exist first - see pkgs/manual.md.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Manifest lines are "name  # optional comment"; strip comments and blanks.
manifest() {
    sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "$1"
}

missing_apt() {
    local pkg
    while read -r pkg; do
        dpkg -s "$pkg" &> /dev/null || printf '%s\n' "$pkg"
    done < <(manifest pkgs/apt.txt)
}

missing_R() {
    # One R startup for the whole list rather than one per package.
    Rscript -e 'p <- commandArgs(TRUE); cat(setdiff(p, rownames(installed.packages())), sep="\n")' \
        $(manifest pkgs/R.txt) 2> /dev/null
}

# Single-binary tools apt does not carry, installed into ~/.local/bin
# (already on PATH via bash_profile).
declare -r LOCAL_BIN="$HOME/.local/bin"

# fnm (node version manager) is not packaged for Ubuntu, so it comes from
# upstream's install script.
#   --skip-shell  don't let it edit the bash config - those files are
#                 symlinks into this repo
#   --install-dir ~/.local/bin, which bash_profile already puts on PATH
has_fnm() {
    command -v fnm &> /dev/null || [ -x "$LOCAL_BIN/fnm" ]
}

install_fnm() {
    if has_fnm; then
        printf 'fnm already installed.\n'
        return
    fi
    printf 'Installing fnm...\n'
    curl -fsSL https://fnm.vercel.app/install \
        | bash -s -- --skip-shell --install-dir "$LOCAL_BIN"
}

# zoxide. Ubuntu 22.04 only has 0.4.3 (2021), too old for `zoxide import`,
# so take the current static binary from upstream instead.
#
# Not using upstream's install.sh: it detects this machine as musl and then
# refuses, claiming musl isn't packaged - while shipping a musl asset. Pull
# the tarball directly. The musl build is static and runs fine on glibc.
has_zoxide() {
    command -v zoxide &> /dev/null || [ -x "$LOCAL_BIN/zoxide" ]
}

install_zoxide() {
    if has_zoxide; then
        printf 'zoxide already installed.\n'
        return
    fi

    local ver tmp
    ver="$(curl -fsSL https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest \
        | sed -n 's/.*"tag_name" *: *"v\([^"]*\)".*/\1/p')"
    [ -n "$ver" ] || { printf 'zoxide: could not determine latest version\n' >&2; return 1; }

    printf 'Installing zoxide %s...\n' "$ver"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/z.tar.gz" \
        "https://github.com/ajeetdsouza/zoxide/releases/download/v${ver}/zoxide-${ver}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "$tmp/z.tar.gz" -C "$tmp"
    install -m755 "$tmp/zoxide" "$LOCAL_BIN/zoxide"
    rm -rf "$tmp"

    # Carry over the old z database if it's still around.
    [ -r "$HOME/.z" ] && "$LOCAL_BIN/zoxide" import z < "$HOME/.z" && \
        printf 'imported ~/.z into zoxide\n'
}

main() {
    local mode="${1:-apt}"

    case "$mode" in
        --audit)
            local apt_missing R_missing
            apt_missing="$(missing_apt)"
            printf 'apt: %s missing\n' "$(grep -c . <<< "$apt_missing" || true)"
            [ -n "$apt_missing" ] && sed 's/^/  /' <<< "$apt_missing"

            if command -v Rscript &> /dev/null; then
                R_missing="$(missing_R)"
                printf 'R:   %s missing\n' "$(grep -c . <<< "$R_missing" || true)"
                [ -n "$R_missing" ] && sed 's/^/  /' <<< "$R_missing"
            else
                printf 'R:   skipped (no Rscript)\n'
            fi

            printf 'fnm:    %s\n' "$(has_fnm && echo present || echo missing)"
            printf 'zoxide: %s\n' "$(has_zoxide && echo present || echo missing)"

            printf '\nHand-installed things are not audited - see pkgs/manual.md\n'
            ;;

        --R)
            local pkgs
            pkgs="$(missing_R)"
            if [ -z "$pkgs" ]; then
                printf 'R packages already up to date.\n'
                return
            fi
            printf 'Installing R packages: %s\n' "$(tr '\n' ' ' <<< "$pkgs")"
            Rscript -e 'install.packages(commandArgs(TRUE))' $pkgs
            ;;

        apt)
            local pkgs
            pkgs="$(missing_apt)"
            if [ -z "$pkgs" ]; then
                printf 'apt packages already up to date.\n'
            else
                printf 'Installing: %s\n' "$(tr '\n' ' ' <<< "$pkgs")"
                # shellcheck disable=SC2086
                sudo apt install -y $pkgs
            fi
            install_fnm
            install_zoxide
            ;;

        *)
            sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 1
            ;;
    esac
}

main "$@"
