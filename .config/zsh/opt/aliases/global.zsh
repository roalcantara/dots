# Similar to opt-shellAliases, but are substituted anywhere on a line.;
# These do not have to be at the beginning of the command line
alias -g UUID="$(uuidgen | tr -d \\n)";
alias -g G="| grep";
alias -g M="| more";
alias -g H="| head";
alias -g T="| tail";
alias -g L="| less";
alias -g LTrim="sed -e 's/^[[:space:]]*//'";
alias -g RTrim="sed -e 's/ *$//g'";
alias -g Trim="sed -e 's/^[[:space:]]*//' -e 's/ *$//g'";
alias -g Inline="tr '\\n' ' '";
# Returns a new String with the last character removed.
# If the string ends with rn, both characters are removed.
# Applying chop to an empty string returns an empty string.
# String#chomp is often a safer alternative, as it leaves the string unchanged
# if it doesn’t end in a record separator - https://bit.ly/3xIElkJ
alias -g Chop="sed 's/.$//'";
