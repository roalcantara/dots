Feature: Discover xc commands
  The xc launcher helps terminal users discover available Dots commands.

  Rule: The launcher exposes command discovery without starting an interactive picker

    Scenario: User lists tools from the fixture bin directory
      Given the fixture bin directory contains executable xc tools
      When Alice runs `xc list`
      Then Alice sees the command succeed
      And Alice sees "xc-sample" in the output
      And Alice sees "Fixture tool" in the output

    Scenario: User reads launcher help
      Given the xc launcher is available
      When Alice runs `xc -h`
      Then Alice sees the command succeed
      And Alice sees "xc" in the output
      And Alice sees "list" in the output
      And Alice sees "launcher" in the output
