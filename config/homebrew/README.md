# Homebrew

Homebrew [Bundle][5] is the right place for the installed state, but it is not a good place for the cookbook. Detailed command examples, historical notes, and workflow instructions were being mixed into the package list and making it hard to scan.

## Overview

- [Brewfile](./Brewfile) is the declarative package catalog.
- [mise.toml](./mise.toml) owns the operational workflow and task recipes.
- [README.md](./README.md) explains the conventions and quickstart path.

The long-form comments and historical notes have been moved out of the active package catalog so the file stays readable and stable.

## Usage

```sh
# or mise -C config/homebrew [task]
cd config/homebrew

# Install Homebrew if it is missing:
mise run brew:setup

# Load the brew environment into the shell session:
mise run brew:load

# Install the declared package catalog:
mise run bundle install

# Check whether the local machine matches the declared state:
mise run bundle check

# Refresh and upgrade the installed packages:
mise run bundle update

# Clean up and verify the installation:
mise run bundle clean

# Generate a new `Brewfile` from currently installed packages:
mise run bundle dump

# Default task lists all dependencies present in the Brewfile:
mise run bundle

# Add dependencies to the Brewfile:
mise run bundle add formulae git
mise run bundle add cask firefox
mise run bundle add mas Xcode 497799835

# Remove dependencies from the Brewfile:
mise run bundle rm cask firefox
```

## Conventions

Keep dependencies and the file organized by category and order the sections consistently:

1. `tap` for Homebrew taps
2. `brew` for core formulae
3. `cask` for desktop apps and GUI tools
4. `cask` for fonts in their own font section
5. optional or temporarily disabled items stay out of the active catalog

### Rules

- Keep only active package state here.
- Prefer short, section-level comments over long narrative blocks.
- Do not keep procedural steps or command examples in the package catalog.
- If a package is temporarily disabled, keep it in the task history or a PR description instead of in the live catalog.

## Homebrew configuration

A cookbook of Homebrew configuration recipes can be found in the guides directory. For examples demonstrating the correct syntax for taps, core formulae, casks, fonts, Mac App Store apps, npm packages, VS Code extensions, and more, refer to the [Homebrew Recipes guide](../../assets/guides/homebrew-recipes.md).

## Dependencies and acknowledgements

- [Standard Readme][1]
- [Git][2]
- [mise][3]
- [Homebrew][4]
- [Homebrew Bundle][5]

[1]: https://github.com/RichardLitt/standard-readme 'Standard Readme'
[2]: https://git-scm.com 'Distributed version control system'
[3]: https://mise.jdx.dev 'Manages dev tools like node, python, cmake, terraform, and hundreds more'
[4]: https://brew.sh 'The missing package manager for macOS'
[5]: https://docs.brew.sh/Manpage#bundle-subcommand 'Homebrew Bundle Subcommand'
