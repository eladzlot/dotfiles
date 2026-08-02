.DEFAULT_GOAL := help
.PHONY: all help link vim pkgs audit

## all: link the config files, install the vim plugins and the packages
all: link vim pkgs

## link: symlink the config files into $HOME
link:
	@./os/create_symbolic_links.sh

## vim: install and update the vim plugins
vim:
	@./os/install_vim_plugins.sh

## pkgs: install the apt packages and single-binary tools that are missing
pkgs:
	@./install.sh

## audit: report what is recorded but not installed; change nothing
audit:
	@./install.sh --audit

## help: show this list
help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | awk -F': ' '{printf "  make %-7s %s\n", $$1, $$2}'
