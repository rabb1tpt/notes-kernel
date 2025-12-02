#!/usr/bin/env python3
import sys
import subprocess
import datetime
import os

from pathlib import Path

def usage():
    print(
        "Usage:\n"
        "nk init\t-> Sets up or updates the local Python virtual environment\n"
        "\n"
        "nk vault init [path] -> Initializes a vault folder structure\n"
        "\n"
        "nk videos process [vault-path] -> Converts .mp4 videos to .mp3 audios\n"
        "\n"
        "nk audios process [vault-path] -> Transcribes .mp3 audios to .txt transcripts using Whisper\n"
        "nk audios record [vault-path] [filename] -> Records a .mp3 audio note into the vault\n"
        "\n"
        "nk notes new \"title\" -> Creates a markdown note with a standard template\n"
        "\n"
        "nk autosetup systemd [vault-path] [interval] -> Generate systemd service+timer to auto-process audios/videos\n"
    )

def load_systemd_template(name: str) -> str:
    """
    Load a systemd-related template from internals/templates/systemd.
    """
    kernel_dir = Path(__file__).resolve().parent
    tpl_path = kernel_dir / "internals" / "templates" / "systemd" / name
    if not tpl_path.is_file():
        raise SystemExit(f"Template not found: {tpl_path}")
    return tpl_path.read_text()

def autosetup_systemd_generate(rest: list[str]) -> int:
    """
    Usage:
      nk autosetup systemd [vault-path] [interval]

    - vault-path: optional, default "."
    - interval:   optional, default "5min" (systemd time span, e.g. 10min, 1h)
    """
    vault_raw = rest[0] if len(rest) >= 1 else "."
    interval = rest[1] if len(rest) >= 2 else "5min"

    vault = Path(normalize_path(vault_raw)).resolve()
    if not vault.exists():
        print(f"Error: vault path does not exist: {vault}")
        return 1

    vault_id = vault.name

    # Where this nk.py lives and which Python is running it
    kernel_dir = Path(__file__).resolve().parent
    nk_py = kernel_dir / "nk.py"
    python_bin = sys.executable

    # 1) Runner script inside the vault (versioned with the vault)
    auto_dir = vault / ".nk" / "auto"
    auto_dir.mkdir(parents=True, exist_ok=True)
    runner_script_path = auto_dir / f"run_nk_{vault_id}.sh"

    runner_tpl = load_systemd_template("run_nk_on_vault.sh.tpl")
    runner_content = runner_tpl.format(
        vault_path=str(vault),
        vault_id=vault_id,
        nk_py=str(nk_py),
        python_bin=python_bin,
        runner_script_path=str(runner_script_path),
        interval=interval,
    )
    runner_script_path.write_text(runner_content)
    runner_script_path.chmod(0o755)

    # 2) Systemd user units under ~/.config/systemd/user
    config_root = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    user_systemd = config_root / "systemd" / "user"
    user_systemd.mkdir(parents=True, exist_ok=True)

    service_path = user_systemd / f"nk-{vault_id}.service"
    timer_path = user_systemd / f"nk-{vault_id}.timer"

    service_tpl = load_systemd_template("nk-vault.service.tpl")
    timer_tpl = load_systemd_template("nk-vault.timer.tpl")

    service_content = service_tpl.format(
        vault_path=str(vault),
        vault_id=vault_id,
        nk_py=str(nk_py),
        python_bin=python_bin,
        runner_script_path=str(runner_script_path),
        interval=interval,
    )
    timer_content = timer_tpl.format(
        vault_path=str(vault),
        vault_id=vault_id,
        nk_py=str(nk_py),
        python_bin=python_bin,
        runner_script_path=str(runner_script_path),
        interval=interval,
    )

    service_path.write_text(service_content)
    timer_path.write_text(timer_content)

    print("✅ Generated automation files:")
    print(f"  Runner script: {runner_script_path}")
    print(f"  Service unit:  {service_path}")
    print(f"  Timer unit:    {timer_path}")
    print()
    print("To activate this timer, run:")
    print(f"  nk autosetup systemd-activate {vault}")
    return 0



