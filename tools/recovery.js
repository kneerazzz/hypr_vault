//Function to decrypt info and password using vault.db or vault.json, salt.txt and master password
//usage node recover.js <vault.db or ,json> <salt.txt> <masterPassword>

import fs from 'fs';
import Database from 'better-sqlite3';
import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';


function deriveKey(masterPassword, salt) {
    return crypto.scryptSync(masterPassword, salt, 32, { 
        N: 2 ** 14, 
        r: 8, 
        p: 1 
    });
}

function decrypt(encryptedHex, ivHex, authTagHex, key) {
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
}

async function runRecovery() {
    const args = process.argv.slice(2);
    if (args.length < 3) {
        console.log("\nUsage: node recovery.js <vault.db|.json> <salt.txt> <password>");
        process.exit(1);
    }

    const [filePath, saltPath, masterPassword] = args;

    try {
        if (!fs.existsSync(filePath)) throw new Error(`Vault file not found: ${filePath}`);
        if (!fs.existsSync(saltPath)) throw new Error(`Salt file not found: ${saltPath}`);

        const salt = fs.readFileSync(saltPath);
        const key = deriveKey(masterPassword, salt);
        let entries = [];

        if (filePath.endsWith('.db')) {
            const db = new Database(filePath, { readonly: true });
            entries = db.prepare('SELECT * FROM vault').all();
            db.close();
        } 
        else if (filePath.endsWith('.json')) {
            entries = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        } 
        else {
            throw new Error("Unsupported file format. Use .db or .json");
        }

        console.log(`\n=== 🔓 HYPR-VAULT RECOVERY: ${entries.length} ENTRIES ===\n`);

        entries.forEach((row, index) => {
            try {
                const encData = row.encrypted_password || row.password; 
                const clearPass = decrypt(encData, row.iv, row.auth_tag, key);

                console.log(`${index + 1}. [${row.service.toUpperCase()}]`);
                console.log(`   User: ${row.username || 'N/A'}`);
                console.log(`   Mail: ${row.email || 'N/A'}`);
                console.log(`   URL:  ${row.url || 'N/A'}`);
                console.log(`   Pass: ${clearPass}`);
                console.log('   ' + '-'.repeat(30));
            } catch (e) {
                console.log(`${index + 1}. [${row.service}] -> Decryption Failed (Incorrect password or corrupted entry)`);
            }
        });

    } catch (error) {
        console.error(`\n❌ RECOVERY ERROR: ${error.message}\n`);
    }
}

runRecovery();