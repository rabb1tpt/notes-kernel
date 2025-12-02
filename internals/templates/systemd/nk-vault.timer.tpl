[Unit]
Description=Timer to run notes-kernel processing on vault {vault_id}

[Timer]
OnBootSec=2min
OnUnitActiveSec={interval}
AccuracySec=1min
Persistent=true
Unit=nk-{vault_id}.service

[Install]
WantedBy=timers.target

