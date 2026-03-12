# Cloud-Agnostic Encrypted Backup Engine (GFS)

## Overview
A Bash script to create encrypted, compressed snapshots of a directory, sync them to AWS S3, Google Cloud Storage, or a remote VPS via rsync, and implement Grandfather-Father-Son (GFS) rotation. After upload, it decrypts and verifies a random file for integrity.

---

## Usage
```bash
./cloud-backup-gfs.sh /path/to/source [aws|gcs|rsync] [DESTINATION] [PASSPHRASE]
```
- `/path/to/source` — Directory to back up
- `aws` — Use AWS S3 (requires AWS CLI configured)
- `gcs` — Use Google Cloud Storage (requires gsutil configured)
- `rsync` — Use rsync to remote VPS or server
- `DESTINATION` — S3 bucket, GCS bucket, or rsync target (e.g., s3://mybucket/backups/)
- `PASSPHRASE` — Encryption passphrase

---

## Example: AWS S3
```bash
./cloud-backup-gfs.sh /home/user/data aws s3://mybucket/backups/ mySecretPass
```

## Example: Google Cloud Storage
```bash
./cloud-backup-gfs.sh /var/www gcs gs://mybucket/backups/ anotherPassphrase
```

## Example: Remote VPS via rsync
```bash
./cloud-backup-gfs.sh /etc rsync user@backupserver:/srv/backups/ strongPass
```

---

## GFS Rotation
- **Son**: Daily backup (keeps last 7)
- **Father**: Weekly backup (keeps last 4, created on Sundays)
- **Grandfather**: Monthly backup (keeps last 12, created on the 1st)

Backups are named with type and timestamp, e.g.:
```
data-son-20260312-153000.tar.gz.enc
```

---

## Integrity Check
After upload, the script decrypts the backup, lists its contents, and extracts a random file to verify successful encryption/decryption and archive integrity.

---

## Requirements
- Bash, tar, openssl
- AWS CLI, gsutil, or rsync (depending on sync method)

---

## Security Note
- Store your passphrase securely. Anyone with the passphrase and backup file can decrypt your data.
- Test restore regularly!
