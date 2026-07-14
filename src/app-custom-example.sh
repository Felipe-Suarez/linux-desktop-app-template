#!/bin/bash
# App Custom Example — reference implementation for the Linux Desktop App Template.
#
# This script demonstrates the dialog capabilities available to a desktop
# launcher. Each step is self-describing: it prints what it is about to do,
# then does it.
#
# The implementation notes for each technique are documented in docs/guide.md.

TITLE="App Custom Example"

echo "$TITLE — demonstration of available capabilities."
echo "This terminal window is itself one of them: the .desktop entry sets Terminal=true."
echo
echo "══════════════════════════════════════════════════════════════"
echo "  Six capabilities follow. Each one explains itself as it runs."
echo "══════════════════════════════════════════════════════════════"
echo

# ── Capability 1: terminal output ──
echo "[1/6] Terminal output — plain echo, visible because Terminal=true."
for i in 1 2 3; do
  echo "      counting... $i"
  sleep 0.6
done

# ── Capability 2: graphical progress bar ──
echo "[2/6] Progress bar — zenity --progress reads from stdin:"
echo "      a bare number sets the percentage, a line starting with # sets the label."
(
  echo "10" ; echo "# This is a progress bar."                   ; sleep 0.7
  echo "40" ; echo "# Numbers arriving on stdin set the percent" ; sleep 0.7
  echo "70" ; echo "# ...and lines starting with # set this text"; sleep 0.7
  echo "100"; echo "# Reaching 100 closes the dialog"            ; sleep 0.5
) | zenity --progress --title="$TITLE — 2/6" \
      --text="Starting..." --percentage=0 --auto-close --width=440

# ── Capability 3: desktop notification ──
echo "[3/6] Desktop notification — check the top right of the screen."
notify-send -i system-run "$TITLE" \
  "This is a desktop notification (notify-send). It is non-blocking: the script continues immediately."
sleep 1.5

# ── Capability 4: yes/no question (the exit status is the answer) ──
echo "[4/6] Question dialog — the answer is returned as an exit status (0=yes, 1=no)."
if zenity --question --title="$TITLE — 4/6" \
     --text="This is a <b>question</b> dialog.\n\nIt returns no text. It returns an <i>exit status</i>:\n0 if confirmed, 1 if declined or closed via the window manager.\n\nContinue?" \
     --ok-label="Yes, continue" --cancel-label="No" --width=460; then
  ANSWER="confirmed (exit status 0)"
else
  ANSWER="declined or dismissed (exit status 1)"
fi
echo "      -> $ANSWER"

# ── Capability 5: text entry ──
echo "[5/6] Text entry — this one does return the typed value on stdout."
INPUT=$(zenity --entry --title="$TITLE — 5/6" \
  --text="This is a <b>text entry</b> dialog.\n\nWhatever is typed here is returned on stdout and captured\ninto a shell variable. Cancelling returns an empty string." \
  --entry-text="type something here" --width=460)
if [ -n "$INPUT" ]; then
  ENTERED="received: «$INPUT»"
else
  ENTERED="nothing received (cancelled)"
fi
echo "      -> $ENTERED"

# ── Capability 6: closing summary ──
echo "[6/6] Information dialog — summarises the run and exits."
echo

# The summary embeds user-supplied text. Pango markup breaks on unescaped
# <, > and &, so the value is escaped first. See docs/guide.md, section 5.
SAFE=$(printf '%s' "$ENTERED" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

zenity --info --title="$TITLE — finished" \
  --text="This is an <b>information</b> dialog: a message and a single button.\n\n<b>Capabilities demonstrated:</b>\n• Terminal output (echo)\n• Progress bar (zenity --progress)\n• Desktop notification (notify-send)\n• Question dialog → $ANSWER\n• Text entry → $SAFE\n• This dialog (zenity --info)\n\nThe implementation notes for each technique are in\n<b>docs/guide.md</b> in the repository." \
  --ok-label="Close" --width=500

echo "-> Demonstration complete."