def autosetup_systemd_activate(rest: list[str]) -> int:
    """
    nk autosetup systemd-activate [vault-path]

    Activates the systemd timer for the given vault by name:
      nk-<vault-id>.timer

    Assumes autosetup_systemd_generate was already run so that
    the .service and .timer files exist under ~/.config/systemd/user.
    """
    vault_raw = rest[0] if len(rest) >= 1 else "."
    vault = Path(normalize_path(vault_raw)).resolve()
    if not vault.exists():
        print(f"Error: vault path does not exist: {vault}")
        return 1

    vault_id = vault.name

    config_root = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    user_systemd = config_root / "systemd" / "user"
    service_path = user_systemd / f"nk-{vault_id}.service"
    timer_path = user_systemd / f"nk-{vault_id}.timer"

    missing: list[str] = []
    if not service_path.is_file():
        missing.append(str(service_path))
    if not timer_path.is_file():
        missing.append(str(timer_path))

    if missing:
        print("Error: missing systemd unit files:")
        for m in missing:
            print(f"  {m}")
        print("Run `nk autosetup systemd [vault-path] [interval]` first.")
        return 1

    try:
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
        subprocess.run(
            ["systemctl", "--user", "enable", "--now", f"nk-{vault_id}.timer"],
            check=True,
        )
        print(f"✅ Activated timer: nk-{vault_id}.timer for vault {vault}")
    except Exception as e:
        print(f"⚠️ Failed to activate timer: {e}")
        print("You can also try manually:")
        print("  systemctl --user daemon-reload")
        print(f"  systemctl --user enable --now nk-{vault_id}.timer")
        return 1

    return 0



def normalize_path(raw: str | None) -> str:
    """
    - None / "" / "." -> "."
    - "~" / "~/..."  -> expanded to $HOME
    - other paths -> absolute path via resolve()
    """
    if not raw or raw == ".":
        return "."
    p = Path(raw).expanduser()
    # resolve() with strict=False: ok if path doesn't exist yet
    try:
        p = p.resolve(strict=False)
    except TypeError:
        # older Python: resolve() without strict kw arg
        p = p.resolve()
    return str(p)


def run_script(script_name: str, *args: str) -> int:
    print("nk.py - run_script start...")
    kernel_dir = Path(__file__).resolve().parent
    script = kernel_dir / "internals" / script_name
    if not script.exists():
        print(f"Error: {script_name} not found in {kernel_dir}")
        return 1
    
    cmd = [str(script), *[str(a) for a in args]]
    print(f"nk.py - cmd ready: {cmd}")

    try:
        # keep strict behavior: non-zero exit → CalledProcessError
        print("nk.py - calling cmd...")
        result = subprocess.run(cmd, check=True)
        print(f"nk.py - cmd result: {result}")
        return result.returncode
    except KeyboardInterrupt:
        # User hit Ctrl+C (e.g. stop ffmpeg).
        # At this point the child has already handled SIGINT and flushed output.
        # We treat this as a normal, intentional stop.
        return 0
    except subprocess.CalledProcessError as e:
        print("❌ nk.py - cmd failed!")
        print(f"   Command: {e.cmd}")
        print(f"   Exit code: {e.returncode}")

        # stderr
        if e.stderr:
            print("   --- STDERR ---")
            print(e.stderr.decode().strip())

        # stdout
        if e.output:
            print("   --- STDOUT ---")
            print(e.output.decode().strip())

        return e.returncode

