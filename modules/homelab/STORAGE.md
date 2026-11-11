# Storage Commands Reference

## MergerFS Pool Status

```bash
# View mounted pools
cat /proc/mounts | grep mergerfs

# Check disk space on all drives
df -h /mnt/disk1 /mnt/disk2 /mnt/parity1 /mnt/cold /mnt/pool /cache

# List files in cache
ls -la /cache
```

## Cache Mover

Moves every file not modified for 2 days from SSD cache (`/cache`) to cold
storage (`/mnt/cold`), regardless of how full the cache is. SnapRAID does not
cover `/cache`, so this is what gets new data under parity.

```bash
# Run cache mover
sudo systemctl start mergerfs-cache-mover

# Check logs
journalctl -u mergerfs-cache-mover

# Force move all cache files regardless of age
sudo rsync -av --remove-source-files /cache/ /mnt/cold/
```

## SnapRAID Commands

SnapRAID protects files on `/mnt/disk1` and `/mnt/disk2` only (not `/cache`).

### Status & Health

```bash
# Check status (changes since last sync)
sudo snapraid status

# SMART disk health info
sudo snapraid smart

# Show differences without syncing
sudo snapraid diff

# List protected files
sudo snapraid list
```

### Sync (Update Parity)

```bash
# Manual sync
sudo snapraid sync

# Via systemd service
sudo systemctl start snapraid-sync
```

### Scrub (Verify Integrity)

```bash
# Default scrub (12% of array)
sudo snapraid scrub

# Scrub specific percentage
sudo snapraid scrub -p 20

# Full verification (slow)
sudo snapraid scrub -p 100

# Only data older than N days
sudo snapraid scrub -o 10
```

### Recovery

```bash
# Check for corruption (read-only)
sudo snapraid check

# Fix corrupted files
sudo snapraid fix
```

## Automated Schedule

| Time    | Service                  | Action                        |
|---------|--------------------------|-------------------------------|
| 12:00   | mergerfs-cache-mover     | Move old cache files to cold  |
| 13:00   | snapraid-sync            | Update parity data            |
| Weekly  | snapraid-scrub           | Verify 12% of array           |

## Data Flow

1. New files write to `/mnt/pool` -> land on `/cache` (SSD)
2. Cache mover moves files not modified for 2 days to `/mnt/cold` (daily, 12:00)
3. `/mnt/cold` is mergerfs union of `/mnt/disk1` + `/mnt/disk2`
4. SnapRAID creates parity for disk1/disk2 on `/mnt/parity1`
