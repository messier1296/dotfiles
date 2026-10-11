local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.scrollback_lines = 10000
config.enable_tab_bar = false
config.use_ime = true
-- Keep ASCII and Nerd Font icons in the existing Fira Code family.
-- DemiLight is the OpenType weight 350 (Yu Gothic UI Semilight).
config.font = wezterm.font_with_fallback {
  { family = 'FiraCode Nerd Font Mono', weight = 'Regular' },
  { family = 'Yu Gothic UI', weight = 'DemiLight' },
}

-- Use Windows' default WSL distribution and its configured login shell.
-- No Windows username, Linux home directory, or distribution name is hardcoded.
if wezterm.target_triple:find('windows') then
  config.default_prog = { 'wsl.exe', '--cd', '~' }
end

-- Keep pane/tab/session management in Zellij. Use WezTerm for selection/copy.
config.keys = {
  { key = 'X', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateCopyMode },
  { key = 'C', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'V', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },
}

-- Keep WezTerm's bundled Nerd Font Symbols and emoji fallback.
return config
