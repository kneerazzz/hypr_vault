# hypr-vault

A minimal password manager widget for Hyprland built with QuickShell (QML) and a Node.js backend. Passwords are encrypted at rest using AES-256-GCM with scrypt key derivation.

---

## Features

- **AES-256-GCM** encrypted storage with scrypt key derivation
- **Live password generator** with length and character class controls
- **Lifeboat export** — portable double-encrypted bundle, recoverable on any machine with just your master password
- **Integrity check** — validates every entry's auth tag, detects tampering
- **Standalone recovery** — `recovery.js and getYourPass.js` works without the UI if Hyprland fails

---

## Project Structure

```
qml/          ← QML frontend
  shell.qml
  VaultWidget.qml
  LoginView.qml
  VaultListView.qml
  CredentialDetailView.qml
  AddCredentialView.qml
  SettingsView.qml

src/              ← Node.js backend
  index.js
  db.js
  crypto.js
  utils/
    backup.js
    generate.js

tools/
  getYourPass.js
  recovery.js
```

Data stored at `~/.config/hypr-vault/` — `vault.db` and `salt.txt`, both `chmod 600`.
Backups stored at `~/.config/hypr-vault/backups` - `vault_backup_<date>`

---

## Setup

```bash
cd /home/llyod/Documents/Projects/hypr_vault
npm install
chmod +x /home/llyod/Documents/Projects/hypr_vault/launch.sh
bash /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

Hyprland keybind (optional):
```conf
bind = $mainMod, H, exec, bash /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Escape` | Go back |
| `Ctrl+L` | Lock vault |
| `Ctrl+F` | Open filter |
| `Ctrl+N` | Add credential |
| `Ctrl+S` | Open Settings |


---

## Security

The master password is **never in argv**. It's passed via environment variable scoped only to the child Node process:

```qml
process.environment = ({ "VAULT_MASTER_KEY": masterPassword })
process.command     = ["node", "src/index.js", "login"]
```

Login is verified by attempting to decrypt an existing credential — wrong password means GCM auth tag mismatch, Node throws, login fails. No separate verification file.

---

## Emergency Recovery

If the UI is unavailable:

```bash
# From a Lifeboat bundle
node src/tools/getYourPass.js vault_lifeboat.json "your_password"

# From a raw database
node src/tools/recovery.js ~/.config/hypr-vault/vault.db ~/.config/hypr-vault/salt.txt "your_password"
```

---

## Customisation

**Shorter passcode for show/copy/delete** — open `CredentialDetailView.qml`, find `submitConfirm()`, and replace the `masterPassword` comparison with any hardcoded string you want. The vault is already unlocked at that point so it's just a convenience tweak.

**Move the project** — update `scriptDir` in every QML file:
```qml
readonly property string scriptDir: "/your/new/path/src/"
```