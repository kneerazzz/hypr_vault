//Function to decrypt .json file with salt.txt and vault.db fixed
import fs from 'fs'
import crypto from 'crypto'

const ALGORITHM = 'aes-256-gcm';

export function decryptRaw(encryptedHex, ivHex, authTagHex, key) {
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
}

async function getYourPass(filePath, masterPassword) {
    let entries = []

    const fileData = JSON.parse(fs.readFileSync(filePath, 'utf8'))
    if(fileData.locked_vault) {
        const bundleKey = crypto.scryptSync(masterPassword, 'hypr-vault-bundle-salt', 32, { N: 2 ** 14, r: 8, p: 1 });
        const decryptedBundle = decryptRaw(fileData.locked_vault, fileData.iv, fileData.auth_tag, bundleKey);
        entries = JSON.parse(decryptedBundle);
    } else {
        entries = fileData;
    }
    return entries;
}


if(process.argv[1].endsWith('getYourPass.js')){
    const [file, pass] = process.argv.slice(2);
    if (!file || !pass) {
        console.log("\nUsage: node recovery.js <vault.db|.json> <password>");
        process.exit(1);
    }
    const key = crypto.scryptSync(pass, 'hypr-vault-bundle-salt', 32, { N: 2 ** 14, r: 8, p: 1});
    getYourPass(file, pass)
        .then(entries => {
            console.log(`\n=== 🔓 RECOVERY SUCCESSFUL: ${entries.length} ENTRIES ===\n`);
            entries.forEach((e, i) => {
                const encData = e.encrypted_password || e.password;
                const clearPass = decryptRaw(encData, e.iv, e.auth_tag, key)
                console.log(`${i + 1}. [${e.service.toUpperCase()}]`);
                console.log(`   User: ${e.username || 'N/A'}`);
                console.log(`   Mail: ${e.email || 'N/A'}`);
                console.log(`   URL:  ${e.url || 'N/A'}`);
                console.log(`   Pass: ${clearPass}`);
                console.log('   ' + '-'.repeat(30));
            });
        })
        .catch(err => console.error("\n❌ Recovery Failed:", err.message));
}