# Homebrew configuration recipes

Use this guide as a cookbook for declaring various dependency types inside
your `Brewfile`. These examples demonstrate the correct syntax for taps,
core formulae, casks, fonts, Mac App Store apps, npm packages, VS Code
extensions, Go packages, Cargo packages, uv tools, Krew plugins, and
Flatpak packages.

## Homebrew taps

Use **`tap`** to register external formulas repositories.

```ruby
tap "apple/apple"
tap "user/tap-repository", "https://user@bitbucket.org/user/homebrew-tap-repository.git"
```

## Core formulae

Use **`brew`** to register command-line tools and libraries.

```ruby
brew "apple/apple/game-porting-toolkit"
brew "postgresql@16", restart_service: true
```

## Homebrew casks

Use **`cask`** to register graphical applications.

```ruby
cask "firefox"
```

## Mac App Store apps

Use **`mas`** to register Mac App Store applications (requires `mas` CLI installed).

```ruby
mas "Refined GitHub", id: 1519867270
```

## npm packages

Use **`npm`** to declare global JavaScript/TypeScript packages.

```ruby
npm "create-react-app"
```

## VS Code extensions

Use **`vscode`** to declare extensions.

```ruby
vscode "editorconfig.editorconfig"
```

## Go packages

Use **`go`** to declare Go command binaries.

```ruby
go "github.com/charmbracelet/crush"
```

## Cargo packages

Use **`cargo`** to declare Rust packages.

```ruby
cargo "ripgrep"
```

## uv tools

Use **`uv`** to declare Python packages.

```ruby
uv "mkdocs"
uv "ruff", source: "git+https://github.com/astral-sh/ruff.git"
```

## Krew plugins

Use **`krew`** to declare Kubernetes CLI plugins.

```ruby
krew "ctx"
```

## Flatpak packages

Use **`flatpak`** to declare Linux Flatpak packages.

```ruby
flatpak "com.visualstudio.code"
flatpak "org.godotengine.Godot", remote: "flathub-beta", url: "https://dl.flathub.org/beta-repo/"
flatpak "io.github.dvlv.boxbuddyrs", remote: "flathub-beta"
```
