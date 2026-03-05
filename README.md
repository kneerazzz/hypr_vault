# hypr-vault

A dark, minimal password manager for Hyprland built with **QuickShell (QML)** and a **Node.js backend**.
Passwords are encrypted at rest using **AES-256-GCM** with **scrypt key derivation**.

The vault opens as a **separate window on the right side of the screen**, designed to be lightweight and keyboard-friendly.

---

# Project Structure

```
/home/llyod/Documents/Projects/hypr_vault/
├── launch.sh
├── README.md
├── scripts/
│   ├── shell.qml
│   ├── VaultWidget.qml
│   ├── LoginView.qml
│   ├── VaultListView.qml
│   ├── CredentialDetailView.qml
│   ├── AddCredentialView.qml
│   ├── DetailField.qml
│   └── EditField.qml
└── src/
    ├── package.json
    ├── index.js
    ├── db.js
    ├── crypto.js
    └── generate.js
```

---

# Data Storage

Vault data is stored inside:

```
~/.config/hypr-vault/
```

Files created automatically:

```
vault.db   ← SQLite database
salt.txt   ← scrypt salt
```

Permissions are restricted:

```
chmod 600
```

This ensures **only your user account can access the vault data**.

---

# Setup

## 1 Install dependencies

```
cd /home/llyod/Documents/Projects/hypr_vault/src
npm install
```

---

## 2 Make launcher executable

```
chmod +x /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

---

## 3 Launch the vault

```
bash /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

---

## Optional Hyprland Keybind

Add to:

```
~/.config/hypr/hyprland.conf
```

```
bind = $mainMod, H, exec, bash /home/llyod/Documents/Projects/hypr_vault/launch.sh
```

Press **Super + H** to open the vault.

---

# Usage Flow

```
Launch Vault
     │
     ▼
[LOGIN]
enter master password
     │
     ▼
[VAULT LIST]
     │
     ├── Add new credential
     ├── Filter credentials
     └── Open entry
            │
            ▼
       [DETAIL VIEW]
            │
     ┌──────┴───────┐
     ▼              ▼
  Update         Delete
```

---

# Keyboard Shortcuts

| Shortcut | Action                   |
| -------- | ------------------------ |
| Escape   | Go back to previous view |
| Ctrl+L   | Lock vault               |
| Ctrl+N   | Add new credential       |
| Ctrl+F   | Open filter panel        |
| Ctrl+T   | Close vault window       |

---

# Security Architecture

## Master Password Handling

The master password is **never passed as a command line argument**.

Instead it is passed to the Node process using a **temporary environment variable**:

### QML

```qml
process.environment = ({ "VAULT_MASTER_KEY": masterPassword })
process.command     = ["node", "src/index.js", "login"]
process.running     = true
```

### Node

```javascript
function getMasterPassword() {
    return process.env.VAULT_MASTER_KEY || "";
}
```

This avoids exposing the password in:

```
ps aux
/proc/<pid>/cmdline
```

The environment variable exists **only for the lifetime of that child process**.

---

# Encryption

Passwords are encrypted before being written to disk.

Encryption details:

| Feature        | Value                                  |
| -------------- | -------------------------------------- |
| Algorithm      | AES-256-GCM                            |
| Key Derivation | scrypt                                 |
| Salt           | Random salt stored in `salt.txt`       |
| Authentication | GCM authentication tag                 |
| IV             | Random per-entry initialization vector |

AES-GCM provides:

• confidentiality
• integrity protection
• tamper detection

If ciphertext or tag is modified, **decryption fails automatically**.

---

# Database

SQLite database stored at:

```
~/.config/hypr-vault/vault.db
```

Table fields:

```
id
service
username
email
url
encrypted_password
iv
auth_tag
```

Important:

• plaintext passwords are **never written to disk**
• only encrypted values are stored

---

# Backend Commands

All commands run through:

```
node src/index.js <command>
```

Available commands:

| Command  | Description                        |
| -------- | ---------------------------------- |
| login    | verify master password             |
| list     | list credentials                   |
| get <id> | decrypt and return password        |
| add      | add new credential                 |
| update   | update credential                  |
| delete   | delete credential                  |
| filter   | search by service, username, email |

---

# Password Generator

The password generator uses Node's cryptographically secure RNG:

```
crypto.randomInt()
```

Options supported:

| Option    | Default |
| --------- | ------- |
| length    | 18      |
| lowercase | enabled |
| uppercase | enabled |
| numbers   | enabled |
| symbols   | enabled |

Features:

• ensures at least **one character from each enabled class**
• fills remaining characters randomly
• uses **Fisher-Yates shuffle** to remove positional patterns

Passwords range from **8 to 64 characters**.

---

# QML Architecture

The UI follows a **single root controller pattern**.

```
VaultWidget
 ├ LoginView
 ├ VaultListView
 ├ CredentialDetailView
 └ AddCredentialView
```

`VaultWidget.qml` owns:

• all state
• all Node processes
• view routing

Child views **only emit signals** and never execute backend commands directly.

---

# Process Execution Pattern

Every backend call uses a short timer to avoid process reuse issues in QuickShell.

```
Timer {
    interval: 10
    onTriggered: {
        process.environment = ({ "VAULT_MASTER_KEY": password })
        process.command = ["node", scriptDir + "index.js", "command"]
        process.running = true
    }
}
```

The delay ensures a **clean process state before execution**.

---

# Clipboard Handling

Password copying uses a hidden `TextEdit` element:

```
selectAll()
copy()
```

This approach is used instead of the QuickShell clipboard API to ensure **consistent behaviour across Qt versions**.

---

# Window Behaviour

The vault opens as a **standalone window positioned on the right side of the screen**.

It is not a layer-shell overlay and does not reserve space in the compositor layout.

This allows the vault to behave like a normal floating utility window.

---

# Design Philosophy

hypr-vault is designed around a few principles:

• **minimal UI**
• **keyboard-first workflow**
• **simple architecture**
• **strong local encryption**

The goal is to keep the vault **fast, private, and easy to audit**.

---

# License

Personal project.
Use freely and modify as needed.
