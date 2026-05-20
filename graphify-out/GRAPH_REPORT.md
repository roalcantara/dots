# Graph Report - /Users/roalcantara/Work/dots  (2026-05-08)

## Corpus Check
- Large corpus: 543 files · ~350,609 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 367 nodes · 378 edges · 117 communities (108 shown, 9 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 4 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]

## God Nodes (most connected - your core abstractions)
1. `get()` - 14 edges
2. `M.get_info()` - 10 edges
3. `sanitize_jql_value()` - 9 edges
4. `M.get_name()` - 8 edges
5. `is_linux()` - 7 edges
6. `is_windows()` - 6 edges
7. `is_freebsd()` - 6 edges
8. `is_wsl()` - 6 edges
9. `execute_external_language()` - 5 edges
10. `M.stdpath()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `M.root_path()` --calls--> `M.detect()`  [INFERRED]
  config/nvim/lua/core/vi/paths.lua → config/nvim/lua/core/vi/buf/get_buf_name.lua
- `execute_external_language()` --calls--> `trim()`  [INFERRED]
  config/nvim/lua/core/ui/snacks/scratch.lua → config/nvim/specs/tools/spec_helper.lua
- `set_keymaps()` --calls--> `is_git_repo()`  [INFERRED]
  config/nvim/lua/core/vi/maps/set_keymaps.lua → config/nvim/lua/core/etc/git/is_git_repo.lua
- `au()` --calls--> `aug()`  [INFERRED]
  config/nvim/lua/core/vi/au/au.lua → config/nvim/lua/core/vi/au/aug.lua

## Communities (117 total, 9 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.09
Nodes (21): agentDir, agentLines, customSrc, cwd, d, decode(), dest, dest1 (+13 more)

### Community 1 - "Community 1"
Cohesion: 0.16
Nodes (15): M.basename(), M.bin_for(), M.bin_for_python3_venv(), M.ensure(), M.get_runtimepath_path_items(), M.get_stdpaths(), M.getenv(), M.is_directory() (+7 more)

### Community 2 - "Community 2"
Cohesion: 0.37
Nodes (14): get(), get_uname(), get_uname_released(), is_freebsd(), is_linux(), is_macos(), is_windows(), is_wsl() (+6 more)

### Community 3 - "Community 3"
Cohesion: 0.18
Nodes (16): build_blocked_query(), build_completed_query(), build_in_progress_query(), build_project_query(), build_risk_query(), build_unassigned_query(), Build query for blocked issues., Sanitize a value for use in JQL to prevent injection attacks.          Args: (+8 more)

### Community 4 - "Community 4"
Cohesion: 0.16
Nodes (12): decode(), fixturesDir, fzfLog, gumLog, lines, makeTmpStubs(), minimalStubs, noGumStubs (+4 more)

### Community 5 - "Community 5"
Cohesion: 0.24
Nodes (9): clear_results(), create_results_buffer(), execute_code(), execute_external_language(), open_scratch_panel_for(), prepare(), show_execution_result(), is_empty() (+1 more)

### Community 6 - "Community 6"
Cohesion: 0.29
Nodes (8): decodeHtmlEntities(), expectedJson, extractAttribute(), extractFromList(), extractFromMarvel(), extractTextContent(), ListItem, main()

### Community 7 - "Community 7"
Cohesion: 0.33
Nodes (5): clear_message(), M.create_noice_component_with_dismiss(), M.create_package_component_with_dismiss(), M.dismiss(), start_dismiss_timer()

### Community 8 - "Community 8"
Cohesion: 0.39
Nodes (6): extract_command_and_opts(), extract_opts(), format_key_combination(), keymap(), setup_key_combination_and_user_command(), setup_user_command()

### Community 9 - "Community 9"
Cohesion: 0.39
Nodes (5): create_package_component(), get_color_by_name(), get_noice_component(), get_package(), get_package_value()

### Community 11 - "Community 11"
Cohesion: 0.29
Nodes (3): is_git_repo(), keymap_cmd(), set_keymaps()

### Community 12 - "Community 12"
Cohesion: 0.48
Nodes (5): M.clear_cache(), M.get_formatter_status(), M.get_formatter_status_async(), M.get_formatters_for_filetype(), M.is_formatter_available()

### Community 14 - "Community 14"
Cohesion: 0.52
Nodes (5): call_all(), call_one(), content_for_request(), get_provider_api(), M.call()

### Community 15 - "Community 15"
Cohesion: 0.33
Nodes (4): out, r, selected, xdg

### Community 16 - "Community 16"
Cohesion: 0.53
Nodes (4): cancel_mouse_hover_timer(), is_completion_visible(), show_hover(), start_mouse_hover_timer()

### Community 18 - "Community 18"
Cohesion: 0.6
Nodes (3): format_notification_msg(), get_notify_options(), update_spinner()

### Community 19 - "Community 19"
Cohesion: 0.7
Nodes (3): M.close_modal(), M.show_formatter_modal(), M.toggle_modal()

### Community 20 - "Community 20"
Cohesion: 0.6
Nodes (4): M.noice_count_history(), M.noice_history(), M.notifier_count_history(), M.notifier_history()

### Community 22 - "Community 22"
Cohesion: 0.7
Nodes (4): M.bufpath(), M.detect(), M.detectors.pattern(), M.resolve()

### Community 23 - "Community 23"
Cohesion: 0.7
Nodes (4): build_argv(), normalize_input(), request(), strip_preamble()

### Community 24 - "Community 24"
Cohesion: 0.6
Nodes (3): get_request_opts(), M.get_request_opts(), M.messages()

### Community 25 - "Community 25"
Cohesion: 0.6
Nodes (3): get_request_opts(), M.get_request_opts(), M.messages()

### Community 26 - "Community 26"
Cohesion: 0.6
Nodes (3): get_request_opts(), M.get_request_opts(), M.responses()

### Community 27 - "Community 27"
Cohesion: 0.83
Nodes (3): get_lazy_version(), get_nvim_version(), get_versions()

## Knowledge Gaps
- **42 isolated node(s):** `selected`, `SKILL_TARGETS`, `r`, `fakeHome`, `src` (+37 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `M.root_path()` connect `Community 1` to `Community 22`?**
  _High betweenness centrality (0.001) - this node is a cross-community bridge._
- **Why does `M.detect()` connect `Community 22` to `Community 1`?**
  _High betweenness centrality (0.001) - this node is a cross-community bridge._
- **What connects `selected`, `SKILL_TARGETS`, `r` to the rest of the system?**
  _42 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.09 - nodes in this community are weakly interconnected._