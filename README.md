# 🧠 Notes Kernel

**Notes Kernel (nk)** is a lightweight CLI toolkit for managing your personal or research vaults.  
It handles the entire flow from **video recording -> audio -> transcript -> note**, powered by local tools and open-source AI.
It also enables you to keep things simple and just create a quick note too.
Works beautifully to create note vaults that you can manage on Obsidian for example.

---

## 📦 Features

| Stage | Command | Description |
|--------|----------|-------------|
| 🗂️ Vault setup | `nk vault init [path]` | Initializes a vault folder structure |
| 🎬 Video to Audio | `nk videos process [vault-path]` | Converts `.mp4` videos to `.mp3` audios |
| 🎧 Audio to Text | `nk audios process [vault-path]` | Transcribes `.mp3` audios to `.txt` transcripts using Whisper |
| 🎤 Record Audio | `nk audios record [vault-path]` | Record `.mp3` audios directly from the terminal |
| 📝 Notes | `nk notes new "title"` | Creates a markdown note with a standard template |
| ⚙️  Environment | `nk init` | Sets up or updates the local Python virtual environment |

All commands are invoked through the single CLI entrypoint `nk`.

---

## 🧩 Architecture

Notes Kernel is intentionally modular:

| Layer | Responsibility |
|--------|----------------|
| `nk.py` | Main CLI entrypoint and command router |
| `notes-videos-to-audios.sh` | Converts all videos in a vault folder |
| `notes-audios-to-texts.sh` | Transcribes all audios in a vault folder |
| `venv/` | Local environment with required Python packages |
| `requirements.txt` | List of Python dependencies (`openai-whisper`, etc.) |
| `mp3-to-txt-file.sh` | Transcribes a single `.mp3` to `.txt` using Whisper (internals) |
| `mp4-to-mp3-file.sh` | Converts a single `.mp4` to `.mp3` (internals) |

This separation ensures:
- Each layer does **one thing well**
- Vaults stay **data-only**
- The kernel is **reproducible** and **self-contained**

---

## 🧭 Typical Vault Layout

```
vault/
├── videos/
│   ├── inbox/
│   │   ├── 2025-11-04 13-05-23.mp4
│   │   └── ...
│   └── archive/
├── audios/
│   ├── inbox/
│   │   ├── 2025-11-04 13-05-23.mp3
│   │   └── ...
│   ├── transcripts/
│   │   ├── 2025-11-04 13-05-23.txt
│   │   └── ...
│   └── archive/
└── notes/
    ├── 2025-11-30-my-idea.md
    └── ...
```

---

## ⚙️ Setup

### 1. Clone this repo

```bash
git clone https://github.com/YOUR-USERNAME/notes-kernel.git ~/Bruno/code/notes-kernel
cd ~/Bruno/code/notes-kernel
```

### 2. Initialize local environment

```bash
nk init
```

This creates `./venv` and installs all dependencies listed in `requirements.txt`.

### 3. Add alias to your shell (`~/.zshrc` or `~/.bashrc`)

Or if you're using `oh-my-zsh` add it on ~/.oh-my-zsh/custom/my-aliases.zsh
```bash
export NOTES_KERNEL_DIR="$HOME/Bruno/code/notes-kernel"
alias nk='PATH="$NOTES_KERNEL_DIR/venv/bin:$PATH" python3 "$NOTES_KERNEL_DIR/nk.py"'
```

Reload your shell:
```bash
source ~/.zshrc
```

---

## 🧪 Usage

### Initialize a vault
```bash
cd ~/Bruno/vaults/bruno-vault
nk vault init .
```

### Convert videos into audios
```bash
nk videos process
```

### Transcribe audios → texts
```bash
nk audios process
```

### Create a new note
```bash
nk notes new "My Idea"
```

This creates:
```
notes/2025-11-30-my-idea.md
```

with:
```markdown
# My Idea

## Tags:
```

---

## 🧰 Dependencies

### System-level
- `ffmpeg` (for video → audio)
- `python3` (>= 3.10)

Install on Ubuntu:
```bash
sudo apt update
sudo apt install ffmpeg python3-venv
```

### Python (via `requirements.txt`)
```
openai-whisper
```

Add more dependencies as needed and rerun `nk init`.

---

## 🧠 Philosophy

Notes Kernel follows **antifragile design principles**:

| Principle | Applied as |
|------------|-------------|
| **Separation of concerns** | Each shell script does one job; wrappers manage orchestration |
| **Self-containment** | The environment lives inside the kernel folder (`venv/`) |
| **Transparency** | All conversions and moves are visible in stdout |
| **Composability** | Each stage (video → audio → text → note) can be run independently |
| **Resilience** | Errors in one step don’t corrupt vault data |

---

## 🩺 Diagnostics

To verify setup:

```bash
which ffmpeg
which python3
nk init
```

If `nk videos process` or `nk audios process` show `⚠️ Skipped`, check paths or missing binaries.

---

## 🧰 Roadmap Ideas

- [ ] `nk videos rec` – record video from the terminal

---

# 🪪 License
This project is licensed under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

If you use or distribute this project, please credit:
**“Based on Notes Kernel by Bruno Coelho — https://github.com/rabb1tpt/notes-kernel”**

---

## ✨ Credits

Built by **Bruno Coelho**  
Philosophy: *"Antifragile systems turn noise into knowledge."*
