import { 
    addCredential, updateCredential, getVault, getCredential, 
    deleteCredential, filterVaultByService, filterVaultByUsername, filterVaultByEmail 
} from "./db.js";
import { decryptPassword, encryptPassword } from "./crypto.js";
import { generateStrongPassword } from "./generate.js";
import { createBackup } from "./backup.js";
import fs from 'fs';

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
                
                // FIXED: Using encrypted_password to match db.js
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

            case 'verify': {
                const masterPassword = getMasterPassword();
                if (!masterPassword) throw new Error("No master password provided.");
                
                const fullVault = [];
                // We need the full data (IV/Tags) for verification, getVault() only returns headers
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

            default:
                process.exit(1);
        }
    } catch (error) {
        process.stderr.write(error.message + '\n');
        process.exit(1);
    }
}

main();