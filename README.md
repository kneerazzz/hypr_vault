# hypr-vault

A dark, minimal password manager widget for Hyprland built with QuickShell (QML) and a Node.js backend. Passwords are encrypted at rest using AES-256-GCM with scrypt key derivation. The UI sits as a fixed panel on the right side of your screen.

---

## Project Structure

```
/home/llyod/Documents/Projects/hypr_vault/
├── launch.sh                  ← Run this to start the widget
├── README.md
├── scripts/                   ← QuickShell entry point (-c points here)
│   ├── shell.qml              ← PanelWindow definition (size, layer, anchors)
│   ├── VaultWidget.qml        ← Root controller — view routing, all processes
│   ├── LoginView.qml          ← Master password entry screen
│   ├── VaultListView.qml      ← Credential list with filter panel
│   ├── CredentialDetailView.qml ← Detail, edit, delete, show, copy
│   ├── AddCredentialView.qml  ← New credential form with live password generator
│   ├── DetailField.qml        ← Read-only labelled field with copy button
│   └── EditField.qml          ← Editable input with validation and show/hide
└── src/                       ← Node.js backend
    ├── package.json
    ├── index.js               ← CLI dispatcher for all vault commands
    ├── db.js                  ← SQLite CRUD via better-sqlite3
    ├── crypto.js              ← AES-256-GCM encrypt/decrypt + scrypt key derivation
    └── generate.js            ← Cryptographically random password generator
```

Vault data is stored at:
```
~/.config/hypr-vault/
├── vault.db      (SQLite database, chmod 600)
└── salt.txt      (scrypt salt, chmod 600)
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
bind = $mainMod, H, exec, bash /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

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
                    by service,       fill form               │
                    username,         ⚡ live gen             ▼
                    or email          save                [DETAIL VIEW]
                                                         show/copy/edit
                                                         /delete
                                                              │
                                             ┌───────────────┴──────────────┐
                                             ▼                              ▼
                                         [UPDATE]                      [DELETE]
                                     edit fields,                  master password
                                     master pass                   confirm, then
                                     to confirm save               wipe entry
```

---

## Keyboard Shortcuts

| Shortcut   | Action                                                              |
|------------|---------------------------------------------------------------------|
| `Escape`   | Navigate back to previous view                                      |
| `Ctrl+L`   | Lock vault — wipes master password from memory, returns to login    |

---

## Security Architecture

### Master password handling

The master password is **never passed as a command-line argument** (which would expose it in `ps aux` and `/proc/<pid>/cmdline`). Instead it is passed via environment variable, scoped only to the child Node process:

```qml
// QML side — Quickshell Process API
process.environment = ({ "VAULT_MASTER_KEY": masterPassword })
process.command     = ["node", "src/index.js", "login"]
process.running     = true
```

```javascript
// Node side — src/index.js
function getMasterPassword() {
    return process.env.VAULT_MASTER_KEY || "";
}
```

**Why this is safe:**
- The env var is set at the OS level after `fork()`, never visible in argv
- It is scoped only to that single child process — the parent shell never sees it
- The process lives for milliseconds; the only attack window is `/proc/<pid>/environ` by a process running as the same user, which would mean the attacker already has full user access

### Login verification

There is no separate verification file. On login, the vault attempts to decrypt the first existing credential with the provided password. If the password is wrong, AES-256-GCM's auth tag won't match and decryption throws — login fails. On an empty vault (first use), any password succeeds and becomes the master password from the moment the first credential is saved.

### Encryption

- Algorithm: **AES-256-GCM** (authenticated encryption — detects tampering)
- Key derivation: **scrypt** (`N=32768, r=8, p=1`) — slow by design, resistant to brute force
- Each password gets a unique random IV
- Auth tag is stored alongside ciphertext and verified on every decrypt

### Database

- SQLite via `better-sqlite3`
- File stored at `~/.config/hypr-vault/vault.db`
- `chmod 600` — owner read/write only
- Stores: `id`, `service`, `username`, `email`, `url`, `encrypted_password`, `iv`, `auth_tag`
- Plaintext passwords are **never written to disk**

---

## Node.js Backend Commands

All commands are invoked as `node src/index.js <command> [args] [--json]`.

| Command                  | Auth required      | Description                           |
|--------------------------|--------------------|---------------------------------------|
| `login`                  | `VAULT_MASTER_KEY` | Verify master password by decrypting a probe credential |
| `list`                   | none               | Return all credentials (no passwords) |
| `get <id>`               | `VAULT_MASTER_KEY` | Decrypt and return a single password  |
| `add ...`                | `VAULT_MASTER_KEY` | Encrypt and store a new credential    |
| `update <id> ...`        | `VAULT_MASTER_KEY` | Update fields on an existing entry    |
| `delete <id>`            | `VAULT_MASTER_KEY` | Delete a credential after auth        |
| `filter <type> <query>`  | none               | Search by service / username / email  |

