# 🧠 Notes Kernel (`nk`)

Notes Kernel (nk) is a lightweight CLI toolkit for managing your personal note vaults.

It handles the entire flow from video recording -> audio -> transcript -> note, powered by local tools and open-source AI (like OpenAI Whisper).

It also enables you to keep things simple and just create a quick note too. 

Works beautifully to create note vaults that you can manage on Obsidian for example.

---

# 🚀 Commands Overview

### 🔧 Environment Setup
| Command | Description |
|--------|-------------|
| `nk init` | Creates/updates local `venv/`, installs dependencies, checks ffmpeg |

---

### 🗂️ Vault Management
| Command | Description |
|--------|-------------|
| `nk vault init [path]` | Initializes a vault folder structure |

---

### 🎬 Video → Audio
| Command | Description |
|--------|-------------|
| `nk videos process [vault-path]` | Converts `.mp4` → `.mp3` into `audios/inbox/` |

---

### 🎧 Audio → Transcript
| Command | Description |
|--------|-------------|
| `nk audios process [vault-path]` | Transcribes `.mp3` → `.txt` via Whisper |
| `nk audios record [vault-path] [filename]` | Records audio directly into the vault |

---

### 📝 Notes
| Command | Description |
|--------|-------------|
| `nk notes new "title"` | Creates a markdown note with date prefix |
| `nk daily` | Creates (or opens) the daily note using templates |

> Daily notes now support templates:
- Vault override: `.nk/templates/notes/daily.md.tpl`
- Kernel fallback: `internals/templates/notes/daily.md.tpl`

Templates may use `{date}` placeholder.

---

### ⚙️ Systemd Auto-Processing
| Command | Description |
|--------|-------------|
| `nk autosetup systemd [vault-path] [interval]` | Generates systemd service + timer |
| `nk autosetup systemd-activate [vault-path]` | Activates the timer |
| `nk auto status [vault-path]` | Show timer/service status |
| `nk auto queue [vault-path]` | Count pending items |
| `nk auto run [vault-path]` | Manually trigger a run |
| `nk auto logs [vault-path]` | View recent logs |
| `nk auto enable / disable [vault-path]` | Toggle automation |

Automation is vault-specific.  
Units are placed into:

```
~/.config/systemd/user/nk-<vault-name>.service
~/.config/systemd/user/nk-<vault-name>.timer
```

The vault itself receives a runnable script:

```
.vault/.nk/auto/run_nk_<vault>.sh
```

---

# 📐 Vault Layout

```
vault/
├── videos/
│   ├── inbox/
│   └── archive/
├── audios/
│   ├── inbox/
│   ├── transcripts/
│   └── archive/
├── notes/
├── daily/
├── .nk/
│   ├── auto/
│   │   └── run_nk_<vault>.sh
│   └── templates/
│       └── notes/
│           └── daily.md.tpl (optional override)
```

---

# 🧩 Architecture

### nk.py (the router)
Handles:
- command parsing
- path normalization
- editor launching
- template loading
- dispatch to shell scripts in `internals/`

### Shell scripts (inside `internals/`)
- `notes-init.sh`
- `notes-videos-to-audios.sh`
- `notes-audios-to-texts.sh`
- `notes-audios-record.sh`
- `notes-auto-service.sh`

Each is isolated and versioned inside the kernel.

### Templates
Found under:

```
internals/templates/notes/*.tpl
internals/templates/systemd/*.tpl
```

Vaults may override notes templates under:

```
.vault/.nk/templates/notes/
```

---

# 🧪 Setup Instructions

### 1. Clone
```bash
git clone https://github.com/YOUR-USERNAME/notes-kernel.git
cd notes-kernel
```

### 2. Initialize the kernel environment
```bash
nk init
```

This:
- Creates `venv/`
- Installs pip requirements
- Validates ffmpeg availability

### 3. Shell Alias
Add to `~/.zshrc`:

```bash
export NOTES_KERNEL_DIR="$HOME/code/notes-kernel"
alias nk='PATH="$NOTES_KERNEL_DIR/venv/bin:$PATH" python3 "$NOTES_KERNEL_DIR/nk.py"'
```

---

# 🛠 Usage Examples

### Initialize a vault
```bash
nk vault init ~/Bruno/vaults/bruno2brain
```

### Convert videos → audios
```bash
nk videos process .
```

### Transcribe audios → text
```bash
nk audios process .
```

### Record audio note
```bash
nk audios record . "idea-about-bitcoin"
```

### Create note
```bash
nk notes new "Bitcoin thesis"
```

### Daily note
```bash
nk daily
```

Loads template if available.

---

# ⚡ Systemd Automation

### Generate units (default interval: 5min)
```bash
nk autosetup systemd ~/Bruno/vaults/bruno2brain 5min
```

### Activate
```bash
nk autosetup systemd-activate ~/Bruno/vaults/bruno2brain
```

---

# 🧰 Dependencies

### System Packages
- `ffmpeg`
- `python3` (>= 3.10)

Ubuntu:
```bash
sudo apt install ffmpeg python3-venv
```

### Python packages (`requirements.txt`)
```
openai-whisper
```

Add more → rerun `nk init`.

---

# 🧠 Philosophy

Notes Kernel embodies antifragile design:

| Principle | How it appears |
|----------|----------------|
| Via negativa | Fewer moving parts; avoid magic sync engines |
| Optionality | Each stage is independent |
| Transparency | All executions printed to stdout |
| Flexibility | Templates override at vault level |
| Resilience | Failures never corrupt vault data |
| Robust automation | systemd timers instead of ad-hoc cron hacks |

---

# 🪪 License
Licensed under **CC BY 4.0**.
