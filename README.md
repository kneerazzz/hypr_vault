# hypr-vault

A dark, minimal password manager widget for Hyprland using QuickShell.

---

## Project Structure

```
/home/llyod/Documents/Projects/hypr_vault/
├── launch.sh                  ← Run this to start the widget
├── README.md
├── scripts/                   ← QuickShell entry point (-c points here)
│   ├── shell.qml
│   ├── VaultWidget.qml
│   ├── LoginView.qml
│   ├── VaultListView.qml
│   ├── CredentialDetailView.qml
│   ├── AddCredentialView.qml
│   ├── DetailField.qml
│   └── EditField.qml
└── src/                       ← Node.js backend
    ├── package.json
    ├── index.js
    ├── db.js
    ├── crypto.js
    └── generate.js
```

The vault database and salt file are stored at:
```
~/.config/hypr-vault/
├── vault.db      (SQLite, chmod 600)
└── salt.txt      (crypto salt, chmod 600)
```

---

## Setup

### 1. Install Node dependencies

```bash
cd /home/llyod/Documents/Projects/hypr_vault/src
npm install
```

### 2. Make the launch script executable

```bash
chmod +x /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

### 3. Launch

```bash
bash /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

### 4. Bind to a Hyprland key (optional)

Add to `~/.config/hypr/hyprland.conf`:

```conf
bind = $mainMod, V, exec, bash /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

---

## Why `-c scripts/`?

QuickShell's `-c` flag takes a **directory** and looks for `shell.qml` inside it.
Since QML files live in `scripts/`, that's the directory you point it at — not the project root.

The QML files resolve the Node backend path as:
```
Qt.resolvedUrl("../")  →  /home/llyod/Documents/Projects/hypr_vault/
                + "src/" →  /home/llyod/Documents/Projects/hypr_vault/src/
```

So `../src/` from `scripts/` lands exactly on your `src/` folder.

---

## Usage Flow

```
Launch Widget
     │
     ▼
[LOGIN] ── enter master password ──► [VAULT LIST]
                                           │
                         ┌─────────────────┼──────────────────┐
                         ▼                 ▼                  ▼
                    [FILTER]          [ADD NEW]         [CLICK ENTRY]
                    by service,        fill form              │
                    username,           save                  ▼
                    or email                           [DETAIL VIEW]
                                                       passwords +
                                                       copy fields
                                                            │
                                             ┌─────────────┴─────────────┐
                                             ▼                           ▼
                                         [UPDATE]                   [DELETE]
                                         edit fields             confirm with
                                         save changes            master pass
```

---

## Security Notes

- Master password **only** travels via stdin — never as a CLI argument
- `ps aux` / `/proc/<pid>/cmdline` will never expose it
- Database and salt file are `chmod 600` (owner read/write only)
- Delete requires re-entering the master password to authenticate
- Decryption uses AES-256-GCM with scrypt key derivation (N=32768)