---

## Password Generator

The `generate.js` module uses Node's `crypto.randomInt()` (CSPRNG) to build passwords. Options:

| Option         | Default | Range  |
|----------------|---------|--------|
| `length`       | 18      | 8 – 64 |
| `useLowercase` | true    | a-z    |
| `useUppercase` | true    | A-Z    |
| `useNumbers`   | true    | 0-9    |
| `useSymbols`   | true    | !@#$%^ |

The generator guarantees at least one character from each enabled character class before filling the rest randomly, then shuffles with Fisher-Yates to avoid predictable positions.

In the UI, clicking ⚡ opens the generator panel and **immediately generates** a password. Adjusting length or toggling character classes re-generates live with an 80ms debounce. A ↺ button lets you regenerate on demand. The generated password is shown in the field before saving — what you see is what gets stored.

---

## QML Architecture

### View routing

`VaultWidget.qml` is the root controller. It owns all `Process` instances and all state. Child views are all mounted simultaneously with `visible` + `opacity` toggled — this avoids re-instantiation cost on navigation.

```
VaultWidget (root, "login" | "list" | "detail" | "addform")
├── LoginView
├── VaultListView
├── CredentialDetailView
└── AddCredentialView
```

### Process pattern

Every Node command follows the same pattern to avoid Quickshell process re-use timing bugs:

```qml
Timer {
    id: someTimer
    interval: 10          // 1-frame delay ensures clean process state
    onTriggered: {
        someProcess.environment = ({ "VAULT_MASTER_KEY": password })
        someProcess.command     = ["node", scriptDir + "index.js", "command"]
        someProcess.running     = true
    }
}
```

### Why environment variables instead of stdin

An earlier version passed the master password via stdin using `process.write()` + EOF signaling. This was abandoned because:

1. Quickshell's `Process` has no `stdin` property — only `stdinEnabled: true` + `write()` method
2. Node's `readStdin()` blocks until pipe close (EOF) — with `stdinEnabled: true` the pipe stays open forever causing infinite hangs
3. Environment variables are simpler, equally secure for this threat model, and avoid all async pipe complexity

### Password field auto-clear

`AddCredentialView` calls `clearAll()` on `onVisibleChanged: if (visible)` — every field is wiped each time the add form is opened, preventing stale data from a previous entry appearing in a new form.

### EditField component

`EditField.qml` exposes:
- `currentValue` — read-only live text
- `initialValue` — sets text on load and on change
- `clear()` — wipes the field
- `setValue(v)` — programmatically fills the field (used by the password generator)
- `validate()` — checks `required` constraint, sets `errorMessage`
- `isPassword` — toggles echo mode with a built-in show/hide eye button

### DetailField component

`DetailField.qml` uses a hidden `TextEdit` + `selectAll()` + `copy()` as the clipboard mechanism instead of Quickshell's `Clipboard` singleton, which proved unreliable across versions.

---

## Known Decisions & Trade-offs

| Decision | Reason |
|----------|--------|
| Env vars over stdin | Stdin caused indefinite process hangs due to pipe EOF semantics |
| No verify.bin | Not needed — login probes an existing credential; first-use sets password implicitly on first save |
| Master password to confirm show/copy/delete | Once logged in, sensitive actions require re-entering the master password — you can hardcode a shorter passcode directly in `CredentialDetailView.qml` if you prefer |
| All processes in VaultWidget | Centralised state; child views only emit signals, never own processes |
| 10ms Timer before process start | Prevents Quickshell process re-use race conditions |
| TextEdit clipboard bridge | `Clipboard.text` from Quickshell was unreliable; native Qt copy always works |
| Full-height right panel | Panel anchors top+bottom+right, filling the full screen height on the right side |

---

## Customisation

### Change the panel width

Edit `scripts/shell.qml`:
```qml
implicitWidth: 480   // panel width in pixels
```

### Use a shorter passcode for show / copy / delete

By default, show, copy, and delete all require your full master password. If you want a shorter code to use once you're already logged in, open `scripts/CredentialDetailView.qml` and On Line 636 and 637, respectively. Change the comparison to whatever you want:


This is purely a convenience tweak — the vault is already unlocked at this point so the master password has already been verified at login.

### Change the scriptDir path

If you move the project, update the path in every QML file that declares:
```qml
readonly property string scriptDir: "/home/llyod/Documents/Projects/hypr_vault/src/"
```