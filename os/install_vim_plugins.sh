#!/bin/bash

cd "$(dirname "$BASH_SOURCE")" \
    && source 'utils.sh'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

    # Check if `Git` is installed

    if ! cmd_exists 'curl'; then
        print_error 'curl is required, please install it!\n'
        exit 1
    fi

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Install / Update vim plugins

    rm -f ~/.vim/autoload/plug.vim &> /dev/null \
        && curl -fLo ~/.vim/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim &> /dev/null \
        && printf "\n" | vim +PlugInstall +qall 2> /dev/null
        #     └─ simulate the ENTER keypress for
        #        the case where there are warnings
    print_result $? 'Install Vim plugins'

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Index the hand-written help in ~/.vim/doc, so that `:help todo-md`
    # works. vim-plug indexes the help of the plugins it installs, but not
    # this, because it did not install it.

    vim +'helptags ~/.vim/doc' +qall &> /dev/null
    print_result $? 'Index Vim help tags'

}

main
