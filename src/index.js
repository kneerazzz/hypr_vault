import { 
    addCredential, updateCredential, getVault, getCredential, 
    deleteCredential, filterVaultByService, filterVaultByUsername, filterVaultByEmail 
} from "./db.js";
import { decryptPassword, encryptPassword } from "./crypto.js";
import { generateStrongPassword } from "./utils/generate.js"
import { createBackup } from "./utils/backup.js";
import fs from 'fs';
import crypto from 'crypto'


const command    = process.argv[2];
const jsonOutput = process.argv.includes('--json');

function getMasterPassword() {
    return process.env.VAULT_MASTER_KEY || "";
}

async function main() {
    try {
        switch (command) {
            case 'list': {
                const vault = getVault();
                process.stdout.write(JSON.stringify(vault) + '\n');
                break;
            }

            case 'login': {
                const masterPassword = getMasterPassword();
                if (!masterPassword) throw new Error("No master password provided.");
                const vault = getVault();
                if (vault.length > 0) {
                    const probe = getCredential(vault[0].id);
                    decryptPassword(probe.encrypted_password, probe.iv, probe.auth_tag, masterPassword);
                }
                process.stdout.write(JSON.stringify({ success: true }) + '\n');
                break;
            }

            case 'get': {
                const id = process.argv[3];
                const masterPassword = getMasterPassword();
                if (!id || !masterPassword) throw new Error("Missing arguments.");
                const item = getCredential(id);
                if (!item) throw new Error(`Credential id=${id} not found.`);
                
                const decrypted = decryptPassword(item.encrypted_password, item.iv, item.auth_tag, masterPassword);
                
                if (jsonOutput) {
                    const out = { ...item, password: decrypted };
                    delete out.encrypted_password; delete out.iv; delete out.auth_tag;
                    process.stdout.write(JSON.stringify(out) + '\n');
                } else {
                    process.stdout.write(decrypted);
                }
                break;
            }

            case 'add': {
                const service = process.argv[3];
                const username = process.argv[4];
                const email = (!process.argv[5] || process.argv[5] === "SKIP") ? null : process.argv[5];
                const url = (!process.argv[6] || process.argv[6] === "SKIP") ? null : process.argv[6];
                let password = process.argv[7];
                const masterPassword = getMasterPassword();

                if (!password || password === "GENERATE") {
                    password = generateStrongPassword({ length: 18, useSymbols: true, useNumbers: true, useUppercase: true });
                }

                const locked = encryptPassword(password, masterPassword);
                addCredential(service, username, email, url, locked.encrypted_password, locked.iv, locked.auth_tag);
                createBackup();
                process.stdout.write(JSON.stringify({ success: true, password }) + '\n');
                break;
            }
            case 'update': {
                const id          = process.argv[3];
                const service     = process.argv[4];
                const username    = process.argv[5];
                const email       = process.argv[6];
                const url         = process.argv[7];
                const newPassword = process.argv[8];
                const masterPassword = getMasterPassword();
                if (!id)             throw new Error("Missing id argument.");
                if (!masterPassword) throw new Error("No master password provided.");
                const updates = {};
                if (service     && service     !== "SKIP") updates.service  = service;
                if (username    && username    !== "SKIP") updates.username = username;
                if (email       && email       !== "SKIP") updates.email    = email;
                if (url         && url         !== "SKIP") updates.url      = url;
                if (newPassword && newPassword !== "SKIP") {
                    const locked = encryptPassword(newPassword, masterPassword);
                    updates.encrypted_password = locked.encrypted_password;
                    updates.iv       = locked.iv;
                    updates.auth_tag = locked.auth_tag;
                }
                updateCredential(id, updates);
                createBackup();
                process.stdout.write(JSON.stringify({ success: true }) + '\n');
                break;
            }

            case 'filter': {
                const type  = process.argv[3];
                const query = process.argv[4];
                if (!type || !query) throw new Error("Usage: filter <service|username|email> <query>");
                let results = [];
                if      (type === 'service')  results = filterVaultByService(query);
                else if (type === 'username') results = filterVaultByUsername(query);
                else if (type === 'email')    results = filterVaultByEmail(query);
                else throw new Error(`Invalid filter type: "${type}"`);
                process.stdout.write(JSON.stringify(results) + '\n');
                break;
            }

            case 'delete': {
                const id = process.argv[3];
                const masterPassword = getMasterPassword();
                if (!id)             throw new Error("Missing id argument.");
                if (!masterPassword) throw new Error("No master password provided.");
                const vault = getVault();
                if (vault.length > 0) {
                    const probe = getCredential(vault[0].id);
                    decryptPassword(probe.encrypted_password, probe.iv, probe.auth_tag, masterPassword);
                }
                deleteCredential(id);
                createBackup();
                process.stdout.write(JSON.stringify({ success: true, deleted: id }) + '\n');
                break;
            }


            case 'verify': {
                const masterPassword = getMasterPassword();
                if (!masterPassword) throw new Error("No master password provided.");
                
                const fullVault = [];
                const vaultHeaders = getVault();
                let corruptedList = [];

                for (const header of vaultHeaders) {
                    const item = getCredential(header.id);
                    try {
                        decryptPassword(item.encrypted_password, item.iv, item.auth_tag, masterPassword);
                    } catch (e) {
                        corruptedList.push(`#${item.id} (${item.service})`);
                    }
                }

                if (corruptedList.length > 0) {
                    process.stdout.write(JSON.stringify({ 
                        success: false, 
                        total: vaultHeaders.length, 
                        corrupted: corruptedList.length, 
                        message: `WARNING: Corrupted entries found: ${corruptedList.join(', ')}` 
                    }) + '\n');
                } else {
                    process.stdout.write(JSON.stringify({ 
                        success: true, 
                        total: vaultHeaders.length, 
                        message: "Vault integrity verified. All entries are secure." 
                    }) + '\n');
                }
                break;
            }

            case 'export': {
                const outPath = process.argv[3];
                const vaultHeaders = getVault();
                const fullData = vaultHeaders.map(h => getCredential(h.id));
                fs.writeFileSync(outPath, JSON.stringify(fullData, null, 2));
                process.stdout.write(JSON.stringify({ success: true, entries: fullData.length }) + '\n');
                break;
            }

            case 'import': {
                const inPath = process.argv[3];
                const importData = JSON.parse(fs.readFileSync(inPath, 'utf8'));
                let imported = 0;
                for (const item of importData) {
                    if (item.encrypted_password && item.iv && item.auth_tag) {
                        addCredential(item.service, item.username, item.email, item.url, item.encrypted_password, item.iv, item.auth_tag);
                        imported++;
                    }
                }
                process.stdout.write(JSON.stringify({ success: true, imported }) + '\n');
                break;
            }

            case 'export-portable': {
                const outPath = process.argv[3];
                const masterPassword = getMasterPassword();
                if(!masterPassword) throw new Error("Authentication Required for secure export")

                const vaultHeaders = getVault();
                const portableData = vaultHeaders.map(h => {
                    const item = getCredential(h.id);
                    const clearText = decryptPassword(item.encrypted_password, item.iv, item.auth_tag, masterPassword);
                    
                    const portableKey = crypto.scryptSync(masterPassword, 'hypr-vault-bundle-salt', 32, { N: 2 ** 14, r: 8, p: 1 });
                    const iv = crypto.randomBytes(12);
                    const cipher = crypto.createCipheriv('aes-256-gcm', portableKey, iv);
                    
                    let enc = cipher.update(clearText, 'utf8', 'hex');
                    enc += cipher.final('hex');
                    
                    return {
                        service: item.service,
                        username: item.username,
                        email: item.email,
                        url: item.url,
                        password: enc,
                        iv: iv.toString('hex'),
                        auth_tag: cipher.getAuthTag().toString('hex')
                    };
                });


                const containerJson = JSON.stringify(portableData);
                const bundleKey = crypto.scryptSync(masterPassword, 'hypr-vault-bundle-salt', 32, { N: 2 ** 14, r: 8, p: 1 });
                const bIv = crypto.randomBytes(12);
                const bCipher = crypto.createCipheriv('aes-256-gcm', bundleKey, bIv);
                
                let locked = bCipher.update(containerJson, 'utf8', 'hex');
                locked += bCipher.final('hex');

                fs.writeFileSync(outPath, JSON.stringify({
                    locked_vault: locked,
                    iv: bIv.toString('hex'),
                    auth_tag: bCipher.getAuthTag().toString('hex')
                }, null, 2));

                process.stdout.write(JSON.stringify({ success: true }) + '\n');
                break;
            }
            default:
                process.exit(1);
        }
    } catch (error) {
        process.stderr.write(error.message + '\n');
        process.exit(1);
    }
}

main();