#!/usr/bin/env zsh
# Fixture: xc-fabric-style dispatcher (main + sub blocks) for xc-usage scope tests

##? xc-alpha - Example dispatcher for tests
##?
##? Usage:
##?   xc-alpha <subcommand>
##?   xc-alpha -h | --help
##?
##? Subcommands:
##?   ping    Say ping
##?   pong    Say pong
##?
##? Options:
##?   -h, --help    Show this screen
##?
##? Examples:
##?   xc-alpha -h
##?   xc-alpha ping

### Subcommand help blocks (parsed by xc-usage; not shown in help output) ###

##? xc-alpha ping - Say ping
##?
##? Usage:
##?   xc-alpha ping
##?   xc-alpha ping -h | --help
##?
##? Examples:
##?   xc-alpha ping

##? xc-alpha pong - Say pong
##?
##? Usage:
##?   xc-alpha pong
##?   xc-alpha pong -h | --help
##?
##? Examples:
##?   xc-alpha pong
