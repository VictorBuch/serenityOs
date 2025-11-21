{ config, lib, pkgs, ... }:

{
  # PostgreSQL backup service (for Immich)
  systemd.services.postgres-backup = {
    description = "Backup PostgreSQL databases to mergerFS pool";
    path = with pkgs; [postgresql gzip coreutils findutils];
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail

      BACKUP_DIR="/mnt/pool/backups/postgres"
      DAILY_DIR="''${BACKUP_DIR}/daily"
      WEEKLY_DIR="''${BACKUP_DIR}/weekly"
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      DAY_OF_WEEK=$(date +%u)  # 1 = Monday, 7 = Sunday

      # Create backup directories
      mkdir -p "''${DAILY_DIR}" "''${WEEKLY_DIR}"

      echo "Starting PostgreSQL backup at $(date)"

      # Backup all databases
      for DB in $(psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1')"); do
        DB=$(echo ''${DB} | xargs)  # Trim whitespace
        echo "Backing up database: ''${DB}"

        pg_dump -U postgres "''${DB}" | gzip > "''${DAILY_DIR}/''${DB}_''${TIMESTAMP}.sql.gz"
      done

      # Copy to weekly if it's Sunday
      if [ "''${DAY_OF_WEEK}" -eq 7 ]; then
        echo "Sunday backup - copying to weekly retention"
        cp -r "''${DAILY_DIR}"/* "''${WEEKLY_DIR}/" || true
      fi

      # Retention: Keep 7 daily backups
      echo "Cleaning up old daily backups (keeping last 7)"
      find "''${DAILY_DIR}" -name "*.sql.gz" -type f -mtime +7 -delete

      # Retention: Keep 4 weekly backups
      echo "Cleaning up old weekly backups (keeping last 4 weeks)"
      find "''${WEEKLY_DIR}" -name "*.sql.gz" -type f -mtime +28 -delete

      echo "PostgreSQL backup completed at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
  };

  # MySQL/MariaDB backup service (for Nextcloud)
  systemd.services.mysql-backup = {
    description = "Backup MySQL databases to mergerFS pool";
    path = with pkgs; [mariadb gzip coreutils findutils];
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail

      BACKUP_DIR="/mnt/pool/backups/mysql"
      DAILY_DIR="''${BACKUP_DIR}/daily"
      WEEKLY_DIR="''${BACKUP_DIR}/weekly"
      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      DAY_OF_WEEK=$(date +%u)

      # Create backup directories
      mkdir -p "''${DAILY_DIR}" "''${WEEKLY_DIR}"

      echo "Starting MySQL backup at $(date)"

      # Backup all databases
      for DB in $(mysql -N -e "SHOW DATABASES" | grep -v -E '^(information_schema|performance_schema|mysql|sys)$'); do
        echo "Backing up database: ''${DB}"

        mysqldump --single-transaction --routines --triggers "''${DB}" | gzip > "''${DAILY_DIR}/''${DB}_''${TIMESTAMP}.sql.gz"
      done

      # Copy to weekly if it's Sunday
      if [ "''${DAY_OF_WEEK}" -eq 7 ]; then
        echo "Sunday backup - copying to weekly retention"
        cp -r "''${DAILY_DIR}"/* "''${WEEKLY_DIR}/" || true
      fi

      # Retention: Keep 7 daily backups
      echo "Cleaning up old daily backups (keeping last 7)"
      find "''${DAILY_DIR}" -name "*.sql.gz" -type f -mtime +7 -delete

      # Retention: Keep 4 weekly backups
      echo "Cleaning up old weekly backups (keeping last 4 weeks)"
      find "''${WEEKLY_DIR}" -name "*.sql.gz" -type f -mtime +28 -delete

      echo "MySQL backup completed at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "mysql";
    };
  };

  # Timers for automated backups
  systemd.timers.postgres-backup = {
    description = "Daily PostgreSQL backup timer";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "01:00";  # 1 AM daily
      Persistent = true;
    };
  };

  systemd.timers.mysql-backup = {
    description = "Daily MySQL backup timer";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "01:30";  # 1:30 AM daily
      Persistent = true;
    };
  };
}
