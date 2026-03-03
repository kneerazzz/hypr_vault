import Database from "better-sqlite3";
import fs from 'fs'
import path from "path";
import os from 'os'

const configDir = path.join(os.homedir(), '.config', 'hypr-vault');

if(!fs.existsSync(configDir)){
    fs.mkdirSync(configDir, {recursive: true, mode: 0o700})
}

const dbPath = path.join(configDir, 'vault.db');

const db = new Database(dbPath);

if(fs.existsSync(dbPath)){
    fs.chmodSync(dbPath, 0o600)
}

db.exec(`
    CREATE TABLE IF NOT EXISTS vault (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service TEXT NOT NULL,
        username TEXT NOT NULL,
        url TEXT, -- (URL OF THE LOGIN OR SIGNUP PAGE EX: https://github.com/login)
        encrypted_password TEXT NOT NULL,
        iv TEXT NOT NULL,
        auth_tag TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )     
`);


function addCredential(service, username, url = null, encryptedPassword, iv, authTag){
    const stmt = db.prepare(`
        INSERT INTO vault( service, username, url, encrypted_password, iv, auth_tag)
        VALUES(?, ?, ?, ?, ?, ?)
    `);
    return stmt.run(service, username, url , encryptedPassword, iv, authTag);
}

function getCredential(id){
    const stmt = db.prepare(`SELECT * FROM vault WHERE id = ?`);
    return stmt.get(id);
}

function getVault(){
    const stmt = db.prepare(`SELECT service, username FROM vault ORDER BY service ASC`);
    return stmt.all();
}

function updateCredential(id, updates) {
    const existing = getCredential(id);
    if (!existing) throw new Error("Credential not found!");

    const username = updates.username || existing.username;
    const url = updates.url || existing.url;

    const encrypted_password = updates.encrypted_password || existing.encrypted_password;
    const iv = updates.iv || existing.iv;
    const auth_tag = updates.auth_tag || existing.auth_tag;

    const stmt = db.prepare(`
        UPDATE vault
        SET username = ?, url = ?, encrypted_password = ?, iv = ?, auth_tag = ?, updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    `);
    
    return stmt.run(username, url, encrypted_password, iv, auth_tag, id);
}

function deleteCredential(id, service){
    const stmt = db.prepare(`
        DELETE FROM vault WHERE id = ?
    `);
    stmt.run(id);
}

function filterVaultByService(service){
    const stmt = db.prepare(`
        SELECT id, username, service, url FROM vault WHERE service = ? ORDER BY service ASC    
    `);
    return stmt.all(service);
}

function filterVaultByUsername(username){
    const stmt = db.prepare(`
        SELECT id, username, service, url FROM vault WHERE username = ? ORDER BY service ASC    
    `);
    return stmt.all(username);
}
export {
    addCredential, 
    getCredential,
    getVault,
    updateCredential,
    deleteCredential,
    filterVaultByService,
    filterVaultByUsername
}