# ==========================================
#  🌿 JUSTTAB — "hold Tab" overlay, like a game scoreboard
# ==========================================
#
# On an empty line, HOLD Tab: a panel opens right under the active line with
# the current path and everything in it. RELEASE Tab: the panel disappears and
# your terminal is exactly as before. With text on the line, Tab completes as usual.
#
# Release detection: on X11, a tiny helper (keywatch.c, compiled on first use)
# watches the physical Tab key, so the panel closes the instant you let go.
# Without X11 (ssh, Wayland…), it falls back to "Tab stopped auto-repeating",
# with timings read from your keyboard repeat settings.
#
# Options (in ~/.zshrc, before `source $ZSH/oh-my-zsh.sh`):
#
#   JUSTTAB_HOLD_DELAY=0.55   # seconds, > repeat delay (500 ms by default)
#   JUSTTAB_REPEAT_GAP=0.08   # seconds, > time between two repeats (30 ms)
#   JUSTTAB_HIDDEN=true       # false = hide dotfiles
#
# Colors and icons come from the verdant theme when it is loaded.

# Set by you in ~/.zshrc? Then keep it, otherwise read the keyboard settings
(( $+JUSTTAB_HOLD_DELAY )) && _justtab_user_hold=1
(( $+JUSTTAB_REPEAT_GAP )) && _justtab_user_gap=1
: ${JUSTTAB_HOLD_DELAY:=0.55}
: ${JUSTTAB_REPEAT_GAP:=0.08}
: ${JUSTTAB_HIDDEN:=true}

# Verdant palette (same values as verdant3.0)
typeset -gA _TM_C
_TM_C=(
	red     $'\e[38;2;242;167;195m'
	green   $'\e[38;2;168;220;197m'
	yellow  $'\e[38;2;245;214;165m'
	blue    $'\e[38;2;185;167;232m'
	magenta $'\e[38;2;217;160;213m'
	cyan    $'\e[38;2;168;216;232m'
	white   $'\e[38;2;245;234;240m'
	grey    $'\e[38;2;120;108;130m'
	lgrey   $'\e[38;2;155;145;165m'
	bold    $'\e[1m'
	reset   $'\e[0m'
)

