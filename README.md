# Minesweeper - PowerShell Terminal Edition

A classic Minesweeper game that runs in the PowerShell terminal with colorized output.

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+

## How to Run

```powershell
.\minesweeper.ps1
```

## Controls

| Key         | Action          |
|-------------|-----------------|
| Arrow keys  | Move cursor     |
| Space       | Reveal cell     |
| F           | Toggle flag     |
| R           | Restart game    |
| Q           | Quit            |

## Difficulty Levels

| Level    | Grid | Mines |
|----------|------|-------|
| Beginner | 9×9  | 10    |
| Medium   | 9×9  | 20    |
| Expert   | 9×9  | 35    |

## Features

- Color-coded numbers (1–8)
- Timer display
- Mine/flag counter
- Safe first move (mines placed after first reveal)
- Flood-fill reveal for empty cells
