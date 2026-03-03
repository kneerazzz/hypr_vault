import crypto from 'crypto';
import fs from 'fs';
import path from 'path';
import os from 'os';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;

const configDir = path.join(os.homedir(), '.config', 'hypr-vault');
const saltPath  = path.join(configDir, 'salt.txt');


function getOrCreateSalt() {
    try {
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true, mode: 0o700 });
        }
        if (fs.existsSync(saltPath)) {
            return fs.readFileSync(saltPath);
        }
        const newSalt = crypto.randomBytes(16);
        fs.writeFileSync(saltPath, newSalt, { mode: 0o600 });
        return newSalt;
    } catch (error) {
        throw new Error(`Critical error handling cryptographic salt: ${error.message}`);
    }
}

function deriveKey(masterPassword) {
    try {
        const salt = getOrCreateSalt();
        return crypto.scryptSync(masterPassword, salt, 32, {
            N: 2 ** 14,
            r: 8,
            p: 1
        });
    } catch (error) {
        throw new Error(`Failed to derive encryption key: ${error.message}`);
    }
}

export function encryptPassword(password, masterPassword) {
    try {
        const key = deriveKey(masterPassword);
        const iv  = crypto.randomBytes(IV_LENGTH);

        const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

        let encryptedPass  = cipher.update(password, 'utf8', 'hex');
            encryptedPass += cipher.final('hex');

        const authTag = cipher.getAuthTag();

        return {
            encrypted_password: encryptedPass,
            iv:                 iv.toString('hex'),
            auth_tag:           authTag.toString('hex')
        };
    } catch (error) {
        throw new Error(`Encryption failed: ${error.message}`);
    }
}

export function decryptPassword(encryptedHex, ivHex, authTagHex, masterPassword) {
    try {
        const key     = deriveKey(masterPassword);
        const iv      = Buffer.from(ivHex,      'hex');
        const authTag = Buffer.from(authTagHex, 'hex');

        const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
        decipher.setAuthTag(authTag);

        let decryptedPass  = decipher.update(encryptedHex, 'hex', 'utf8');
            decryptedPass += decipher.final('utf8');

        return decryptedPass;
    } catch (error) {
        throw new Error(`Decryption failed (wrong master password or corrupted data): ${error.message}`);
    }
}