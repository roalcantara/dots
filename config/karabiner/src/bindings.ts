// The fn layer: one entry per key combination (docs/superpowers/specs/2026-11-07-yabai-omarchy-design.md,
// "Key layout"). fn is always required and is not listed in `mods`. An entry either runs `yb <args>`
// (config/bin/yb) or sends a key (`key`). build.ts turns this table into Karabiner rules and hotkeys.json.

export type Group = 'Spaces' | 'Windows' | 'Layout' | 'Apps' | 'System'
export type Mod = 'shift' | 'option' | 'control'

export type Binding = Readonly<{
  key: string
  mods: readonly Mod[]
  label: string
  group: Group
  yb?: readonly string[]
  sends?: string
}>

const b = (group: Group, key: string, mods: readonly Mod[], label: string, yb: readonly string[]): Binding => ({
  group,
  key,
  mods,
  label,
  yb,
})

const DIGITS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'] as const
const ARROWS = [
  ['left_arrow', 'west'],
  ['right_arrow', 'east'],
  ['up_arrow', 'north'],
  ['down_arrow', 'south'],
] as const
const APPS = [
  ['return_or_enter', ['shift'], 'Google Chrome'],
  ['f', ['shift'], 'Finder'],
  ['a', ['shift'], 'ChatGPT'],
  ['c', ['shift'], 'Claude'],
  ['v', ['shift'], 'Visual Studio Code'],
  ['g', ['shift'], 'WhatsApp'],
  ['d', ['shift'], 'Discord'],
] as const

const slot = (i: number) => String(i + 1)

export const bindings: readonly Binding[] = [
  ...DIGITS.map((key, i) => b('Spaces', key, [], `Go to space ${slot(i)}`, ['space', slot(i)])),
  ...DIGITS.map((key, i) => b('Spaces', key, ['shift'], `Move window to space ${slot(i)}`, ['move', slot(i)])),
  ...DIGITS.map((key, i) =>
    b('Spaces', key, ['shift', 'option'], `Move window to space ${slot(i)}, stay here`, ['move', slot(i), '--stay'])
  ),
  b('Spaces', 'tab', [], 'Next space on this screen', ['space', 'next']),
  b('Spaces', 'tab', ['shift'], 'Previous space on this screen', ['space', 'prev']),
  b('Spaces', 'tab', ['control'], 'Last space you were on', ['space', 'recent']),

  ...ARROWS.map(([key, dir]) => b('Windows', key, [], `Focus window ${dir}`, ['focus', dir])),
  ...ARROWS.map(([key, dir]) => b('Windows', key, ['shift'], `Swap window ${dir}`, ['swap', dir])),
  b('Windows', 'left_arrow', ['shift', 'control'], 'Send window to the screen west', ['send-display', 'west']),
  b('Windows', 'right_arrow', ['shift', 'control'], 'Send window to the screen east', ['send-display', 'east']),
  b('Windows', 'grave_accent_and_tilde', [], 'Focus the other screen', ['display-other']),
  b('Windows', 'w', [], 'Close window', ['close']),
  b('Windows', 't', [], 'Toggle tiled / floating', ['float']),
  b('Windows', 'f', [], 'Fullscreen inside the space', ['zoom', 'full']),
  b('Windows', 'f', ['option'], 'Full width (fill the parent split)', ['zoom', 'parent']),
  b('Windows', 'o', [], 'Pin: floating, on top, on every space', ['pin']),
  b('Windows', 's', [], 'Toggle the scratchpad', ['scratchpad']),
  b('Windows', 's', ['option'], 'Send window to the scratchpad', ['scratchpad', '--send']),
  b('Windows', 'hyphen', [], 'Narrower', ['resize', 'w-']),
  b('Windows', 'equal_sign', [], 'Wider', ['resize', 'w+']),
  b('Windows', 'hyphen', ['shift'], 'Shorter', ['resize', 'h-']),
  b('Windows', 'equal_sign', ['shift'], 'Taller', ['resize', 'h+']),

  b('Layout', 'j', [], 'Toggle split orientation', ['split']),
  ...ARROWS.map(([key]) => {
    const dir = ({ left_arrow: 'left', right_arrow: 'right', up_arrow: 'up', down_arrow: 'down' } as const)[key]
    const how = dir === 'left' || dir === 'right' ? 'side by side' : 'one above the other'
    return b('Layout', key, ['control'], `Focused and its neighbour ${how}, focused ${dir === 'up' ? 'on top' : dir === 'down' ? 'at the bottom' : `on the ${dir}`}`, ['arrange', dir])
  }),
  b('Layout', 'l', [], 'Toggle tiled / floating layout', ['layout']),
  b('Layout', 'b', [], 'Balance the splits', ['balance']),
  b('Layout', 'r', [], 'Rotate the layout clockwise', ['rotate']),
  b('Layout', 'right_arrow', ['shift', 'option'], 'Rotate the layout clockwise', ['rotate', 'cw']),
  b('Layout', 'left_arrow', ['shift', 'option'], 'Rotate the layout counter-clockwise', ['rotate', 'ccw']),

  b('Apps', 'return_or_enter', [], 'New Ghostty window', ['term']),
  ...APPS.map(([key, mods, app]) => b('Apps', key, mods, app, ['app', app])),
  b('Apps', 'n', ['shift'], 'Neovim', ['nvim']),

  b('System', 'k', [], 'Show these hotkeys', ['hotkeys']),
  b('System', 'escape', [], 'System: lock, sleep, restart', ['system']),
  { group: 'System', key: 'up_arrow', mods: ['option'], label: 'Page Up', sends: 'page_up' },
  { group: 'System', key: 'down_arrow', mods: ['option'], label: 'Page Down', sends: 'page_down' },
]
