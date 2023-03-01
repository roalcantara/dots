#!/usr/bin/env bash
override BRANCH 			:= main
override HOSTNAME 			:= NCC1701
override DOTS_REPO 			:= https://github.com/roalcantara/dots
override DOTS_TARGET 		:= ~/.git
override XDG_CONFIG_HOME 	:= ~/.config
override XDG_CONFIG_BAK 	:= ~/.config.bak
override OS_NAME            := $(shell uname -s | tr '[:upper:]' '[:lower:]')

SHELL 						= /bin/bash
DOTS 	 					= $(/usr/bin/git --git-dir="$(DOTS_TARGET)" --work-tree="$(HOME)")
BACKUP 						= $(mkdir -p $(XDG_CONFIG_BAK) && $(DOTS) checkout 2>&1 | grep -E '\s+\.' | awk '{ print $1 }' | xargs -I{} mv {} $(XDG_CONFIG_BAK)/{})
SOFTWARE_UPDATE 			= $(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')

is_darwin 					:= $(filter $(OS_NAME),darwin)
is_linux 					:= $(filter $(OS_NAME),linux)
OS   						:= $(if $(is_darwin),darwin,$(if $(is_linux),debian,alpine))

HOMEBREW_PREFIX 			:= $(if $(is_linux),~/.linuxbrew,/usr/local)
BREW_BIN 					:= $(if $(is_darwin),$(HOMEBREW_PREFIX)/bin/brew,eval "$(HOMEBREW_PREFIX)/bin/brew shellenv" && $(HOMEBREW_PREFIX)/bin/brew)

.PHONY: default
default:
	@make -s all

.PHONY: all
all: ## List all available tasks
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z\-_0-9%:\/]+:.*?## / {printf "\033[36m%-30s→\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sed s/://

.PHONY: help
help: ## (Fuzzy) Display available tasks
	@make -s all | fzf --cycle | cut -d ' ' -f1 | xargs -r make

.PHONY: puts
puts: ## Echo environment variables
	$(info "OSTYPE => '$(OSTYPE)' ✔")
	$(info "OS_NAME => '$(OS_NAME)' ✔")
	$(info "is_linux => '$(is_linux)' ✔")
	$(info "is_darwin => '$(is_darwin)' ✔")
	@echo "OS => '$(OS)' ✔"

.PHONY: install
install: puts configure/$(OS) $(XDG_CONFIG_HOME) brew/configure ## Install Dotfiles
	$(info "[$(OS)][install] ✔✔")

.PHONY: docker/build
docker/build: ## Buld Dockerfile
	docker build --target dots -t roalcantara/dots $(XDG_CONFIG_HOME)

.PHONY: docker/run
docker/run: ## Run Docker Container roalcantara/dots (docker run -it --rm --hostname dots roalcantara/dots)
	docker compose run --rm dots

.PHONY: docker/serve
docker/serve: ## Run Docker Container roalcantara/dots mounting ~/.config (docker run -it --rm --hostname dots -v ~/.config:/home/linuxbrew/.config roalcantara/dots)
	docker compose run -v $(XDG_CONFIG_HOME):/home/linuxbrew/.config --rm dots

.PHONY: configure/debian
configure/debian: ## Ensure required dependencies
	$(info "[$(OS)][configure/debian] Ensuring required dependencies..")
	sudo apt-get update
	sudo apt-get install --no-install-recommends -y sudo ca-certificates build-essential curl make bash git procps
	sudo update-ca-certificates

.PHONY: configure/alpine
configure/alpine: ## Ensure required dependencies
	$(info "[configure/alpine] Ensuring required dependencies..")
	apk -U --no-cache add sudo curl make bash git procps

.PHONY: configure/darwin
configure/darwin: configure/darwin/xcode_tools ## Configure darwin defaults
	$(info "[$(OS)][configure/darwin] Configuring darwin..")
	defaults write -g ApplePressAndHoldEnabled -bool false
	defaults write -g InitialKeyRepeat -int 10
	defaults write -g KeyRepeat -int 1
	sudo scutil --set HostName $(HOSTNAME)
	sudo scutil --set LocalHostName $(HOSTNAME)
	sudo scutil --set ComputerName $(HOSTNAME)
	dscacheutil -flushcache
	sudo chown -R $(whoami) /usr/local/share/man/man8
	chmod u+w /usr/local/share/man/man8

.PHONY: configure/darwin/xcode_tools
configure/darwin/xcode_tools: ## Ensure Command Line Tools for Xcode is installed (https://developer.apple.com/forums/thread/698954)
ifeq ($(shell command -v xcode-select),)
	$(info "[$(OS)][configure/darwin/xcode_tools] Command Line Tools for Xcode Not found! Installing from softwareupdate..")
	# This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
	touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
	softwareupdate -ia "$(SOFTWARE_UPDATE)" --verbose;
endif

.PHONY: brew/setup
brew/setup: ## Setup Homebrew
ifeq ($(shell command -v brew),)
	$(info "[$(OS)][Homebrew] Setting up..")
	yes | curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s
endif

.PHONY: brew/bundle
brew/bundle: ## Bundle Homebrew
	HOMEBREW_NO_INSTALL_CLEANUP=TRUE HOMEBREW_NO_ENV_HINTS=TRUE $(BREW_BIN) bundle --verbose --file $(XDG_CONFIG_HOME)/brewfile/Brewfile

.PHONY: brew/configure
brew/configure: brew/setup brew/bundle ## Setup and bundle Homebrew

$(DOTS_TARGET):
	$(info "[$(OS)][Dots] Cloning '$(DOTS_REPO)'..")
	git clone --bare $(DOTS_REPO) $@

$(XDG_CONFIG_HOME): | $(DOTS_TARGET)
	$(info "[$(OS)][Dots] Checking out branch '$(BRANCH)'..")
	$(if $(DOTS) checkout "$(BRANCH)" && test $? -ne 0 ) $(and $(BACKUP) && $(DOTS) checkout "$(BRANCH)")
	$(DOTS) config status.showUntrackedFiles no
