# 013 - VS Code: Copilot's instructions file

```
013_VSCode_InstructionsFile.md
Demo 1, step 8 - VS Code: Copilot's instructions file (about 1 min)
Session: AI in the SQL World - PASS Summit West 2026
Written by Taiob Ali with assistance from GitHub Copilot
taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified
November 10, 2026
```

**Why this step:** VS Code's counterpart to SSMS database instructions (009). SSMS keeps
instructions in the database; VS Code keeps them in a file in the repo.

**Learn facts** (MSSQL extension · Custom instructions)
- GitHub Copilot in VS Code uses `.github/instructions/*.instructions.md`.
- They apply to ask, edit and agent modes and inline completions, for files that match `applyTo`.
- The MSSQL extension needs no extra configuration.

## Before the session
Open the folder `DemoFiles\VSCodeWorkspace` in VS Code (File > Open Folder). It holds the only copy of
the instructions file: `.github/instructions/tsql-conventions.instructions.md`. Nothing to copy.

## On stage
1. In the Explorer, open `.github/instructions/tsql-conventions.instructions.md` and scroll through it (10 seconds).
2. Say: *"Same idea as the database instructions and constitution in SSMS, but it lives in the repo
   with the code. Everything Copilot writes next follows it."*

## How to create one from scratch (Learn steps)
Copilot Chat view > settings (gear) > **Instructions & Rules > New instruction file** >
`.github/instructions` > name it `tsql-conventions`.
