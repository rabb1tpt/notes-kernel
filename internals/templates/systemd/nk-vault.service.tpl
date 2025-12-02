[Unit]
Description=Run notes-kernel processing on vault {vault_id}

[Service]
Type=oneshot
ExecStart={runner_script_path}

[Install]
WantedBy=default.target

