local resolved_capabilities = {
  call_hierarchy = 'boolean',
  code_action = {
    codeActionKinds = 'string[]',
    resolveProvider = 'boolean'
  },
  code_lens = 'boolean',
  code_lens_resolve = 'boolean',
  completion = 'boolean',
  declaration = 'boolean',
  document_formatting = 'boolean',
  document_highlight = 'boolean',
  document_range_formatting = 'boolean',
  document_symbol = 'boolean',
  execute_command = 'boolean',
  find_references = 'boolean',
  goto_definition = 'boolean',
  hover = 'boolean',
  implementation = 'boolean',
  rename = 'boolean',
  signature_help = 'boolean',
  signature_help_trigger_characters = 'string[]',
  text_document_did_change = 'number',
  text_document_open_close = 'boolean',
  text_document_save = 'boolean',
  text_document_save_include_text = 'boolean',
  text_document_will_save = 'boolean',
  text_document_will_save_wait_until = 'boolean',
  type_definition = 'boolean',
  workspace_folder_properties = {
    changeNotifications = 'boolean',
    supported = 'boolean'
  },
  workspace_symbol = 'boolean'
}
return resolved_capabilities
