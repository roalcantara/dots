Feature: List Fabric patterns
  The xc-fabric command lets terminal users inspect available Fabric patterns.

  Rule: Pattern listing is available as a read-only command

    Scenario: User lists fixture Fabric patterns as raw output
      Given fixture Fabric patterns exist
      When Alice runs `xc-fabric ls --raw`
      Then Alice sees the command succeed
      And Alice sees "summarize" in the output
      And Alice sees "youtube_summary" in the output
