<div align="center">

# ⇥ JustTab

**Hold Tab to see where you are. Let go, it's gone.**

An Oh My Zsh plugin that works like the scoreboard in a video game.

</div>

## ✨ About

On an empty command line, **hold Tab**: a panel opens right under your prompt with the current path and everything in the folder. **Release Tab**: the panel disappears, and your terminal is exactly as it was. Nothing ends up in your scrollback.

If you have already typed something, Tab does the normal completion, so you lose nothing.

```
╭─ you@host:~/Documents/Github/verdant-theme [main] ─────────────────────────╮
│                                                                            │
│  assets/                versions/              verdant3.0.zsh-theme        │
│  .git/                  README.md                                          │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│ 3 dossiers   2 fichiers                            relâche Tab pour fermer │
╰────────────────────────────────────────────────────────────────────────────╯
```

> In a real terminal, every entry gets its icon and the Verdant colors (this preview is plain text).

### Features

- ⇥ **Hold to show, release to hide**: the panel stays open exactly as long as your finger is on Tab, even for a very short press
- 📍 **Opens at the active line**, not at the top of the screen, and erases itself cleanly
- 🌿 **Matches the [Verdant theme](https://github.com/HorusExE69/verdant-theme)**: same colors, same file icons, same header as the prompt (user, host, path, Git branch)
- 📁 **Everything at a glance**: folders first, then files, hidden files included, laid out in columns like `ls`
- 🔢 **Counts** folders and files in the footer, and shows `… et N de plus` when the folder doesn't fit on the screen
- ⌨️ **Any other key closes it** and is typed normally; `Esc` and `Ctrl-C` just close it
- 🧩 **Normal completion untouched** as soon as there is text on the line

## ⚙️ How it works

Terminals don't tell programs when a key is *released*. JustTab gets around that in two ways:

1. **On X11** (the default on most Linux desktops, 42 computers included), a tiny C helper, `keywatch`, asks the X server every 4 ms whether the Tab key is physically down. The panel closes the instant you let go. The plugin compiles this helper automatically the first time you press Tab.
2. **Everywhere else** (ssh, Wayland, macOS, or no C compiler), it falls back to watching your keyboard's auto-repeat: the panel stays open while Tab keeps repeating. The timings are read from your keyboard settings (GNOME or `xset`). In this mode, a quick press shows the panel for about half a second, the time your keyboard waits before it starts repeating.

## 🚀 Installation

### 0. Requirements

- **Zsh** and **[Oh My Zsh](https://ohmyz.sh/)**
- For the exact release detection: an **X11 session**, a C compiler (`cc`) and the libX11 headers (`libx11-dev` on Debian/Ubuntu). Without them, JustTab uses the auto-repeat mode.
- For the icons: a **[Nerd Font](https://www.nerdfonts.com/)** in your terminal (see the [Verdant README](https://github.com/HorusExE69/verdant-theme#6-install-a-nerd-font-required-for-the-icons) for a no-`sudo` install)

### 1. Clone the plugin into Oh My Zsh

```bash
git clone git@github.com:HorusExE69/JustTab.git ~/.oh-my-zsh/custom/plugins/justtab
```

### 2. Enable it

In your `~/.zshrc`, add `justtab` to the plugin list:

```bash
plugins=(git justtab)
```

### 3. Reload your shell

```bash
exec zsh
```

Now go to an empty line and hold Tab. 🌱

### Best with Verdant

JustTab works with any theme, but it takes its icons from **[Verdant](https://github.com/HorusExE69/verdant-theme)** when that theme is loaded. Without Verdant, you get the same colors with simple folder, file and executable icons.

```bash
ZSH_THEME="verdant3.0"
```

## 🔧 Options

Add any of these to your `~/.zshrc`, **before** the line `source $ZSH/oh-my-zsh.sh`:

```bash
JUSTTAB_HIDDEN=false        # don't show dotfiles
JUSTTAB_HOLD_DELAY=0.55     # auto-repeat mode only: seconds before the first repeat
JUSTTAB_REPEAT_GAP=0.08     # auto-repeat mode only: seconds between two repeats
```

You only need the two delays if the auto-detection gets your keyboard wrong: the panel flickers while held (raise them) or closes too late (lower them).

## 🩺 Troubleshooting

- **The panel takes about half a second to close after a short press**: you are in auto-repeat mode. Run `justtab-status`: it tells you which mode JustTab is in and why. Usually `$DISPLAY` is empty, or `cc` / the libX11 headers are missing.
- **It still behaves like an old version**: terminals opened before an update keep the old code. Run `exec zsh` in each of them, or open a new one.
- **Empty squares instead of icons**: your terminal isn't using a Nerd Font.
- **Tab does nothing special**: another plugin (for example `fzf-tab`) may bind Tab after JustTab. Put `justtab` last in `plugins=(...)`.

## 🗑️ Uninstall

Remove `justtab` from `plugins=(...)` in your `~/.zshrc`, then:

```bash
rm -rf ~/.oh-my-zsh/custom/plugins/justtab
```
