// The fn layer: one entry per key combination (docs/superpowers/specs/2026-11-07-yabai-omarchy-design.md,
// "Key layout"). fn is always required and is not listed in `mods`. An entry either runs `yb <args>`
// (config/bin/yb) or sends a key (`key`). build.ts turns this table into Karabiner rules and hotkeys.json.
// Each entry also carries what the kb Hotkeys command shows: a description and, for most, a picture spec,
// which kb draws (kb: specs/006-hotkey-pictures/spec.md; the kinds below are the contract between the repos).

export type Group = 'Spaces' | 'Windows' | 'Layout' | 'Apps' | 'System'
export type Mod = 'shift' | 'option' | 'control'

type Compass = 'west' | 'east' | 'north' | 'south'
type Side = 'left' | 'right' | 'up' | 'down'
export type Picture =
  | { kind: 'space'; n: number }
  | { kind: 'send-to-space'; n: number; stay: boolean }
  | { kind: 'space-cycle'; dir: 'next' | 'prev' | 'recent' }
  | { kind: 'focus'; dir: Compass }
  | { kind: 'swap'; dir: Compass }
  | { kind: 'screen'; dir: 'west' | 'east' }
  | { kind: 'send-screen'; dir: 'west' | 'east' }
  | { kind: 'close' }
  | { kind: 'float' }
  | { kind: 'zoom'; scope: 'full' | 'parent' }
  | { kind: 'pin' }
  | { kind: 'scratchpad'; send: boolean }
  | { kind: 'resize'; step: 'w-' | 'w+' | 'h-' | 'h+' }
  | { kind: 'split'; orientation: 'vertical' | 'horizontal' }
  | { kind: 'arrange'; dir: Side }
  | { kind: 'layout' }
  | { kind: 'balance' }
  | { kind: 'rotate'; dir: 'cw' | 'ccw' }
  | { kind: 'new-window' }

export type Binding = Readonly<{
  key: string
  mods: readonly Mod[]
  label: string
  group: Group
  description: string
  picture?: Picture
  yb?: readonly string[]
  sends?: string
}>

const b = (
  group: Group,
  key: string,
  mods: readonly Mod[],
  label: string,
  yb: readonly string[],
  description: string,
  picture?: Picture
): Binding => ({ group, key, mods, label, yb, description, ...(picture ? { picture } : {}) })

const DIGITS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'] as const
const ARROWS = [
  ['left_arrow', 'west'],
  ['right_arrow', 'east'],
  ['up_arrow', 'north'],
  ['down_arrow', 'south'],
] as const
const NEXT_TO = { west: 'to the left of', east: 'to the right of', north: 'above', south: 'below' } as const
const APPS = [
  ['f', ['shift'], 'Finder'],
  ['c', ['shift'], 'Claude'],
  ['v', ['shift'], 'Visual Studio Code'],
  ['g', ['shift'], 'Gemini'],
] as const

const slot = (i: number) => String(i + 1)
const screenOf = (i: number) => (i < 5 ? 'built-in' : 'external')

