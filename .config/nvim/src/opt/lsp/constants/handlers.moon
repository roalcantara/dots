handlers = {
  callHierarchy: {incomingCalls: 'callHierarchy/incomingCalls', outgoingCalls: 'callHierarchy/outgoingCalls'},
  textDocument: {
    hover: 'textDocument/hover',
    rename: 'textDocument/rename',
    completion: 'textDocument/completion',
    definition: 'textDocument/definition',
    formatting: 'textDocument/formatting',
    references: 'textDocument/references',
    codeAction: 'textDocument/codeAction',
    declaration: 'textDocument/declaration*',
    signatureHelp: 'textDocument/signatureHelp',
    typeDefinition: 'textDocument/typeDefinition*',
    documentSymbol: 'textDocument/documentSymbol',
    implementation: 'textDocument/implementation*',
    rangeFormatting: 'textDocument/rangeFormatting',
    documentHighlight: 'textDocument/documentHighlight',
    publishDiagnostics: 'textDocument/publishDiagnostics'
  },
  window: {
    logMessage: 'window/logMessage',
    showMessage: 'window/showMessage',
    showMessageRequest: 'window/showMessageRequest'
  },
  workspace: {symbol: 'workspace/symbol', applyEdit: 'workspace/applyEdit'}
}

return handlers
