local entries = require('etc/tables/entries')
local flatten = require('etc/tables/flatten')
local flat_entries
flat_entries = function(collection, predicate)
  return flatten(entries(collection, predicate))
end
return flat_entries
