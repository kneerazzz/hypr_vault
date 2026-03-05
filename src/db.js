import Database from "better-sqlite3";
import fs from 'fs';
import path from "path";
import os from 'os';

const configDir = path.join(os.homedir(), '.config', 'hypr-vault');

if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true, mode: 0o700 });
}

const dbPath = path.join(configDir, 'vault.db');

const db = new Database(dbPath);

if (fs.existsSync(dbPath)) {
    fs.chmodSync(dbPath, 0o600);
}

db.exec(`
    CREATE TABLE IF NOT EXISTS vault (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service TEXT NOT NULL,
        username TEXT NOT NULL,
        email TEXT,
        url TEXT,
        encrypted_password TEXT NOT NULL,
        iv TEXT NOT NULL,
        auth_tag TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
`);


// Fixed: email parameter was missing from the original signature
function addCredential(service, username, email = null, url = null, encryptedPassword, iv, authTag) {
    try {
        const stmt = db.prepare(`
            INSERT INTO vault (service, username, email, url, encrypted_password, iv, auth_tag)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `);
        return stmt.run(service, username, email, url, encryptedPassword, iv, authTag);
    } catch (error) {
        throw new Error(`Error creating new credential: ${error.message}`);
    }
}

function getCredential(id) {
    try {
        const stmt = db.prepare(`SELECT * FROM vault WHERE id = ?`);
        return stmt.get(id);
    } catch (error) {
        throw new Error(`Error getting credential: ${error.message}`);
    }
}

function getVault() {
    try {
        const stmt = db.prepare(`SELECT id, service, username, email, url FROM vault ORDER BY service ASC`);
        return stmt.all();
    } catch (error) {
        throw new Error(`Error getting vault: ${error.message}`);
    }
}

function updateCredential(id, updates) {
    try {
        const existing = getCredential(id);
        if (!existing) throw new Error("Credential not found!");

        const username           = updates.username           || existing.username;
        const url                = updates.url                || existing.url;
        const service            = updates.service            || existing.service;
        const email              = updates.email              || existing.email;
        const encrypted_password = updates.encrypted_password || existing.encrypted_password;
        const iv                 = updates.iv                 || existing.iv;
        const auth_tag           = updates.auth_tag           || existing.auth_tag;

        const stmt = db.prepare(`
            UPDATE vault
            SET service = ?, username = ?, email = ?, url = ?,
                encrypted_password = ?, iv = ?, auth_tag = ?,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        `);

        return stmt.run(service, username, email, url, encrypted_password, iv, auth_tag, id);
    } catch (error) {
        throw new Error(`Error updating credential: ${error.message}`);
    }
}

function deleteCredential(id) {
    try {
        const stmt = db.prepare(`DELETE FROM vault WHERE id = ?`);
        return stmt.run(id);
    } catch (error) {
        throw new Error(`Error deleting credential: ${error.message}`);
    }
}

function filterVaultByService(service) {
    try {
        const stmt = db.prepare(`
            SELECT id, username, email, service, url FROM vault
            WHERE service LIKE ? ORDER BY service ASC
        `);
        return stmt.all(`%${service}%`);
    } catch (error) {
        throw new Error(`Error filtering vault by service: ${error.message}`);
    }
}

function filterVaultByUsername(username) {
    try {
        const stmt = db.prepare(`
            SELECT id, username, email, service, url FROM vault
            WHERE username LIKE ? ORDER BY service ASC
        `);
        return stmt.all(`%${username}%`);
    } catch (error) {
        throw new Error(`Error filtering vault by username: ${error.message}`);
    }
}

function filterVaultByEmail(email) {
    try {
        const stmt = db.prepare(`
            SELECT id, username, email, service, url FROM vault
            WHERE email LIKE ? ORDER BY service ASC
        `);
        return stmt.all(`%${email}%`);
    } catch (error) {
        throw new Error(`Error filtering vault by email: ${error.message}`);
    }
}

export {
    addCredential,
    getCredential,
    getVault,
    updateCredential,
    deleteCredential,
    filterVaultByService,
    filterVaultByUsername,
    filterVaultByEmail
};