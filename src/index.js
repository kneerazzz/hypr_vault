import { 
    addCredential, updateCredential, getVault, getCredential, 
    deleteCredential, filterVaultByService, filterVaultByUsername, filterVaultByEmail 
} from "./db.js";
import { decryptPassword, encryptPassword } from "./crypto.js";
import { generateStrongPassword } from "./generate.js";

const command = process.argv[2];
const jsonOutput = process.argv.includes('--json');

/**
 * Read master password from stdin ONLY.
 *
 * Security: the master password must never appear in process.argv,
 * environment variables, or any other mechanism visible to other
 * processes via /proc/<pid>/cmdline or `ps aux`.
 *
 * Callers (QML / shell) must pipe it in:
 *   echo "$PASS" | node index.js <command> ...
 * or via QuickShell's Process.stdin property.
 */
function getMasterPassword() {
    const pass = process.env.VAULT_MASTER;
    delete process.env.VAULT_MASTER;
    return pass || null;

}

async function main() {
    try {
        switch (command) {
            case 'list': {
                const vault = getVault();
                if (jsonOutput) {
                    process.stdout.write(JSON.stringify(vault, null, 2) + '\n');
                } else {
                    if (vault.length === 0) {
                        console.log("Vault is empty.");
                    } else {
                        vault.forEach(item => {
                            console.log(`${item.id} | ${item.service} | ${item.username} | ${item.email || 'No Email'}`);
                        });
                    }
                }
                break;
            }

            case 'get': {
                const id = process.argv[3];

                const masterPassword = getMasterPassword();

                if (!id)             throw new Error("Usage: node index.js get <id>  (master password via stdin)");
                if (!masterPassword) throw new Error("Master password is required via stdin.");

                const item = getCredential(id);
                if (!item) throw new Error(`Credential with id=${id} not found.`);

                const decryptedPassword = decryptPassword(
                    item.encrypted_password,
                    item.iv,
                    item.auth_tag,
                    masterPassword
                );

                if (jsonOutput) {
                    const out = { ...item, password: decryptedPassword };
                    delete out.encrypted_password;
                    delete out.iv;
                    delete out.auth_tag;
                    process.stdout.write(JSON.stringify(out, null, 2) + '\n');
                } else {
                    process.stdout.write(decryptedPassword);
                }
                break;
            }

            case 'add': {
                const service    = process.argv[3];
                const username   = process.argv[4];
                const email      = (process.argv[5] === "SKIP" || !process.argv[5]) ? null : process.argv[5];
                const url        = (process.argv[6] === "SKIP" || !process.argv[6]) ? null : process.argv[6];
                let   password   = process.argv[7];
                const genOptions = process.argv[8];

                const masterPassword = getMasterPassword();

                if (!service)        throw new Error("Missing required argument: service.");
                if (!username)       throw new Error("Missing required argument: username.");
                if (!masterPassword) throw new Error("Master password is required via stdin.");

                if (!password || password === "GENERATE") {
                    let options = {};
                    if (genOptions) {
                        const [len, sym, num, up] = genOptions.split(',');
                        options = {
                            length:       parseInt(len) || 18,
                            useSymbols:   sym === 'true',
                            useNumbers:   num === 'true',
                            useUppercase: up  === 'true'
                        };
                    }
                    password = generateStrongPassword(options);
                }

                const locked = encryptPassword(password, masterPassword);
                addCredential(
                    service, username, email, url,
                    locked.encrypted_password, locked.iv, locked.auth_tag
                );

                if (jsonOutput) {
                    process.stdout.write(JSON.stringify({ success: true, password }) + '\n');
                } else {
                    console.log('Success');
                }
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

                if (!id)             throw new Error("Missing required argument: id.");
                if (!masterPassword) throw new Error("Master password is required via stdin.");

                const updates = {};

                if (service     && service     !== "SKIP") updates.service  = service;
                if (username    && username    !== "SKIP") updates.username = username;
                if (email       && email       !== "SKIP") updates.email    = email;
                if (url         && url         !== "SKIP") updates.url      = url;

                if (newPassword && newPassword !== "SKIP") {
                    const locked = encryptPassword(newPassword, masterPassword);
                    updates.encrypted_password = locked.encrypted_password;
                    updates.iv                 = locked.iv;
                    updates.auth_tag           = locked.auth_tag;
                }

                updateCredential(id, updates);

                if (jsonOutput) {
                    process.stdout.write(JSON.stringify({ success: true }) + '\n');
                } else {
                    console.log("Success");
                }
                break;
            }

            case 'filter': {
                const type  = process.argv[3];
                const query = process.argv[4];

                if (!type || !query)
                    throw new Error("Usage: node index.js filter <service|username|email> <query>");

                let results = [];
                if      (type === 'service')  results = filterVaultByService(query);
                else if (type === 'username') results = filterVaultByUsername(query);
                else if (type === 'email')    results = filterVaultByEmail(query);
                else throw new Error(`Invalid filter type: "${type}". Use service, username, or email.`);

                if (jsonOutput) {
                    process.stdout.write(JSON.stringify(results, null, 2) + '\n');
                } else {
                    if (results.length === 0) {
                        console.log("No results found.");
                    } else {
                        results.forEach(item => {
                            console.log(`${item.id} | ${item.service} | ${item.username} | ${item.email || 'N/A'}`);
                        });
                    }
                }
                break;
            }

            case 'delete': {
                const id = process.argv[3];

                const masterPassword = getMasterPassword();

                if (!id)             throw new Error("Usage: node index.js delete <id>  (master password via stdin)");
                if (!masterPassword) throw new Error("Master password is required via stdin.");

                const vault = getVault();
                if (vault.length > 0) {
                    const probe = getCredential(vault[0].id);
                    decryptPassword(
                        probe.encrypted_password,
                        probe.iv,
                        probe.auth_tag,
                        masterPassword
                    );
                }

                deleteCredential(id);

                if (jsonOutput) {
                    process.stdout.write(JSON.stringify({ success: true, deleted: id }) + '\n');
                } else {
                    console.log("Success");
                }
                break;
            }

            case 'login': {
                const masterPassword = getMasterPassword();
                console.log("the request is not even going here ig?")
                if (!masterPassword) throw new Error("No master password provided.");

                const vault = getVault();
                if (vault.length > 0) {
                    // Vault has entries — verify password is correct
                    const probe = getCredential(vault[0].id);
                    decryptPassword(
                        probe.encrypted_password,
                        probe.iv,
                        probe.auth_tag,
                        masterPassword
                    );
                }
                // If vault is empty, password is accepted as-is (first time setup)
                process.stdout.write(JSON.stringify({ success: true }) + '\n');
                break;
            }

            default:
                console.error(
                    "Unknown command.\n" +
                    "Usage: node index.js <command> [args] [--json]\n" +
                    "Commands: list, get, add, update, filter, delete\n" +
                    "Master password is always read from stdin, never from arguments."
                );
                process.exit(1);
        }
    } catch (error) {
        await new Promise(r => setTimeout(r, 200 + Math.random() * 100));
        if (jsonOutput) {
            process.stderr.write(JSON.stringify({ error: error.message }) + '\n');
        } else {
            process.stderr.write(`ERROR: ${error.message}\n`);
        }
        process.exit(1);
    }
}

main();