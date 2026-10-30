# Guide — Building Desktop Applications with Shell Scripts and Zenity

Reference documentation for the Linux Desktop App Template.

Audience: developers building their own launchers, and AI coding agents
generating applications from this template. Sections 1–4 describe the
procedure. Section 6 documents failure modes that are silent and therefore
expensive to rediscover.

Target platform: Linux with a freedesktop-compliant desktop environment.
Developed and verified against GNOME with zenity 4.x.

---

## 1. Definition

A desktop application in this context is not an AppImage. An AppImage bundles
an entire program and its libraries into a single portable binary. That is a
different mechanism.

This template produces a **launcher**: a plain-text `.desktop` entry that
instructs the desktop environment to execute a script when the icon is
activated. The result consists of two text files:

| File | Responsibility |
|---|---|
| The script | Performs the work |
| The `.desktop` entry | Registers the clickable icon that invokes it |

The approach requires no compilation or packaging, and every component remains
readable and editable with a text editor.

---

## 2. File Locations

| Path | Purpose |
|---|---|
| `~/scripts/<name>.sh` | The script. Any directory is acceptable; a single location keeps related files together. |
| `~/.local/share/applications/<name>.desktop` | **Required for system registration.** Determines whether the application appears in the activities overview and whether it can be pinned to the dock. |
| `<desktop>/<name>.desktop` | Optional standalone desktop icon. An independent copy, not a symlink. |

The GNOME activities overview does not scan the desktop directory. A `.desktop`
entry present only on the desktop will not appear in the overview and cannot be
pinned. Installation into `~/.local/share/applications/` is therefore the
default, not an option.

Put differently: the entry in `~/.local/share/applications/` **is** the
application. The copy on the desktop is only a shortcut to the same script,
optional and independent; deleting it does not uninstall anything.

The desktop directory name is localised (`Desktop`, `Escritorio`, `Bureau`,
and others). It must be resolved at runtime rather than hardcoded:

```bash
DESKTOP_DIR="$(xdg-user-dir DESKTOP)"
```

---

## 3. The .desktop Entry

```ini
[Desktop Entry]
Type=Application
Version=1.0
Name=App Custom Example              # label shown beneath the icon
Comment=Example launcher             # tooltip on hover
Exec=/home/user/scripts/app.sh       # absolute path; see below
Icon=system-run                      # icon theme name, without extension
Terminal=true                        # open a visible terminal window?
Categories=Development;              # exactly one primary category
```

### Constraints

**`Exec` does not perform shell expansion.** Neither `~` nor `$HOME` is
resolved. The value must be an absolute path. This is why a `.desktop` entry
cannot be committed to a repository in usable form: the correct path is not
known until installation. This template commits a `.desktop.template`
containing the placeholder `__EXEC_PATH__` and substitutes it during
installation.

**`Icon` names a theme icon, not a file path.** Available names can be listed
with `ls /usr/share/icons/*/48x48/apps/`. Widely available choices include
`system-run`, `text-x-script`, `utilities-terminal`,
`applications-development` and `application-x-executable`. An absolute path to
an image file is also accepted.

**`Categories` accepts exactly one primary category.** Supplying more than one
(for example `Development;Utility;`) causes the application to appear multiple
times in the menu.

**`StartupWMClass` associates open windows with the entry.** It is unnecessary
while the script only shows its own dialogs. When the script opens a window of
another program, the window is attributed to that program unless this key
matches the window's class. See section 6.

**Validate before assuming correctness:**

```bash
desktop-file-validate ~/.local/share/applications/myapp.desktop
```

---

## 4. Procedure for a New Application

**Step 1 — Write the script.** Begin from the minimal template in section 7.

```bash
nano ~/scripts/myapp.sh
```

**Step 2 — Make it executable.** Without this, activating the icon has no
effect and reports no error.

```bash
chmod +x ~/scripts/myapp.sh
```

**Step 3 — Execute it from a terminal before creating the launcher.** A script
that fails here will fail through the launcher as well, but without displaying
the reason.

```bash
~/scripts/myapp.sh
```

**Step 4 — Create the `.desktop` entry** using the template in section 3, with
an absolute path in `Exec`.

**Step 5 — Register it with the system.** This step is required and frequently
omitted.

```bash
chmod +x ~/.local/share/applications/myapp.desktop
update-desktop-database ~/.local/share/applications
```

The application should now appear in the activities overview.

**Step 6 — Pin to the dock (optional).** Either right-click the icon in the
overview and select "Pin to Dash", or append it to the existing list. Pinning
works from the overview whether or not the application is running:

