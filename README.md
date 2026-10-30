# Linux Desktop App Template

A template for building clickable desktop applications on Linux using shell
scripts and zenity. No compilation, no packaging, no runtime dependencies
beyond the dialog utility itself.

The repository contains two things: a written guide describing how to build
such applications, and a reference application that demonstrates every
capability the guide describes.

## Contents

```
├── install.sh                          installer (idempotent, supports --uninstall)
├── docs/
│   └── guide.md                        reference documentation
└── src/
    ├── app-custom-example.sh           reference application
    └── app-custom-example.desktop.template
```

## Installation

```bash
git clone <repository-url>
cd linux-desktop-app-template
./install.sh
```

Open the activities overview (<kbd>Super</kbd>) and search for **App Custom
Example**.

| Command | Effect |
|---|---|
| `./install.sh` | Installs the script and registers the application |
| `./install.sh --desktop` | Additionally places an icon on the desktop |
| `./install.sh --uninstall` | Removes everything, including any dock entry |
| `SCRIPTS_DIR=~/bin ./install.sh` | Installs the script to a different directory |

Requires `zenity`. Optionally `libnotify-bin` for desktop notifications.

## Application or desktop shortcut

These are two different files, and only one of them makes the launcher an
application.

| File | What it is | Created by |
|---|---|---|
| `~/.local/share/applications/<name>.desktop` | **The application.** Listed in the activities overview and in search, and eligible for pinning to the dock. | `./install.sh`, always |
| `<desktop>/<name>.desktop` | **A shortcut.** An independent copy for launching from the desktop. Nothing else depends on it. | `./install.sh --desktop`, optionally |

A `.desktop` file that exists only on the desktop is not an application: GNOME
does not list it in the overview and it cannot be pinned. Deleting the desktop
copy leaves the application intact.

To pin the application to the dock, open the overview (<kbd>Super</kbd>),
search for its name, right-click the icon and select **Pin to Dash**. The
application does not need to be running.

If the script opens a window belonging to another program, such as a browser in
app mode, that window appears in the dock under the other program's icon unless
the `.desktop` entry declares its window class. See `docs/guide.md`, section 6.

## What the installer does

`install.sh` transforms the repository into an installed application:

1. Copies `src/app-custom-example.sh` to `~/scripts/`.
2. Generates the `.desktop` entry from `src/app-custom-example.desktop.template`,
   substituting the absolute script path.
3. Registers it in `~/.local/share/applications/`, which is what makes the
   application appear in the activities overview and eligible for pinning.

Step 2 is the reason the `.desktop` entry is committed as a template rather
than as a finished file. The `Exec` key performs no shell expansion — neither
`~` nor `$HOME` is resolved — so the correct value cannot be known until
install time.

## Uninstallation

```bash
./install.sh --uninstall
```

A launcher installed this way cannot be removed through the desktop interface.
GNOME offers a "Uninstall" action only for applications owned by a package
manager — apt, Flatpak or Snap. An entry in `~/.local/share/applications/` is
owned by no package manager, so no such action is offered. Likewise, a desktop
icon marked as trusted is presented as an application rather than as a file,
which is why the file operations normally available on the desktop do not
appear in its context menu.

Removal is therefore a matter of deleting the files that were installed:

```bash
rm -f ~/.local/share/applications/app-custom-example.desktop
rm -f "$(xdg-user-dir DESKTOP)/app-custom-example.desktop"
rm -f ~/scripts/app-custom-example.sh
update-desktop-database ~/.local/share/applications
```

If the application was pinned to the dock, it must also be removed from the
favourites list, or a broken icon remains:

```bash
gsettings get org.gnome.shell favorite-apps
gsettings set org.gnome.shell favorite-apps "['...remaining entries...']"
```

`./install.sh --uninstall` performs all of the above, including the favourites
cleanup.

## The reference application

Running it demonstrates six capabilities in sequence, each describing itself as
it executes: terminal output, a progress bar, a desktop notification, a
question dialog, a text entry dialog, and a summary dialog. It is intended to
be read alongside `docs/guide.md`, which explains the implementation of each.

## Building a new application

The guide is written to be followed directly, by a developer or by an AI coding
agent working from a clone of this repository:

```
Follow docs/guide.md and build an application that <requirement>.
```

Section 4 covers the procedure. Section 6 documents failure modes that produce
no error message, including processes that terminate silently when no terminal
is attached, shell portability constraints on port checks, dialog markup
escaping, and windows that do not group under their launcher's icon.

## Scope

This is a personal template rather than a supported product. It is verified on
**Ubuntu 24.04, GNOME 46, Wayland, zenity 4.0.1**, and on nothing else.

The `.desktop` format is a freedesktop standard, so the general approach is
expected to apply to other Linux desktop environments, but this is unverified.
KDE requires `kdialog` in place of `zenity`, which has different syntax.
Distributions lacking `xdg-user-dir` or `update-desktop-database` will skip the
corresponding installation steps, and the launcher may not be registered.
macOS and Windows are not supported and are out of scope.

## Licence

MIT
