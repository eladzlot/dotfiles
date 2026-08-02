#!/usr/bin/env bash
#
# Reconcile this machine with pkgs/*.txt. Safe to re-run: it only ever
# installs what is missing, and does nothing at all when everything matches.
#
#   ./install.sh            install missing apt packages, and fnm
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

# fnm (node version manager) isn't packaged for Ubuntu, so it comes from
# upstream's install script.
#   --skip-shell  don't let it edit the bash config - those files are
#                 symlinks into this repo
#   --install-dir ~/.local/bin, which bash_profile already puts on PATH
declare -r FNM_DIR="$HOME/.local/bin"

has_fnm() {
    command -v fnm &> /dev/null || [ -x "$FNM_DIR/fnm" ]
}

install_fnm() {
    if has_fnm; then
        printf 'fnm already installed.\n'
        return
    fi
    printf 'Installing fnm...\n'
    curl -fsSL https://fnm.vercel.app/install \
        | bash -s -- --skip-shell --install-dir "$FNM_DIR"
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

            printf 'fnm: %s\n' "$(has_fnm && echo present || echo missing)"

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
            ;;

        *)
            sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
            exit 1
            ;;
    esac
}

main "$@"
