--- Normalize a generated Conventional Commits message.
--- Small models ignore length and casing rules often enough that the format is
--- enforced here instead: a single scope, a capitalized header cut at a word
--- boundary to fit, and body lines wrapped. A message whose first line is not a
--- Conventional Commits header is returned trimmed but otherwise untouched.

--- @class FormatConventionalCommitOptions
--- @field max_header? integer Limit for the whole first line (default 50)
--- @field max_body? integer Limit for each body line (default 70)
--- @field scopes? table<string, integer> How often the repository used each scope
--- @field paths? string[] Changed file paths, to pick a scope the history does not settle

local DEFAULTS = { max_header = 50, max_body = 70 }

--- Types models emit that this repository spells differently.
local TYPE_ALIASES = { refactor = 'ref' }

--- Words a cut subject should not end on.
local DANGLING = {
  a = true,
  an = true,
  ['and'] = true,
  by = true,
  ['for'] = true,
  from = true,
  ['in'] = true,
  of = true,
  on = true,
  ['or'] = true,
  the = true,
  to = true,
  via = true,
  with = true,
}

--- @param text string
--- @return string
local function trim(text)
  return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

--- Cut `subject` to at most `max` characters at a word boundary.
--- @param subject string
--- @param max integer
--- @return string
local function shorten(subject, max)
  if #subject <= max then
    return subject
  end
  local words = {}
  local length = -1
  for word in subject:gmatch('%S+') do
    if length + 1 + #word > max then
      break
    end
    table.insert(words, word)
    length = length + 1 + #word
  end
  if #words == 0 then
    return subject:sub(1, max)
  end
  -- A cut tail like "and enhance" or "for binary" reads as unfinished: drop it
  -- when it is short, keeping the clause before the conjunction or preposition.
  for i = #words, 2, -1 do
    if #words - i + 1 > 2 then
      break
    end
    if DANGLING[words[i]:lower()] or words[i - 1]:match(',$') then
      words = { unpack(words, 1, i - 1) }
      break
    end
  end
  while #words > 1 and DANGLING[words[#words]:lower():gsub('[%p]+$', '')] do
    table.remove(words)
  end
  return (table.concat(words, ' '):gsub('[%s%p]+$', ''))
end

--- Number of `paths` that contain `term` as a path segment.
--- @param term string
--- @param paths string[]
--- @return integer
local function path_matches(term, paths)
  local count = 0
  for _, path in ipairs(paths) do
    for segment in path:gmatch('[^/]+') do
      if segment:lower() == term then
        count = count + 1
        break
      end
    end
  end
  return count
end

--- Share of changed paths above which a term (e.g. a top-level "config/") no
--- longer tells areas apart.
local UNIVERSAL = 0.8

--- Pick the scope to keep.
--- A list-like scope ("config, nvim, llm") is reduced to the term the repository
--- used most, then the one matching most changed paths, then the first. A scope
--- that names nothing in the changes is replaced by the known scope with the
--- highest (changed paths matched x times used), ignoring terms shared by nearly
--- every path.
--- @param scope string
--- @param opts FormatConventionalCommitOptions
--- @return string
local function pick_scope(scope, opts)
  local scopes, paths = opts.scopes or {}, opts.paths or {}
  local terms = {}
  for term in scope:lower():gmatch('[^,%s|+&]+') do
    table.insert(terms, term)
  end

  local best, best_used, best_paths = terms[1] or '', -1, -1
  for _, term in ipairs(terms) do
    local used, matched = scopes[term] or 0, path_matches(term, paths)
    if used > best_used or (used == best_used and matched > best_paths) then
      best, best_used, best_paths = term, used, matched
    end
  end
  if #paths == 0 or best_paths > 0 then
    return best
  end

  local replacement, replacement_score = best, 0
  for known, used in pairs(scopes) do
    local matched = path_matches(known, paths)
    local score = matched < UNIVERSAL * #paths and matched * used or 0
    if score > replacement_score or (score == replacement_score and score > 0 and known < replacement) then
      replacement, replacement_score = known, score
    end
  end
  return replacement
end

--- Wrap one body line at `max` characters, indenting continuations of list items.
--- @param line string
--- @param max integer
--- @return string[]
local function wrap(line, max)
  if #line <= max then
    return { line }
  end
  local marker = line:match('^%s*[-*]%s+') or line:match('^%s*%d+[.)]%s+') or line:match('^%s*')
  local indent = (' '):rep(#marker)
  local lines, current = {}, marker
  for word in line:sub(#marker + 1):gmatch('%S+') do
    if current ~= marker and current ~= indent and #current + 1 + #word > max then
      table.insert(lines, current)
      current = indent .. word
    else
      current = (current == marker or current == indent) and (current .. word) or (current .. ' ' .. word)
    end
  end
  table.insert(lines, current)
  return lines
end

--- Wrap every body line and collapse runs of blank lines.
--- @param body string
--- @param max integer
--- @return string
local function format_body(body, max)
  local lines = {}
  for line in (body .. '\n'):gmatch('([^\n]*)\n') do
    line = line:gsub('%s+$', '')
    if line ~= '' or (lines[#lines] and lines[#lines] ~= '') then
      for _, wrapped in ipairs(wrap(line, max)) do
        table.insert(lines, wrapped)
      end
    end
  end
  return trim(table.concat(lines, '\n'))
end

--- @param message string Raw model output
--- @param opts FormatConventionalCommitOptions|nil
--- @return string
return function(message, opts)
  opts = opts or {}
  local max_header = opts.max_header or DEFAULTS.max_header
  local max_body = opts.max_body or DEFAULTS.max_body
  message = trim(message:gsub('^%s*```%w*\n', ''):gsub('\n```%s*$', ''))

  local header, rest = message:match('^([^\n]*)\n?(.*)$')
  local kind, scope, bang, subject = header:match('^(%w+)%(([^)]*)%)(!?):%s*(.+)$')
  if not kind then
    kind, bang, subject = header:match('^(%w+)(!?):%s*(.+)$')
  end
  if not kind then
    return message
  end

  kind = kind:lower()
  kind = TYPE_ALIASES[kind] or kind
  scope = scope and pick_scope(scope, opts) or ''
  local prefix = ('%s%s%s: '):format(kind, scope ~= '' and ('(' .. scope .. ')') or '', bang)

  subject = trim(subject):gsub('%.+$', '')
  subject = shorten(subject:sub(1, 1):upper() .. subject:sub(2), math.max(max_header - #prefix, 1))

  local body = format_body(rest, max_body)
  return body == '' and (prefix .. subject) or (prefix .. subject .. '\n\n' .. body)
end
