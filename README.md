# 🧠 Notes Kernel (`nk`)

A tiny, fast CLI that helps you **capture, process, and organize notes** inside a vault you control.

- Create notes instantly  
- Capture audio → transcripts automatically  
- Structure your thinking (inbound, drafts, insights, study modules)  
- Automate everything via systemd  
- Fully compatible with Obsidian

**Simple mental model:**  
> “nk creates the right note in the right place with the right template.”

---

# 🚀 Quick Start

### 1. Install
```bash
nk init
```
Creates/updates the local virtual environment and checks for ffmpeg.

### 2. Create a vault
```bash
nk vault init ~/myvault
```

### 3. Start taking notes
```bash
cd ~/myvault
nk notes new "My first note"
nk daily
nk inbound inbox "Idea about Bitcoin"
nk thinking draft "Article on antifragility"
```

That’s the core workflow.

---

# 🗂️ Commands Overview

## Notes
| Command | Description |
|--------|-------------|
| `nk notes new "title"` | Create a basic note in `notes/` |
| `nk notes insight [title]` | Create an evergreen insight note |
| `nk daily` | Create or open today’s daily note |

Templates (optional):

```
.vault/.nk/templates/notes/
```

Vault template overrides kernel template automatically.

---

## Inbound (Capture Flow)
| Command | Description |
|--------|-------------|
| `nk inbound inbox [title]` | Quick capture note |
| `nk inbound processing [title]` | Processing note |

Perfect for “get it out of your head now, sort later.”

---

## Thinking (Writing Flow)
| Command | Description |
|--------|-------------|
| `nk thinking inbox [title]` | Raw ideas |
| `nk thinking draft [title]` | Draft essays/frameworks |
| `nk thinking publication [title]` | Final/publishable notes |

---

## Study (Structured Learning)
| Command | Description |
|--------|-------------|
| `nk study index "Study Title"` | Create a study root folder |
| `nk study module "Study Title"` | Add module (auto-numbered) |
| `nk study open "Study Title"` | Open index note |

Great for courses, books, long-term topics.

---

## Media Processing
### Video to Audio
```bash
nk videos process [vault]
```

### Audio to Transcript
```bash
nk audios process [vault]
```

### Record audio note
```bash
nk audios record [vault] [filename]
```

These commands funnel all media → transcripts → notes automatically.

---

## Automation (systemd)
| Command | Description |
|--------|-------------|
| `nk autosetup systemd [vault] [interval]` | Generate automation units |
| `nk autosetup systemd-activate [vault]` | Activate timer |
| `nk auto status [vault]` | Status of auto-processing |
| `nk auto queue [vault]` | Count pending media |
| `nk auto run [vault]` | Trigger now |
| `nk auto logs [vault]` | Show logs |
| `nk auto enable/disable [vault]` | Toggle |

This keeps your vault always up-to-date without thinking about it.

---

# 📐 Vault Layout (Minimal View)

```
vault/
├── notes/
├── inbound/
│   ├── inbox/
│   └── processing/
├── thinking/
│   ├── inbox/
│   ├── drafts/
│   └── publications/
├── studies/
├── daily/
├── videos/
│   ├── inbox/
│   └── archive/
├── audios/
│   ├── inbox/
│   ├── transcripts/
│   └── archive/
└── .nk/
    ├── auto/
    └── templates/
```

Everything has one obvious place.

---

# 🧪 Setup (Once)

Add to `.zshrc`:

```bash
export NOTES_KERNEL_DIR="$HOME/code/notes-kernel"
alias nk='PATH="$NOTES_KERNEL_DIR/venv/bin:$PATH" python3 "$NOTES_KERNEL_DIR/nk.py"'
```

---

# 🧘 Philosophy

**Less is more.**  
The kernel avoids complexity and stays out of your way.

Core principles:

- **Local-first.** Your notes stay on your machine.  
- **Fail-safe.** Errors never corrupt your vault.  
- **Predictable.** Every command does exactly one thing.  
- **Extensible.** Templates override easily, no magic.  
- **Automation without mystery.** systemd keeps things running without background daemons.

---

# 🪪 License

CC BY 4.0
