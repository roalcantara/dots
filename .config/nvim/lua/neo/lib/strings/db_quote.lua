local db_quote
db_quote = function(v)
  return '"' .. v .. '"'
end
return db_quote