```bash
gsettings get org.gnome.shell favorite-apps
gsettings set org.gnome.shell favorite-apps "['...existing entries...', 'myapp.desktop']"
```

**Step 7 — Place a shortcut on the desktop (optional).** This copies the
entry; the application from step 5 is unaffected and remains the one to pin.

```bash
cp ~/.local/share/applications/myapp.desktop "$(xdg-user-dir DESKTOP)/"
chmod +x "$(xdg-user-dir DESKTOP)/myapp.desktop"
gio set "$(xdg-user-dir DESKTOP)/myapp.desktop" metadata::trusted true
```

GNOME may still require "Allow Launching" via the context menu on first use.

**Step 8 — Uninstallation.** There is no graphical route. GNOME exposes an
"Uninstall" action only for applications owned by a package manager (apt,
Flatpak, Snap); an entry in `~/.local/share/applications/` has no owning
package, so the action is absent. A trusted desktop icon is presented as an
application rather than as a file, so the usual file operations are absent from
its context menu as well. Uninstallation means deleting the installed files:

```bash
rm -f ~/.local/share/applications/myapp.desktop
rm -f "$(xdg-user-dir DESKTOP)/myapp.desktop"
rm -f ~/scripts/myapp.sh
update-desktop-database ~/.local/share/applications
```

If the application was pinned, remove it from `favorite-apps` as well, or a
broken icon remains in the dock:

```bash
gsettings get org.gnome.shell favorite-apps
gsettings set org.gnome.shell favorite-apps "['...remaining entries...']"
```

Any installer should provide this path. `install.sh --uninstall` in this
repository implements it, favourites cleanup included.

---

## 5. Available Capabilities

The reference application demonstrates each of these in sequence.

| Command | Behaviour |
|---|---|
| `zenity --info` | Message with a single button |
| `zenity --question` | Yes/no prompt; the answer is the exit status |
| `zenity --entry` | Single-line text input |
| `zenity --list` | Selection list |
| `zenity --progress` | Progress bar, driven by stdin |
| `zenity --text-info` | Scrollable text window |
| `zenity --file-selection` | File chooser |
| `zenity --error` | Error message |
| `notify-send` | Desktop notification |
| `xdg-open <url\|file>` | Open in the registered default application |
| `kdialog` | Qt-based alternative to zenity, with different syntax |

### Zenity notes

**Exit status carries the answer.** `0` indicates confirmation; `1` indicates
cancellation or dismissal via the window manager:

```bash
if zenity --question --text="Proceed?"; then
  # confirmed
fi
```

**`--text` accepts Pango markup** (`<b>`, `<i>`, `\n`). Markup parsing fails on
unescaped `<`, `>` and `&`. Any dynamic content — command output, log
excerpts, user input — must be escaped before interpolation:

```bash
safe=$(printf '%s' "$value" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
```

Order matters: `&` must be escaped first. Escaping `<` first produces `&lt;`,
whose ampersand is then escaped again, rendering the literal text `&amp;lt;`.

---

## 6. Failure Modes

The following behaviours produce no error message. They are documented here
because they are difficult to diagnose from symptoms alone.

### Terminal=true versus Terminal=false

`Terminal=true` opens a visible terminal window. Standard output is visible in
real time, which is useful for demonstrations, progress reporting and
debugging.

`Terminal=false` produces no window. This is preferable for production
launchers, but it means **failures are entirely invisible to the user**. When
using `Terminal=false`, every error path must terminate in a `zenity --error`
dialog, or the application will appear to do nothing at all.

### Terminating a background process when its window closes

To tie a process lifetime to a dialog: start the process in the background,
record its PID, and display a **blocking** dialog. The process remains alive
while the dialog is open. When the dialog closes, the script resumes and a
`trap` terminates the process.

```bash
myprocess &
PID=$!
cleanup() {
  kill -TERM "$PID" 2>/dev/null
  for _ in $(seq 1 50); do kill -0 "$PID" 2>/dev/null || break; sleep 0.1; done
  kill -KILL "$PID" 2>/dev/null
}
trap cleanup EXIT INT TERM
zenity --info --text="Running. Closing this window stops the process." --ok-label="Stop"
```

### Processes that read stdin terminate immediately under Terminal=false

