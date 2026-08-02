#!/bin/bash
#
# Shared helpers for the scripts in this directory.
#
# This file used to carry a much larger toolkit, most of which existed for the
# tarball-bootstrap flow (ask_for_sudo, get_os, is_git_repository, mkd, ...).
# That flow is gone - the repo is cloned with git now - so only what
# create_symbolic_links.sh and install_vim_plugins.sh call is left.

answer_is_yes() {
    [[ "$REPLY" =~ ^[Yy]$ ]] \
        && return 0 \
        || return 1
}

ask_for_confirmation() {
    print_question "$1 (y/n) "
    read -n 1
    printf "\n"
}

cmd_exists() {
    command -v "$1" &> /dev/null
    return $?
}

execute() {
    eval "$1" &> /dev/null
    print_result $? "${2:-$1}"
}

print_in_green() {
    printf "\e[0;32m$1\e[0m"
}

print_in_red() {
    printf "\e[0;31m$1\e[0m"
}

print_in_yellow() {
    printf "\e[0;33m$1\e[0m"
}

print_error() {
    print_in_red "  [✖] $1 $2\n"
}

print_question() {
    print_in_yellow "  [?] $1"
}

print_success() {
    print_in_green "  [✔] $1\n"
}

print_result() {
    [ $1 -eq 0 ] \
        && print_success "$2" \
        || print_error "$2"

    return $1
}
