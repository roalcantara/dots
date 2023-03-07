#!/usr/bin/env bash
override BRANCH 			:= main
override HOSTNAME 			:= NCC1701
override DOTS_REPO 			:= https://github.com/roalcantara/dots
override DOTS_TARGET 		:= ~/.git
override XDG_CONFIG_HOME 	:= ~/.config
override XDG_CONFIG_BAK 	:= ~/.config.bak
override OS_NAME            ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
override BREWFILE  			?= $(XDG_CONFIG_HOME)/script/Brewfile
override REQUIREMENTS  		?= $(XDG_CONFIG_HOME)/script/requirements.txt
override PACKAGES  			?= $(shell sed 's/#.*//' $(REQUIREMENTS))

SHELL 						= /bin/bash
DOTS 	 					= $(/usr/bin/git --git-dir="$(DOTS_TARGET)" --work-tree="$(HOME)")
BACKUP 						= $(mkdir -p $(XDG_CONFIG_BAK) && $(DOTS) checkout 2>&1 | grep -E '\s+\.' | awk '{ print $1 }' | xargs -I{} mv {} $(XDG_CONFIG_BAK)/{})
SOFTWARE_UPDATE 			= $(softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')

is_darwin 					:= $(filter $(OS_NAME),darwin)
is_alpine 					:= $(filter $(OS_NAME),linux-musl)
is_debian 					:= $(filter $(OS_NAME),linux)
OS   						:= $(if $(is_darwin),darwin,$(if $(is_alpine),alpine,debian))
HOMEBREW_PREFIX 			:= $(if $(is_darwin),/usr/local,$(HOME)/.linuxbrew)
BREW_BIN					:= HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_ENV_HINTS=1 $(HOMEBREW_PREFIX)/bin/brew

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
	@echo "OS => '$(OS)' ✔"
	$(info "OSTYPE => '$(OSTYPE)' ✔")
	$(info "OS_NAME => '$(OS_NAME)' ✔")
	$(info "is_debian => '$(is_debian)' ✔")
	$(info "is_darwin => '$(is_darwin)' ✔")
	$(info "is_alpine => '$(is_alpine)' ✔")
	$(info "HOMEBREW_PREFIX => '$(HOMEBREW_PREFIX)' ✔")
	$(info "BREW_BIN => '$(BREW_BIN)' ✔")
	$(info "PACKAGES => '$(PACKAGES)' ✔")

.PHONY: docker/build
docker/build: ## Buld Dockerfile
	docker buildx build --target dots -t roalcantara/dots $(XDG_CONFIG_HOME)/script

.PHONY: docker/run
docker/run: ## Run Docker Container roalcantara/dots (docker run -it --rm --hostname dots roalcantara/dots)
	docker compose run --rm dots

.PHONY: docker/serve
docker/serve: ## Run Docker Container roalcantara/dots mounting ~/.config (docker run -it --rm --hostname dots -v ~/.config:/home/linuxbrew/.config roalcantara/dots)
	docker compose run -v $(XDG_CONFIG_HOME):/home/linuxbrew/.config --rm dots

.PHONY: configure/xcode-cli-tools
configure/xcode-cli-tools: ## Ensure Command Line Tools for Xcode is installed (https://developer.apple.com/forums/thread/698954)
ifeq ($(shell command -v xcode-select),)
	$(info "[configure/xcode-cli-tools] Ensuring required dependencies..")
	# This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
	touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
	softwareupdate -ia "$(SOFTWARE_UPDATE)" --verbose;
endif

.PHONY: configure/macos
configure/macos: ## Ensure Command Line Tools for Xcode is installed (https://developer.apple.com/forums/thread/698954)
	$(info "[configure/macos] Setting defaults..")
	defaults write -g ApplePressAndHoldEnabled -bool false
	defaults write -g InitialKeyRepeat -int 10
	defaults write -g KeyRepeat -int 1
	sudo scutil --set HostName $(HOSTNAME)
	sudo scutil --set LocalHostName $(HOSTNAME)
	sudo scutil --set ComputerName $(HOSTNAME)
	dscacheutil -flushcache
	sudo chown -R $(whoami) /usr/local/share/man/man8
	chmod u+w /usr/local/share/man/man8

.PHONY: brew/setup
brew/setup: ## Setup Homebrew
ifeq ($(shell command -v brew),)
	$(info "[$(OS)][brew/setup] Setting up..")
	yes | curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s
	$(BREW_BIN) config
endif

.PHONY: brew/configure
brew/configure: brew/setup ## Setup and bundle Homebrew

.PHONY: install/debian
install/debian: ## Ensure required dependencies
	$(info "[install/$(OS)] Ensuring required dependencies..")
	sudo apt-get update && sudo apt-get install --no-install-recommends -qqy $(PACKAGES) && sudo apt-get autoremove && sudo apt-get clean && sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/*

.PHONY: install/alpine
install/alpine: ## Ensure required dependencies
	$(info "[install/$(OS)] Ensuring required dependencies..")
	sudo apk -U --no-cache add $(PACKAGES) && sudo rm -f /tmp/* /etc/apk/cache/*

.PHONY: install/darwin
install/darwin: configure/xcode-cli-tools configure/macos brew/configure ## Ensure Command Line Tools for Xcode is installed (https://developer.apple.com/forums/thread/698954)
	$(BREW_BIN) bundle --verbose --file $(BREWFILE)

.PHONY: configure/$(OS)
configure/$(OS): install/$(OS) ## Configure darwin defaults

.PHONY: install
install: puts configure/$(OS) $(XDG_CONFIG_HOME) ## Install Dotfiles
	$(info "[$(OS)][install] ✔✔")

$(DOTS_TARGET):
	$(info "[$(OS)][Dots] Cloning '$(DOTS_REPO)'..")
	git clone --bare $(DOTS_REPO) $@

$(XDG_CONFIG_HOME): | $(DOTS_TARGET)
	$(info "[$(OS)][Dots] Checking out branch '$(BRANCH)'..")
	$(if $(DOTS) checkout "$(BRANCH)" && test $? -ne 0 ) $(and $(BACKUP) && $(DOTS) checkout "$(BRANCH)")
	$(DOTS) config status.showUntrackedFiles no
