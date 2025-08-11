# [Bat][1]

A cat(1) clone with syntax highlighting and Git integration.

## Setup

``  ````$ brew install bat ``````````````

## Configuration file

  Define the config file location

    export BAT_CONFIG_PATH=$HOME/.config/bat/config.conf

  Generate a config file

    $ bat --generate-config-file

  Edit the config file

    $ vi $(bat --config-file)

  Config file example

    # Set the theme to "TwoDark"
    --theme="TwoDark"

    # Show line numbers, Git modifications and file header (but no grid)
    --style="numbers,changes,header"

    # Use italic text on the terminal (not supported on all terminals)
    --italic-text=always

    # Use C++ syntax for Arduino .ino files
    --map-syntax "*.ino:C++"

## Usage

  Display a single file on the terminal
`
      $ bat README.md`

  Display multiple files at once

      $ bat src/*.rs

  Print the contents of a file to the standard output:

      $ bat file

  Concatenate several files into the target file:

      $ bat file1 file2 > target_file

  Append several files into the target file:

      $ bat file1 file2 >> target_file

  Number all output lines:

      $ bat -n file

  Syntax highlight a JSON file:

      $ bat --language json file.json

  Display all supported languages:

      $ bat --list-languages

### Adding new syntaxes / language definitions

  Create a folder to place syntax definition

    mkdir -p "$(bat --config-dir)/syntaxes"

  Place language definitions files

    git submodule add git@github.com:tellnobody1/sublime-purescript-syntax "$(bat --config-dir)"/syntaxes/purescript-syntax

  Update the cache

    $ bat cache --build

  Check the new languages

    $ bat --list-languages

### Adding new themes

  Create a folder to place syntax highlighting themes

    mkdir -p "$(bat --config-dir)/themes"

  Place language definitions files

    git submodule add git@github.com:greggb/sublime-snazzy.git "$(bat --config-dir)"/themes/snazzy

  Update the cache

    $ bat cache --build

  Check the new themes

    $ bat --list-themes

## Resources

- [A cat(1) clone with wings][0]

[0]: <https://github.com/sharkdp/bat#adding-new-themes> "A cat(1) clone with wings"
