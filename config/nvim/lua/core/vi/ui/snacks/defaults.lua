local default_exclusions = {
  "**/__pycache__/*",
  "**/.git/*",
  "**/.next/*",
  "**/.next/cache/*",
  "**/.next/cache/fonts/*",
  "**/.next/cache/images/*",
  "**/.next/cache/swc/*",
  "**/.pnpm-store/*",
  "**/.venv/*",
  "**/.yarn/cache/*",
  "**/.yarn/install*",
  "**/.yarn/releases/*",
  "**/node_modules/*",
  "**/venv/*",
}

local default_options = {
  filter = { cwd = true },
  hidden = true,
  follow = true,
  exclude = default_exclusions,
}

return {
  default_options = default_options,
  default_exclusions = default_exclusions,
}
