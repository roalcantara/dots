local devicons = require('nvim-web-devicons')
local lspkind = require('lspkind')
local colorfulmenu = require('colorful-menu')
local blink_cmp = require('blink.cmp')

local cache = {}

--- Get the cached icon and highlight for the given context.kind
--- If the icon is not found in devicons or lspkind, returns the default icon and highlight
--- @param ctx table: The context table
--- @return table: The cached icon and highlight with gap
local get_cached_icon_and_highlight = function(ctx)
  if not cache[ctx.kind] then
    if vim.tbl_contains({ 'Path' }, ctx.source_name) then
      local dev_icon, dev_hl = devicons.get_icon(ctx.label)
      if dev_icon then
        cache[ctx.kind] = { icon = dev_icon, hl = dev_hl, icon_with_gap = dev_icon .. ctx.icon_gap }
      end
    else
      local lspkind_icon = lspkind.symbolic(ctx.kind, nil)
      if lspkind_icon ~= '' then
        cache[ctx.kind] = { icon = lspkind_icon, hl = ctx.kind_hl, icon_with_gap = lspkind_icon .. ctx.icon_gap }
      end
    end
    if not cache[ctx.kind] then
      cache[ctx.kind] = { icon = ctx.kind_icon, hl = ctx.kind_hl, icon_with_gap = ctx.kind_icon .. ctx.icon_gap }
    end
  end
  return cache[ctx.kind]
end

local get_label_highlight = function(ctx)
  if ctx.deprecated then
    local highlights = {
      { 0, #ctx.label, group = 'BlinkCmpLabelDeprecated' },
    }
    if ctx.label_detail then
      table.insert(
        highlights,
        { #ctx.label, #ctx.label + #ctx.label_detail, group = 'BlinkCmpLabelDetail' }
      )
    end
    -- characters matched on the label by the fuzzy matcher
    for _, idx in ipairs(ctx.label_matched_indices) do
      table.insert(highlights, { idx, idx + 1, group = 'BlinkCmpLabelMatch' })
    end

    return highlights
  end
  return colorfulmenu.blink_components_highlight(ctx)
end

--- Get the cached label and highlight for the given context
--- If the label is not found, it will return the default label and highlight
--- @param ctx table The context table with label, label_detail, label_matched_indices
--- @return table cached Label text and highlight
local get_cached_label_and_highlight = function(ctx)
  if not cache[ctx.label] then
    local label_text = colorfulmenu.blink_components_text(ctx)
    local label_highlight = get_label_highlight(ctx)
    cache[ctx.label] = { text = label_text, hl = label_highlight }
  end
  return cache[ctx.label]
end

return {
  --- Get the cached icon with gap by kind from devicons or lspkind; if not found, returns the default icon with gap
  --- @param ctx table The context table with kind, kind_icon, kind_hl and icon_gap
  --- @return string gap The kind icon with gap
  get_kind_icon_with_gap = function(ctx)
    local cached_item = get_cached_icon_and_highlight(ctx)
    return cached_item.icon_with_gap
  end,
  --- Get the cached highlight by kind from devicons or lspkind; if not found, returns the default highlight
  --- @param ctx table The context table with kind, kind_icon, kind_hl and icon_gap
  --- @return string highlight The kind highlight
  get_kind_highlight = function(ctx)
    local cached_item = get_cached_icon_and_highlight(ctx)
    return cached_item.hl
  end,
  --- Get the cached label text for the given context
  --- If the label is not found, it will return the default label text
  --- @param ctx table The context table with label, label_detail, label_matched_indices
  --- @return string label The cached label text
  get_label_text = function(ctx)
    local cached_item = get_cached_label_and_highlight(ctx)
    return cached_item.text
  end,
  --- Get the cached label highlight for the given context
  --- If the label is not found, it will return the default label highlight
  --- @param ctx table The context table with label, label_detail, label_matched_indices
  --- @return string highlight The cached label highlight
  get_label_highlight = function(ctx)
    local cached_item = get_cached_label_and_highlight(ctx)
    return cached_item.hl
  end,
  --- Detect direction order priority to show windows by blink.cmp; { 's', 'n' } by default
  --- Which directions to show the window, falling back to the next direction
  --- when there's not enough space, or another window is in the way
  --- @return table direction_priority The direction order priority; { 's', 'n' } by default
  detect_window_direction_order_priority = function()
    local ctx = blink_cmp.get_context()
    local item = blink_cmp.get_selected_item()
    if ctx and item then
      local item_text = item.textEdit ~= nil and item.textEdit.newText or item.insertText or item.label
      local is_multi_line = item_text:find('\n') ~= nil
      if is_multi_line or vim.g.blink_cmp_upwards_ctx_id == ctx.id then
        -- after showing the menu upwards, we want to maintain that direction
        -- until we re-open the menu, so store the context id in a global variable
        vim.g.blink_cmp_upwards_ctx_id = ctx.id
        return { 'n', 's' }
      end
    end
    return { 's', 'n' }
  end
}