def main(argv: list[str]) -> int:
    if not argv or argv[0] in {"help", "-h", "--help"}:
        usage()
        return 0

    cmd = argv[0]
    sub = argv[1] if len(argv) > 1 else None
    rest = argv[2:] if len(argv) > 2 else []

    if cmd == "init":
        """
        Initializes or updates the local notes-kernel environment.
        - Creates ./venv inside the kernel directory
        - Installs from requirements.txt
        - Checks for ffmpeg
        """
        kernel_dir = Path(__file__).resolve().parent
        venv_dir = kernel_dir / "venv"
        venv_bin = venv_dir / "bin"
        req_file = kernel_dir / "requirements.txt"

        if not req_file.exists():
            print(f"Error: requirements.txt not found at {req_file}")
            return 1

        # 1. Create local venv if needed
        if not venv_dir.exists():
            print(f"📦 Creating virtual environment at {venv_dir}")
            subprocess.run([sys.executable, "-m", "venv", str(venv_dir)], check=True)

        # 2. Upgrade pip and install requirements
        print("🔧 Installing Python dependencies from requirements.txt...")
        subprocess.run([str(venv_bin / "pip"), "install", "--upgrade", "pip"], check=True)
        subprocess.run([str(venv_bin / "pip"), "install", "-r", str(req_file)], check=True)

        # 3. Check ffmpeg
        print("🔍 Checking for ffmpeg...")
        ffmpeg_check = subprocess.run(
            ["ffmpeg", "-version"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if ffmpeg_check.returncode != 0:
            print("🔴 ffmpeg not found on PATH.")
            print("   Install it via your system package manager, e.g.:")
            print("   sudo apt install ffmpeg")

        print(f"\n✅ notes-kernel environment ready at {venv_dir}")
        print("   You can now add an alias like:")
        print(f"  Add alias -> PATH=\"{venv_bin}:$PATH\" python {kernel_dir}/nk.py")
        return 0

    if cmd == "vault":
        if sub == "init":
            target = normalize_path(rest[0] if rest else ".")
            return run_script("notes-init.sh", target)
        else:
            print("Unknown vault command:", sub or "<missing>")
            print("Usage: nk vault init [path]")
            return 1

    if cmd == "videos":
        if sub == "process":
            target = normalize_path(rest[0] if rest else ".")
            return run_script("notes-videos-to-audios.sh", target)
        else:
            print("Unknown videos command:", sub or "<missing>")
            print("Usage: nk videos process [vault-path]")
            return 1

    if cmd == "notes":
        if sub == "new":
            if not rest:
                print("Usage: nk notes new \"note title\"")
                return 1
            note_title = rest[0]
            date_prefix = datetime.date.today().strftime("%Y-%m-%d")
            safe_title = note_title.lower().replace(" ", "-")
            filename = f"{date_prefix}-{safe_title}.md"

            notes_dir = Path(".") / "notes"
            notes_dir.mkdir(exist_ok=True)
            note_path = notes_dir / filename

            if note_path.exists():
                print(f"Note already exists: {note_path}")
                return 1

            with open(note_path, "w") as f:
                f.write(f"# {note_title}\n")
                f.write("## Tags:\n\n")

            print(f"Created: {note_path}")
            return 0
        else:
            print("Unknown note command:", sub or "<missing>")
            print("Usage: nk note new \"note title\"")
            return 1

    if cmd == "audios":
        if sub == "process":
            target = normalize_path(rest[0] if rest else ".")
            return run_script("notes-audios-to-texts.sh", target)

        elif sub == "record":
            # Supported forms:
            # nk audios record
            # nk audios record "name"
            # nk audios record /path/to/vault
            # nk audios record /path/to/vault "name"
            vault = "."
            name = ""

            if len(rest) == 0:
                # nk audios record
                pass
            elif len(rest) == 1:
                arg = rest[0]
                # Heuristic: if it looks like a path, treat as vault, else as filename
                if arg == "." or "/" in arg or arg.startswith("~"):
                    vault = normalize_path(arg)
                else:
                    name = arg
            else:
                # len(rest) >= 2
                vault = normalize_path(rest[0])
                name = rest[1]

            return run_script("notes-audios-record.sh", vault, name)

        else:
            print("Unknown audios command:", sub or "<missing>")
            print("Usage:")
            print("  nk audios process [vault-path]")
            print("  nk audios record [vault-path] [filename]")
            return 1

    if cmd == "autosetup":
        if sub == "systemd":
            return autosetup_systemd_generate(rest)
        if sub == "systemd-activate":
            return autosetup_systemd_activate(rest)
        print("Unknown autosetup command:", sub or "<missing>")
        print("Usage:")
        print("  nk autosetup systemd [vault-path] [interval]")
        print("  nk autosetup systemd-activate [vault-path]")
        return 1

    print("Unknown nk command:", cmd)
    print("Run 'nk help' for usage.")
    return 1

    

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

