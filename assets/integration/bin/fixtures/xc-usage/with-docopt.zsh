#!/usr/bin/env zsh
#? License RIT (Robot Institute of Technology)

##? fixture-with-docopt - Test fixture with full ##? docopt header
##?
##? Usage:
##?   fixture-with-docopt [options] <args...>
##?   fixture-with-docopt -h | --help
##?
##? Arguments:
##?   args    Positional arguments
##?
##? Options:
##?   -h, --help    Show this screen
##?   -v, --verbose  Verbose output
##?
##? Examples:
##?   fixture-with-docopt -h
##?   fixture-with-docopt arg1 arg2

echo "fixture ran with: $@"
