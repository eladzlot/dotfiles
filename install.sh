#!/usr/bin/env bash
#
# Reconcile this machine with pkgs/*.txt. Safe to re-run: it only ever
# installs what is missing, and does nothing at all when everything matches.
#
#   ./install.sh            install missing apt packages and single-binary tools
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

has_bin() {
    command -v "$1" &> /dev/null || [ -x "$LOCAL_BIN/$1" ]
}

# fnm (node version manager) is not packaged for Ubuntu, so it comes from
# upstream's install script.
#   --skip-shell  don't let it edit the bash config - those files are
#                 symlinks into this repo
#   --install-dir ~/.local/bin, which bash_profile already puts on PATH
install_fnm() {
    if has_bin fnm; then
        printf 'fnm already installed.\n'
        return
    fi
    printf 'Installing fnm...\n'
    curl -fsSL https://fnm.vercel.app/install \
        | bash -s -- --skip-shell --install-dir "$LOCAL_BIN"
}

# Rust single-binary tools, taken straight from their GitHub releases.
#
# Both publish the same asset shape: <name>-<version>-x86_64-unknown-linux-
# musl.tar.gz, with the binary either at the root or one directory down. The
# musl builds are static and run fine on glibc.
#
# Neither is usable from apt: jammy's zoxide is 0.4.3 (2021, predating
# `zoxide import`), and jammy's "delta" is an unrelated 2006 binary-diff tool.
# Their own install scripts are no better - zoxide's detects this machine as
# musl and then refuses, claiming musl isn't packaged, while shipping a musl
# asset.
#
#   $1 owner/repo   $2 binary name (also the asset prefix)
github_binary() {
    local repo="$1" bin="$2" tag ver tmp found

    if has_bin "$bin"; then
        printf '%s already installed.\n' "$bin"
        return
    fi

    # The tag is "0.19.2" for delta but "v0.10.0" for zoxide, while both name
    # the asset without the v. Keep the tag verbatim for the URL path, and a
    # v-stripped copy for the filename.
    tag="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | sed -n 's/.*"tag_name" *: *"\([^"]*\)".*/\1/p')"
    [ -n "$tag" ] || { printf '%s: could not determine latest version\n' "$bin" >&2; return 1; }
    ver="${tag#v}"

    printf 'Installing %s %s...\n' "$bin" "$ver"
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/dl.tar.gz" \
        "https://github.com/$repo/releases/download/${tag}/${bin}-${ver}-x86_64-unknown-linux-musl.tar.gz"
    tar xzf "$tmp/dl.tar.gz" -C "$tmp"

    found="$(find "$tmp" -type f -name "$bin" -perm -u+x -print -quit)"
    [ -n "$found" ] || { printf '%s: binary not found in tarball\n' "$bin" >&2; rm -rf "$tmp"; return 1; }
    install -m755 "$found" "$LOCAL_BIN/$bin"
    rm -rf "$tmp"
}

install_zoxide() {
    local fresh='no'
    has_bin zoxide || fresh='yes'

    github_binary ajeetdsouza/zoxide zoxide

    # Carry over the old z database, but only on a first install - re-importing
    # would double-count every entry.
    if [ "$fresh" = 'yes' ] && [ -r "$HOME/.z" ]; then
        "$LOCAL_BIN/zoxide" import z < "$HOME/.z" && printf 'imported ~/.z into zoxide\n'
    fi
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

            local b
            for b in fnm zoxide delta; do
                printf '%-7s %s\n' "$b:" "$(has_bin "$b" && echo present || echo missing)"
            done

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
            github_binary dandavison/delta delta
            ;;

        *)
            sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 1
            ;;
    esac
}

main "$@"
