import fs, { readdirSync } from 'fs'
import os from 'os'
import path from 'path'


const configDir = path.join(os.homedir(), '.config', 'hypr-vault');
const backupDir = path.join(configDir, 'backups');

export function createBackup() {
    try {

        if(!fs.existsSync(backupDir)){
            fs.mkdirSync(backupDir, { recursive: true, mode: 0o700})
        }
        const dbPath = path.join(configDir, 'vault.db');
        const saltPath = path.join(configDir, 'salt.txt');

        if(!fs.existsSync(dbPath)){
            return;
        }

        if(fs.existsSync(saltPath)){
            const backupSaltPath = path.join(backupDir, 'salt_backup.txt');
            if(!fs.existsSync(backupSaltPath)){
                fs.copyFileSync(saltPath, backupSaltPath);
                fs.chmodSync(backupSaltPath, 0o600)
            }
        }

        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const newBackupDbPath = path.join(backupDir, `vault_backup_${timestamp}.db`);
        
        fs.copyFileSync(dbPath, newBackupDbPath)
        fs.chmodSync(newBackupDbPath, 0o600)

        const files = readdirSync(backupDir)

        const dbBackups = files
            .filter(f => f.startsWith(`vault_backup_`) && f.endsWith(`.db`))
            .map(f => ({
                name: f,
                path: path.join(backupDir, f),
                time: fs.statSync(path.join(backupDir, f)).mtime.getTime()
            }))
            .sort((a, b) => b.time - a.time);

        if(dbBackups.length > 10){
            const backupsToDelete = dbBackups.slice(10);
            backupsToDelete.forEach(backup => {
                fs.unlinkSync(backup.path);
            });
        }
    } catch (error) {
        console.error(`Backup Failed: ${error.message}`)   
    }
}