export const bindings: readonly Binding[] = [
  ...DIGITS.map((key, i) =>
    b('Spaces', key, [], `Go to space ${slot(i)}`, ['space', slot(i)], `Shows space ${slot(i)}, on the ${screenOf(i)} screen.`, {
      kind: 'space',
      n: i + 1,
    })
  ),
  ...DIGITS.map((key, i) =>
    b(
      'Spaces',
      key,
      ['shift'],
      `Move window to space ${slot(i)}`,
      ['move', slot(i)],
      `Sends the focused window to space ${slot(i)} and follows it there.`,
      { kind: 'send-to-space', n: i + 1, stay: false }
    )
  ),
  ...DIGITS.map((key, i) =>
    b(
      'Spaces',
      key,
      ['shift', 'option'],
      `Move window to space ${slot(i)}, stay here`,
      ['move', slot(i), '--stay'],
      `Sends the focused window to space ${slot(i)} and keeps you on the space you are on.`,
      { kind: 'send-to-space', n: i + 1, stay: true }
    )
  ),
  b('Spaces', 'tab', [], 'Next space on this screen', ['space', 'next'],
    'Goes to the next space on the screen you are on, back to the first after the last.', { kind: 'space-cycle', dir: 'next' }),
  b('Spaces', 'tab', ['shift'], 'Previous space on this screen', ['space', 'prev'],
    'Goes to the previous space on the screen you are on, round to the last from the first.', { kind: 'space-cycle', dir: 'prev' }),
  b('Spaces', 'tab', ['control'], 'Last space you were on', ['space', 'recent'],
    'Goes back to the space you were on before, like ⌘ Tab does for apps.', { kind: 'space-cycle', dir: 'recent' }),

  ...ARROWS.map(([key, dir]) =>
    b('Windows', key, [], `Focus window ${dir}`, ['focus', dir],
      `Moves the focus to the window ${NEXT_TO[dir]} the focused one; at the edge it moves to the next screen.`, { kind: 'focus', dir })
  ),
  ...ARROWS.map(([key, dir]) =>
    b('Windows', key, ['shift'], `Swap window ${dir}`, ['swap', dir],
      `Swaps the focused window with the one ${NEXT_TO[dir]} it; the focus stays on your window.`, { kind: 'swap', dir })
  ),
  b('Windows', 'open_bracket', [], 'Focus the screen west', ['screen', 'west'],
    'Moves the focus to the screen on the left.', { kind: 'screen', dir: 'west' }),
  b('Windows', 'close_bracket', [], 'Focus the screen east', ['screen', 'east'],
    'Moves the focus to the screen on the right.', { kind: 'screen', dir: 'east' }),
  b('Windows', 'open_bracket', ['shift'], 'Send window to the screen west', ['send-display', 'west'],
    'Sends the focused window to the screen on the left and follows it.', { kind: 'send-screen', dir: 'west' }),
  b('Windows', 'close_bracket', ['shift'], 'Send window to the screen east', ['send-display', 'east'],
    'Sends the focused window to the screen on the right and follows it.', { kind: 'send-screen', dir: 'east' }),
  b('Windows', 'w', [], 'Close window', ['close'], 'Closes the focused window, like ⌘ W in most apps.', { kind: 'close' }),
  b('Windows', 't', [], 'Toggle tiled / floating', ['float'],
    'Lifts the focused window out of the tiling so it floats; press again to tile it back.', { kind: 'float' }),
  b('Windows', 'f', [], 'Fullscreen inside the space', ['zoom', 'full'],
    'Makes the focused window fill the space while the others wait behind it; the outline turns amber. Press again to restore.',
    { kind: 'zoom', scope: 'full' }),
  b('Windows', 'f', ['option'], 'Full width (fill the parent split)', ['zoom', 'parent'],
    'Makes the focused window fill its parent split, such as the whole width of a stack. Press again to restore.',
    { kind: 'zoom', scope: 'parent' }),
  b('Windows', 'o', [], 'Pin: floating, on top, on every space', ['pin'],
    'Keeps the focused window floating, above the others and on every space. Press again to unpin. Needs the scripting addition.',
    { kind: 'pin' }),
  b('Windows', 's', [], 'Toggle the scratchpad', ['scratchpad'],
    'Shows or hides the scratchpad window, a window kept out of the way until you call it. Needs the scripting addition.',
    { kind: 'scratchpad', send: false }),
  b('Windows', 's', ['option'], 'Send window to the scratchpad', ['scratchpad', '--send'],
    'Makes the focused window the scratchpad window and hides it until fn + s brings it back.', { kind: 'scratchpad', send: true }),
  b('Windows', 'hyphen', [], 'Narrower', ['resize', 'w-'], 'Makes the focused window narrower by moving its side split.',
    { kind: 'resize', step: 'w-' }),
  b('Windows', 'equal_sign', [], 'Wider', ['resize', 'w+'], 'Makes the focused window wider by moving its side split.',
    { kind: 'resize', step: 'w+' }),
  b('Windows', 'hyphen', ['shift'], 'Shorter', ['resize', 'h-'], 'Makes the focused window shorter by moving the split above or below it.',
    { kind: 'resize', step: 'h-' }),
  b('Windows', 'equal_sign', ['shift'], 'Taller', ['resize', 'h+'], 'Makes the focused window taller by moving the split above or below it.',
    { kind: 'resize', step: 'h+' }),

  b('Layout', 'backslash', ['shift'], 'Focused window and its neighbour side by side (|)', ['split', 'vertical'],
    'Places the focused window and its neighbour side by side, split by a vertical line.', { kind: 'split', orientation: 'vertical' }),
  b('Layout', 'backslash', [], 'Focused window and its neighbour one above the other (\\)', ['split', 'horizontal'],
    'Places the focused window and its neighbour one above the other, split by a horizontal line.',
    { kind: 'split', orientation: 'horizontal' }),
  ...ARROWS.map(([key]) => {
    const dir = ({ left_arrow: 'left', right_arrow: 'right', up_arrow: 'up', down_arrow: 'down' } as const)[key]
    const how = dir === 'left' || dir === 'right' ? 'side by side' : 'one above the other'
    const where = dir === 'up' ? 'on top' : dir === 'down' ? 'at the bottom' : `on the ${dir}`
    return b('Layout', key, ['control'], `Focused and its neighbour ${how}, focused ${where}`, ['arrange', dir],
      `Arranges the focused window and its neighbour ${how}, with the focused one ${where}.`, { kind: 'arrange', dir })
  }),
  b('Layout', 'l', [], 'Toggle tiled / floating layout', ['layout'],
    'Switches this space between tiled (windows share the screen) and floating (windows stay where you put them).', { kind: 'layout' }),
  b('Layout', 'b', [], 'Balance the splits', ['balance'], 'Gives every window in this space an equal share again after resizing.',
    { kind: 'balance' }),
  b('Layout', 'right_arrow', ['shift', 'option'], 'Rotate the layout clockwise', ['rotate', 'cw'],
    'Turns the whole layout of this space a quarter clockwise: side by side becomes one above the other.', { kind: 'rotate', dir: 'cw' }),
  b('Layout', 'left_arrow', ['shift', 'option'], 'Rotate the layout counter-clockwise', ['rotate', 'ccw'],
    'Turns the whole layout of this space a quarter counter-clockwise.', { kind: 'rotate', dir: 'ccw' }),

  b('Apps', 'return_or_enter', [], 'New Ghostty window', ['term'],
    'Opens a new Ghostty window on the focused screen, also when Ghostty is already in front.', { kind: 'new-window' }),
  b('Apps', 'return_or_enter', ['shift'], 'New tab in the default browser', ['browser'],
    "Opens a new tab in the default browser's front window, or a first window when it has none.", { kind: 'new-window' }),
  b('Apps', 'return_or_enter', ['shift', 'option'], 'New default browser window', ['browser', '--window'],
    'Opens a new window of the default browser on the focused screen.', { kind: 'new-window' }),
  ...APPS.map(([key, mods, app]) =>
    b('Apps', key, mods, app, ['app', app], `Opens ${app}, or brings it to the front when it is already running.`, { kind: 'new-window' })
  ),
  b('Apps', 'n', ['shift'], 'Neovim', ['nvim'], 'Opens Neovim in a new Ghostty window.', { kind: 'new-window' }),
  b('Apps', 'q', [], 'Raycast Notes (instead of Quick Note)', ['notes'],
    "Opens Raycast Notes; this key no longer opens macOS's Quick Note.", { kind: 'new-window' }),

  b('System', 'k', [], 'Show these hotkeys', ['hotkeys'], 'Opens this list: every fn-layer hotkey, searchable, with what it does.'),
  b('System', 'escape', [], 'System: lock, sleep, restart', ['system'], 'Opens the kb System list: lock the screen, sleep or restart.'),
  {
    group: 'System',
    key: 'up_arrow',
    mods: ['option'],
    label: 'Page Up',
    sends: 'page_up',
    description: 'Scrolls one page up, for keyboards without a Page Up key.',
  },
  {
    group: 'System',
    key: 'down_arrow',
    mods: ['option'],
    label: 'Page Down',
    sends: 'page_down',
    description: 'Scrolls one page down, for keyboards without a Page Down key.',
  },
]
