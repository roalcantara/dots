---Returns {str} right-aligned by padding them on the left with {char}, {len} times. The padding is applied from the right end of the string.
---@param str string The string to the pad
---@param len? number Length of the pad [default: 1]
---@param char? string The string used as padding [default: ' ']
---@return string The padded string
---@example print(ljust('foo', 12, '_')) => "foo_________"
local function l_just(str, len, char)
  if not len then len = 1 end
  if not char then char = ' ' end

  -- Allowed flags:
  -- - : left align result inside field
  -- + : always prefix with a sign, using + if field positive
  -- 0 : left-fill with zeroes rather than spaces
  -- (space) : If positive, put a space where the + would have been
  -- # : Changes the behaviour of various formats, as follows:
  --   For octal conversion (o), prefixes the number with 0 - if necessary.
  --   For hex conversion (x), prefixes the number with 0x
  --   For hex conversion (X), prefixes the number with 0X
  --   For e, E and f formats, always show the decimal point.
  --   For g and G format, always show the decimal point, and do not truncate trailing zeroes.
  --   The option to 'always show the decimal point' would only apply if you had the precision set to 0.
  return string.format('%s%s', str, string.rep(char, len - (vim.fn.strdisplaywidth(str))))
end

return l_just
