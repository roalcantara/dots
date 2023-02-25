# SHELDON {
  # https://sheldon.cli.rs
  # Sheldon is a fast, configurable, command-line tool to manage your shell plugins.
  # curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to /usr/local/bin
  if (($+commands[sheldon])); then
    source <(sheldon source)
  fi
# }
