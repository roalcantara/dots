# Taskfile { 
# Task is a task runner / build tool that aims to be simpler and easier to use than, for example, GNU Make.
# https://taskfile.dev/
if (($+commands[gotask])); then
  alias gt='gotask'                            # List non-hidden folders and files inline
fi
# }