Long-running processes that accept commands on standard input — protocol
servers, REPLs and interactive CLIs among them — shut down on receiving EOF.
Under `Terminal=true` they behave correctly, because the terminal holds stdin
open. Under `Terminal=false` **no stdin is attached**: the process receives EOF
at startup, initialises, and exits within a second. The characteristic symptom
is a log containing a startup line followed immediately by a shutdown line.

The fix is to supply a FIFO opened for both reading and writing, which never
reports EOF for as long as the script holds the descriptor:

```bash
FIFO=$(mktemp -u); mkfifo "$FIFO"
exec 9<>"$FIFO"                    # descriptor 9 stays open
myserver <&9 >"$LOG" 2>&1 &
PID=$!
# on exit:  exec 9>&-; rm -f "$FIFO"
```

### /dev/tcp is unavailable outside bash

`/dev/tcp/host/port` is a bash-specific feature. It does not exist in zsh,
dash or POSIX sh, where it fails with a "no such file or directory" error. A
`#!/bin/bash` shebang protects the script itself, but the construct will fail
when the code is sourced or reused from another shell.

Use tools that behave consistently across shells:

```bash
ss -ltn | grep -q ":8080 "                      # is the port bound?
curl -s -o /dev/null --max-time 2 "$URL"        # does it actually respond?
```

These answer different questions. A bound port does not imply a working
service, and a port may be held by an unrelated process. When starting a
server, check for an existing listener before binding, and do not terminate
whatever is found: it may not belong to the application.

### Waiting for readiness

A fixed `sleep` is unreliable in both directions: too short and the resource is
not ready, too long and startup is needlessly slow. Poll with an upper bound,
and check on each iteration that the process has not already exited:

```bash
for _ in $(seq 1 150); do                       # 150 × 0.1s = 15s ceiling
  curl -s -o /dev/null --max-time 2 "$URL" && break
  kill -0 "$PID" 2>/dev/null || { zenity --error --text="Process exited during startup"; exit 1; }
  sleep 0.1
done
```

### Temporary files

Create them with `mktemp` and remove them in the `trap`, so that repeated runs
do not accumulate files:

```bash
LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT
```

### Windows of another program appear under that program's icon

GNOME attributes an open window to an application by comparing the window's
class (`WM_CLASS` on X11, `app_id` on Wayland) with the `StartupWMClass` key,
or with the `.desktop` file name. When the script opens a window that belongs
to another program (a browser in app mode, an editor, a viewer), the class is
that program's. The dock then shows a second icon, or groups the window under
the other program, and "Pin to Dash" on the running window pins the wrong
application.

The fix is to set `StartupWMClass` to the class the window actually reports.
It is not always the obvious value. Google Chrome launched with
`--app=http://localhost:<port>` under Wayland reports
`chrome-localhost__-Default`: the host without the port, the path with `/`
replaced, and the profile directory name. Its `--class` flag does not change
that `app_id`.

```ini
StartupWMClass=chrome-localhost__-Default
```

To read a window's class, open Looking Glass (<kbd>Alt</kbd>+<kbd>F2</kbd>,
`lg`) and check the Windows tab. `xprop` does not see native Wayland windows,
and GNOME's introspection D-Bus API refuses callers by default.

### pgrep -f matches the querying command

`pgrep -f "myprocess --flag"` matches any process whose command line contains
that string — including the shell command performing the check. This produces
false positives when verifying whether a process has terminated. Test a known
PID with `kill -0 "$PID"`, or inspect the parent with `ps -o ppid= -p "$PID"`.
Note also that `pgrep -x` does not match process names longer than 15
characters.

---

## 7. Minimal Template

**`~/scripts/myapp.sh`**

```bash
#!/bin/bash
# One-line description of what this application does.

error() { zenity --error --title="My App" --text="$1" --width=420; exit 1; }

echo "[1/2] Working..."                  # visible when Terminal=true
sleep 1

echo "[2/2] Done."
zenity --info --title="My App" \
  --text="Completed successfully.\n\nDetail: <b>value</b>." --width=420
```

**`~/.local/share/applications/myapp.desktop`**

```ini
[Desktop Entry]
Type=Application
Version=1.0
Name=My App
Comment=One-line description
Exec=/home/user/scripts/myapp.sh
Icon=system-run
Terminal=true
Categories=Utility;
```

**Installation**

```bash
chmod +x ~/scripts/myapp.sh ~/.local/share/applications/myapp.desktop
update-desktop-database ~/.local/share/applications
```

---

## 8. Reference Implementation

`src/app-custom-example.sh` in this repository implements each capability listed
in section 5, following the practices described here. It is installed by
`install.sh` and serves as a working demonstration.
