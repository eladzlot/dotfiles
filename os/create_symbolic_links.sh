#!/bin/bash

cd "$(dirname "$BASH_SOURCE")" \
    && source 'utils.sh'

declare -a FILES_TO_SYMLINK=(

    'shell/bash_aliases'
    'shell/bash_exports'
    'shell/bash_functions'
    'shell/bash_logout'
    'shell/bash_options'
    'shell/bash_profile'
    'shell/bash_prompt'
    'shell/bashrc'
    'shell/curlrc'
    'shell/inputrc'
    'shell/dircolors'

    'git/gitconfig'

    'vim/vim'
    'vim/vimrc'
)

# Links whose target isn't ~/.<basename>, as 'source:target-under-$HOME'.
#
# git only reads a per-user ignore/attributes file from ~/.config/git/, or
# from wherever core.excludesFile / core.attributesFile point. The old
# ~/.gitignore and ~/.gitattributes symlinks were never read by anything.
declare -a NESTED_SYMLINKS=(

    'git/gitignore:.config/git/ignore'
    'git/gitattributes:.config/git/attributes'

    'claude/settings.json:.claude/settings.json'
    'claude/CLAUDE.md:.claude/CLAUDE.md'
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

link_file() {

    local sourceFile="$1"
    local targetFile="$2"

    mkdir -p "$(dirname "$targetFile")"

    if [ ! -e "$targetFile" ]; then
        execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
    elif [ "$(readlink "$targetFile")" == "$sourceFile" ]; then
        print_success "$targetFile → $sourceFile"
    else
        ask_for_confirmation "'$targetFile' already exists, do you want to overwrite it?"
        if answer_is_yes; then
            rm -rf "$targetFile"
            execute "ln -fs $sourceFile $targetFile" "$targetFile → $sourceFile"
        else
            print_error "$targetFile → $sourceFile"
        fi
    fi

}

main() {

    local i=''
    local rootDir="$(cd .. && pwd)"

    for i in ${FILES_TO_SYMLINK[@]}; do
        link_file "$rootDir/$i" "$HOME/.$(basename "$i")"
    done

    for i in ${NESTED_SYMLINKS[@]}; do
        link_file "$rootDir/${i%%:*}" "$HOME/${i##*:}"
    done

}

main