# Visible width of a string (colors removed, wide chars counted twice)
function _justtab_width {
	setopt local_options extended_glob
	local s=${1//$'\e'\[[0-9;]#m/}
	REPLY=${(m)#s}
}

# Icon + colors for one entry → _vls_icon, _vls_ic, _vls_nc
function _justtab_style {
	if (( $+functions[_verdant_ls_style] )); then
		_verdant_ls_style "$1" "$1"
		return
	fi
	# Theme not loaded: simple fallback
	if [[ -d $1 ]]; then
		_vls_icon=$'\uf07b' _vls_ic=$_TM_C[red] _vls_nc=$_TM_C[bold]$_TM_C[red]
	elif [[ -x $1 ]]; then
		_vls_icon=$'\uf489' _vls_ic=$_TM_C[green] _vls_nc=$_TM_C[bold]$_TM_C[green]
	else
		_vls_icon=$'\uf15b' _vls_ic=$_TM_C[white] _vls_nc=$_TM_C[white]
		[[ $1 == .* ]] && _vls_nc=$_TM_C[lgrey]
	fi
}

# One framed line: │ <content><padding> │
function _justtab_row {
	local -i inner=$2
	_justtab_width "$1"
	local -i pad=$(( inner - REPLY ))
	(( pad < 0 )) && pad=0
	print -r -- "$_TM_C[red]│$_TM_C[reset] $1${(l:pad:: :)} $_TM_C[red]│$_TM_C[reset]"
}

# Draw the whole panel on stdout
function _justtab_render {
	emulate -L zsh
	setopt extended_glob
	[[ $JUSTTAB_HIDDEN == true ]] && setopt glob_dots

	local C_r=$_TM_C[red] C_0=$_TM_C[reset]
	local -i W=${COLUMNS:-80} H=${LINES:-24}
	local -i inner=$(( W - 4 ))   # "│ " + content + " │"
	(( inner < 10 )) && inner=10
	local hbar='─'

	# ---- entries: folders first, then files ----
	local -a dirs files ent cells widths
	dirs=( *(N-/) )
	files=( *(N^-/) )
	ent=( ${(oi)dirs} ${(oi)files} )

	local name cell
	local -i i n=${#ent} maxw=0 w
	for name in $ent; do
		_justtab_style "$name"
		_justtab_width "$name"
		w=$(( REPLY + 2 ))
		if (( w > inner )); then
			# Very long name: cut it
			name="${name[1,inner-4]}…"
			_justtab_width "$name"; w=$(( REPLY + 2 ))
		fi
		cells+=( "$_vls_ic$_vls_icon $_vls_nc$name$C_0" )
		widths+=( $w )
		(( w > maxw )) && maxw=w
	done

	# ---- header, like the verdant prompt ----
	local leaf=${VERDANT_LEAF:-🌿}
	local branch=$(command git symbolic-ref --short HEAD 2>/dev/null \
		|| command git rev-parse --short HEAD 2>/dev/null)
	local who="$_TM_C[blue]${USER:-$(whoami)}$_TM_C[magenta]@$_TM_C[blue]${HOST%%.*}$_TM_C[magenta]:"
	local git=${branch:+" $_TM_C[cyan][$branch]"}
	_justtab_width "$leaf $who$git"
	local -i room=$(( W - 7 - REPLY ))   # "╭─" + " " + title + " " + "─╮"
	(( room < 5 )) && room=5
	local where=${(%):-%${room}<…<%~}
	local title="$_TM_C[green]$leaf $who$_TM_C[green]$_TM_C[bold]$where$C_0$git"
	_justtab_width "$title"
	local -i fill=$(( W - 6 - REPLY ))
	(( fill < 0 )) && fill=0
	print -r -- "$C_r╭$hbar$C_0 $title $C_r${(l:fill::─:)}$hbar╮$C_0"
	_justtab_row "" $inner

	# ---- grid (column-major, like ls) ----
	local -i colw=$(( maxw + 2 ))
	local -i cols=$(( (inner + 2) / colw ))
	(( cols < 1 )) && cols=1
	(( cols > n )) && cols=n
	local -i rows=$(( n ? (n + cols - 1) / cols : 0 ))
	# space left on screen: header + 2 blanks + separator + footer + bottom + prompt
	local -i maxrows=$(( H - 7 ))
	(( maxrows < 1 )) && maxrows=1
	local -i hidden=0
	if (( rows > maxrows )); then
		rows=$(( maxrows - 1 ))
		(( rows < 1 )) && rows=1
		hidden=$(( n - rows * cols ))
		(( hidden < 0 )) && hidden=0
	fi

	if (( n == 0 )); then
		_justtab_row "$_TM_C[grey]  (dossier vide)$C_0" $inner
	fi

	local line
	local -i r c pad
	for (( r = 0; r < rows; r++ )); do
		line=
		for (( c = 0; c < cols; c++ )); do
			i=$(( c * rows + r + 1 ))
			(( i > n || i > rows * cols )) && break
			line+=$cells[i]
			if (( c < cols - 1 )); then
				pad=$(( colw - widths[i] ))
				line+=${(l:pad:: :)}
			fi
		done
		_justtab_row "$line" $inner
	done
	(( hidden )) && _justtab_row "$_TM_C[grey]… et $hidden de plus$C_0" $inner

	# ---- footer ----
	_justtab_row "" $inner
	print -r -- "$C_r├${(l:W-2::─:)}┤$C_0"
	local -i nd=${#dirs} nf=${#files}
	local stats="$_TM_C[red]$_TM_C[bold]$nd$C_0$_TM_C[lgrey] dossier${${nd:#[01]}:+s}$C_0"
	stats+="   $_TM_C[white]$_TM_C[bold]$nf$C_0$_TM_C[lgrey] fichier${${nf:#[01]}:+s}$C_0"
	local hint="$_TM_C[grey]relâche Tab pour fermer$C_0"
	_justtab_width "$stats"; local -i sw=$REPLY
	_justtab_width "$hint"
	local -i gap=$(( inner - sw - REPLY ))
	if (( gap >= 2 )); then
		_justtab_row "$stats${(l:gap:: :)}$hint" $inner
	else
		_justtab_row "$stats" $inner
	fi
	print -rn -- "$C_r╰${(l:W-2::─:)}╯$C_0"
}

# The widget bound to Tab
function _justtab_widget {
	if [[ -n $BUFFER ]]; then
		zle ${_justtab_fallback:-expand-or-complete}
		return
	fi

	(( $+_justtab_timings )) || _justtab_detect_timings

	local key more resp panel line
	local -F wait=$JUSTTAB_HOLD_DELAY
	local -A ready
	local -i kfd=-1 tfd=-1 exact=0

	# Watch the real Tab key (X11): closes the very moment you release it
	if [[ -n $DISPLAY ]] && _justtab_build_keywatch; then
		exec {kfd}< <("$_justtab_keywatch" 2>/dev/null)
		exec {tfd}<$TTY
		exact=1
	fi

	panel=$(_justtab_render)
	local -i P=${#${(f)panel}}

	# Where is the cursor? (row, to know if the screen will scroll)
	print -rn -- $'\e[6n' >$TTY
	read -s -t 0.3 -d R resp <$TTY
	local -i row=${${resp##*\[}%%;*}
	(( row < 1 || row > LINES )) && row=LINES
	local -i scrolled=$(( row + P - LINES ))
	(( scrolled < 0 )) && scrolled=0

	# Draw the panel right under the active line
	local crlf=$'\r\n'
	print -rn -- $'\e[?25l\e7\r\n'"${panel//$'\n'/$crlf}" >$TTY

	if (( exact )); then
		# Stay open until the key watcher says Tab is up
		while zselect -A ready -r $kfd -r $tfd; do
			if (( ${+ready[$kfd]} )); then
				# "up" = released; nothing = watcher failed → timing mode
				read -r -u $kfd line || exact=0
				break
			fi
			read -s -k 1 -u $tfd key || break
			[[ $key == $'\t' ]] && continue        # auto-repeat: ignore
			_justtab_other_key "$key" $tfd
			break
		done
	fi
	if (( ! exact )); then
		# No X11: stay open while Tab keeps auto-repeating
		while read -s -k 1 -t $wait key; do
			if [[ $key != $'\t' ]]; then
				_justtab_other_key "$key"
				break
			fi
			wait=$JUSTTAB_REPEAT_GAP
		done
	fi
	(( kfd >= 0 )) && exec {kfd}<&-
	(( tfd >= 0 )) && exec {tfd}<&-

	# Back to the active line (minus the lines the screen scrolled), erase below
	print -rn -- $'\e8' >$TTY
	(( scrolled )) && print -rn -- $'\e['${scrolled}A >$TTY
	print -rn -- $'\e[J\e[?25h' >$TTY
	zle -R
}

# Another key while open: close, and give that key back to the line editor
# (Esc and Ctrl-C just close)
function _justtab_other_key {
	local key=$1 more
	if [[ -n $2 ]]; then
		while read -s -k 1 -t 0.01 -u $2 more; do key+=$more; done
	else
		while read -s -k 1 -t 0.01 more; do key+=$more; done
	fi
	[[ $key != ($'\e'|$'\C-c') ]] && zle -U -- "$key"
}

# Compile the little X11 key watcher once (needs a C compiler + libX11 headers)
function _justtab_build_keywatch {
	[[ -x $_justtab_keywatch ]] && return 0
	(( $+_justtab_keywatch_failed )) && return 1
	local src=$_justtab_dir/keywatch.c
	if [[ -r $src ]] && (( $+commands[cc] )) \
		&& cc -O2 -o $_justtab_keywatch $src -lX11 2>/dev/null; then
		return 0
	fi
	typeset -g _justtab_keywatch_failed=1
	return 1
}

# Closing delays from the real keyboard repeat settings (GNOME, then X11)
function _justtab_detect_timings {
	setopt local_options extended_glob
	typeset -g _justtab_timings=1
	local -i delay=0 interval=0
	if (( $+commands[gsettings] )); then
		local g=$(gsettings get org.gnome.desktop.peripherals.keyboard delay 2>/dev/null)
		delay=${${g##*[^0-9]}:-0}
		g=$(gsettings get org.gnome.desktop.peripherals.keyboard repeat-interval 2>/dev/null)
		interval=${${g##*[^0-9]}:-0}
	fi
	if (( ! delay || ! interval )) && (( $+commands[xset] )) && [[ -n $DISPLAY ]]; then
		local q=$(xset q 2>/dev/null)
		[[ $q == (#b)*delay:\ #([0-9]##)\ #repeat\ rate:\ #([0-9]##)* ]] \
			&& delay=$match[1] interval=$(( 1000 / match[2] ))
	fi
	(( delay && interval )) || return
	# Just over the first repeat, and ~2 repeats of margin after that
	[[ $_justtab_user_hold != 1 ]] && JUSTTAB_HOLD_DELAY=$(( (delay + 40) / 1000.0 ))
	[[ $_justtab_user_gap  != 1 ]] && JUSTTAB_REPEAT_GAP=$(( (2 * interval + 15) / 1000.0 ))
}

zle -N _justtab_widget
zmodload zsh/zselect 2>/dev/null
typeset -g _justtab_dir=${0:A:h}
typeset -g _justtab_keywatch=$_justtab_dir/keywatch

# Keep whatever Tab did before (oh-my-zsh may use expand-or-complete-with-dots)
if [[ -z $_justtab_fallback ]]; then
	_justtab_fallback=${${(z)"$(bindkey '^I')"}[2]}
	[[ -z $_justtab_fallback || $_justtab_fallback == _justtab_widget ]] \
		&& _justtab_fallback=expand-or-complete
fi
bindkey '^I' _justtab_widget
