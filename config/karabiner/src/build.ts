// Generates the fn layer: the "dots" profile's rules in karabiner.json and hotkeys.json (read by the kb
// Raycast extension's Hotkeys command). Run `mise run karabiner:build`; `--check` exits 1 when either
// committed file differs from src/bindings.ts. DOTS_KARABINER_DIR points it at another folder (tests).
import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { complexModifications, rule, writeToProfile } from 'karabiner.ts'
import { type Binding, bindings, type Group } from './bindings'

const PROFILE = 'dots'
const dir = process.env.DOTS_KARABINER_DIR ?? join(import.meta.dir, '..')
const karabinerJson = join(dir, 'karabiner.json')
const hotkeysJson = join(dir, 'hotkeys.json')
const GROUPS: readonly Group[] = ['Spaces', 'Windows', 'Layout', 'Apps', 'System']

const quote = (arg: string) => (/^[\w.+-]+$/.test(arg) ? arg : `'${arg.replaceAll("'", "'\\''")}'`)

const KEYS: Readonly<Record<string, string>> = {
  left_arrow: '←',
  right_arrow: '→',
  up_arrow: '↑',
  down_arrow: '↓',
  return_or_enter: 'Return',
  escape: 'Esc',
  tab: 'Tab',
  grave_accent_and_tilde: '`',
  open_bracket: '[',
  close_bracket: ']',
  hyphen: '−',
  equal_sign: '=',
}
const SYMBOLS: Readonly<Record<string, string>> = { control: '⌃', option: '⌥', shift: '⇧' }
const ORDER = ['control', 'option', 'shift']

// "fn ⇧ 1": the key as hotkeys.json and yb's trace (YB_KEY) name it.
const keysOf = (x: Binding): string =>
  ['fn', ...ORDER.filter(m => x.mods.includes(m as never)).map(m => SYMBOLS[m]), KEYS[x.key] ?? x.key.toUpperCase()].join(' ')

const manipulator = (binding: Binding) => ({
  type: 'basic' as const,
  description: binding.label,
  // Caps Lock counts as a modifier to Karabiner; optional keeps every key working while it is on.
  from: { key_code: binding.key, modifiers: { mandatory: ['fn', ...binding.mods], optional: ['caps_lock'] } },
  to: binding.sends
    ? [{ key_code: binding.sends }]
    : [{ shell_command: `PATH=/opt/homebrew/bin:/usr/bin:/bin YB_KEY='${keysOf(binding)}' "$HOME/.local/bin/yb" ${(binding.yb ?? []).map(quote).join(' ')}` }],
})

const rules = () =>
  GROUPS.map(group =>
    rule(`fn layer: ${group}`).manipulators(bindings.filter(x => x.group === group).map(manipulator) as never)
  )

const hotkeys = () =>
  bindings.map(x => ({
    keys: keysOf(x),
    label: x.label,
    group: x.group,
  }))

const hotkeysText = () => `${JSON.stringify(hotkeys(), null, 2)}\n`

function check(): number {
  const expected = JSON.parse(JSON.stringify(complexModifications(rules()).rules))
  const committed = JSON.parse(readFileSync(karabinerJson, 'utf8'))
  const profile = committed.profiles?.find((p: { name: string }) => p.name === PROFILE)
  const problems = [
    Bun.deepEquals(profile?.complex_modifications?.rules, expected) ? '' : `${karabinerJson}: the ${PROFILE} rules`,
    readFileSync(hotkeysJson, 'utf8') === hotkeysText() ? '' : hotkeysJson,
  ].filter(Boolean)
  for (const problem of problems) console.error(`stale: ${problem} (run mise run karabiner:build)`)
  return problems.length === 0 ? 0 : 1
}

if (process.argv.includes('--check')) process.exit(check())
writeToProfile({ name: PROFILE, karabinerJsonPath: karabinerJson }, rules())
writeFileSync(hotkeysJson, hotkeysText())
