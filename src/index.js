import { 
    addCredential, updateCredential, getVault, getCredential, 
    deleteCredential, filterVaultByService, filterVaultByUsername, filterVaultByEmail 
} from "./db.js";
import { decryptPassword, encryptPassword } from "./crypto.js";
import { generateStrongPassword } from "./generate.js";

const command    = process.argv[2];
const jsonOutput = process.argv.includes('--json');

/**
 * Read master password from the VAULT_MASTER_KEY environment variable.
 *
 * Security properties:
 *  - Never appears in argv (not visible in `ps aux`)
 *  - Env var is scoped to this child process only (set by QML Process.environment)
 *  - Not written to disk or logs
 *  - Parent process (Quickshell) controls exactly which env vars are forwarded
 */
function getMasterPassword() {
    const pass = process.env.VAULT_MASTER_KEY || "";
    return pass;
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
                // Empty vault always succeeds — first-time setup
                process.stdout.write(JSON.stringify({ success: true }) + '\n');
                break;
            }

            case 'get': {
                const id = process.argv[3];
                const masterPassword = getMasterPassword();
                if (!id)             throw new Error("Missing id argument.");
                if (!masterPassword) throw new Error("No master password provided.");
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
                const service    = process.argv[3];
                const username   = process.argv[4];
                const email      = (!process.argv[5] || process.argv[5] === "SKIP") ? null : process.argv[5];
                const url        = (!process.argv[6] || process.argv[6] === "SKIP") ? null : process.argv[6];
                let   password   = process.argv[7];
                const genOptions = process.argv[8];
                const masterPassword = getMasterPassword();
                if (!service)        throw new Error("Missing service argument.");
                if (!username)       throw new Error("Missing username argument.");
                if (!masterPassword) throw new Error("No master password provided.");
                if (!password || password === "GENERATE") {
                    let opts = {};
                    if (genOptions) {
                        const [len, sym, num, up] = genOptions.split(',');
                        opts = { length: parseInt(len)||18, useSymbols: sym==='true', useNumbers: num==='true', useUppercase: up==='true' };
                    }
                    password = generateStrongPassword(opts);
                }
                const locked = encryptPassword(password, masterPassword);
                addCredential(service, username, email, url, locked.encrypted_password, locked.iv, locked.auth_tag);
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
                process.stdout.write(JSON.stringify({ success: true, deleted: id }) + '\n');
                break;
            }

            default:
                process.stderr.write("Unknown command: " + command + "\n");
                process.exit(1);
        }
    } catch (error) {
        await new Promise(r => setTimeout(r, 200 + Math.random() * 100));
        process.stderr.write(JSON.stringify({ error: error.message }) + '\n');
        process.exit(1);
    }
}

main();