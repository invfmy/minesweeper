# Minesweeper - PowerShell Terminal Edition

$script:ROWS = 9
$script:COLS = 9
$script:MINES = 10

$script:board = @()
$script:visible = @()
$script:flagged = @()
$script:gameOver = $false
$script:gameWon = $false
$script:firstMove = $true
$script:cursorRow = 0
$script:cursorCol = 0
$script:startTime = $null
$script:minePositions = @()

function Initialize-Board {
    $script:board = New-Object 'int[,]' $ROWS, $COLS
    $script:visible = New-Object 'bool[,]' $ROWS, $COLS
    $script:flagged = New-Object 'bool[,]' $ROWS, $COLS
    $script:gameOver = $false
    $script:gameWon = $false
    $script:firstMove = $true
    $script:cursorRow = 0
    $script:cursorCol = 0
    $script:startTime = $null
    $script:minePositions = @()
}

function Place-Mines($safeRow, $safeCol) {
    $placed = 0
    while ($placed -lt $MINES) {
        $r = Get-Random -Minimum 0 -Maximum $ROWS
        $c = Get-Random -Minimum 0 -Maximum $COLS
        if ($script:board[$r,$c] -ne -1 -and -not ($r -eq $safeRow -and $c -eq $safeCol)) {
            $script:board[$r,$c] = -1
            $script:minePositions += ,@($r,$c)
            $placed++
        }
    }
    # Calculate numbers
    for ($r = 0; $r -lt $ROWS; $r++) {
        for ($c = 0; $c -lt $COLS; $c++) {
            if ($script:board[$r,$c] -ne -1) {
                $count = 0
                for ($dr = -1; $dr -le 1; $dr++) {
                    for ($dc = -1; $dc -le 1; $dc++) {
                        $nr = $r + $dr; $nc = $c + $dc
                        if ($nr -ge 0 -and $nr -lt $ROWS -and $nc -ge 0 -and $nc -lt $COLS) {
                            if ($script:board[$nr,$nc] -eq -1) { $count++ }
                        }
                    }
                }
                $script:board[$r,$c] = $count
            }
        }
    }
}

function Reveal-Cell($r, $c) {
    if ($r -lt 0 -or $r -ge $ROWS -or $c -lt 0 -or $c -ge $COLS) { return }
    if ($script:visible[$r,$c] -or $script:flagged[$r,$c]) { return }
    $script:visible[$r,$c] = $true
    if ($script:board[$r,$c] -eq 0) {
        for ($dr = -1; $dr -le 1; $dr++) {
            for ($dc = -1; $dc -le 1; $dc++) {
                Reveal-Cell ($r+$dr) ($c+$dc)
            }
        }
    }
}

function Check-Win {
    for ($r = 0; $r -lt $ROWS; $r++) {
        for ($c = 0; $c -lt $COLS; $c++) {
            if ($script:board[$r,$c] -ne -1 -and -not $script:visible[$r,$c]) { return $false }
        }
    }
    return $true
}

function Get-Elapsed {
    if ($null -eq $script:startTime) { return "00:00" }
    $elapsed = (Get-Date) - $script:startTime
    "{0:D2}:{1:D2}" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds
}

function Get-FlagCount {
    $count = 0
    for ($r = 0; $r -lt $ROWS; $r++) {
        for ($c = 0; $c -lt $COLS; $c++) {
            if ($script:flagged[$r,$c]) { $count++ }
        }
    }
    return $count
}

function Draw-Board {
    $host.UI.RawUI.CursorPosition = @{X=0;Y=0}

    $flagCount = Get-FlagCount
    $remaining = $MINES - $flagCount
    $elapsed = Get-Elapsed

    # Header
    Write-Host ("=" * 31) -ForegroundColor DarkCyan
    Write-Host "  MINESWEEPER  " -NoNewline -ForegroundColor Cyan
    $mineStr = "  Mines: $remaining/$MINES  "
    Write-Host $mineStr -NoNewline -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Time: $elapsed" -NoNewline -ForegroundColor Gray
    Write-Host ("  " + ("=" * 16)) -ForegroundColor DarkCyan
    Write-Host ""

    # Column numbers
    Write-Host "   " -NoNewline
    for ($c = 0; $c -lt $COLS; $c++) {
        Write-Host (" $c ") -NoNewline -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  +" -NoNewline -ForegroundColor DarkGray
    Write-Host ("---" * $COLS) -NoNewline -ForegroundColor DarkGray
    Write-Host "+" -ForegroundColor DarkGray

    for ($r = 0; $r -lt $ROWS; $r++) {
        Write-Host (" $r|") -NoNewline -ForegroundColor DarkGray
        for ($c = 0; $c -lt $COLS; $c++) {
            $isCursor = ($r -eq $script:cursorRow -and $c -eq $script:cursorCol)

            if ($isCursor) { Write-Host "[" -NoNewline -ForegroundColor White }
            else { Write-Host " " -NoNewline }

            if ($script:gameOver -and $script:board[$r,$c] -eq -1 -and -not $script:flagged[$r,$c]) {
                Write-Host "*" -NoNewline -ForegroundColor Red
            } elseif ($script:flagged[$r,$c]) {
                Write-Host "F" -NoNewline -ForegroundColor Magenta
            } elseif (-not $script:visible[$r,$c]) {
                Write-Host "#" -NoNewline -ForegroundColor DarkGray
            } elseif ($script:board[$r,$c] -eq -1) {
                Write-Host "*" -NoNewline -ForegroundColor Red
            } elseif ($script:board[$r,$c] -eq 0) {
                Write-Host "." -NoNewline -ForegroundColor DarkGray
            } else {
                $num = $script:board[$r,$c]
                $color = @('White','Blue','Green','Red','DarkBlue','DarkRed','Cyan','DarkMagenta','Gray')[$num]
                Write-Host $num -NoNewline -ForegroundColor $color
            }

            if ($isCursor) { Write-Host "]" -NoNewline -ForegroundColor White }
            else { Write-Host " " -NoNewline }
        }
        Write-Host "|" -ForegroundColor DarkGray
    }

    Write-Host "  +" -NoNewline -ForegroundColor DarkGray
    Write-Host ("---" * $COLS) -NoNewline -ForegroundColor DarkGray
    Write-Host "+" -ForegroundColor DarkGray
    Write-Host ""

    if ($script:gameOver) {
        Write-Host "  GAME OVER! Hit a mine!         " -ForegroundColor Red
    } elseif ($script:gameWon) {
        Write-Host "  YOU WIN! All cells cleared!    " -ForegroundColor Green
    } else {
        Write-Host "  Arrows:Move  Space:Reveal  F:Flag" -ForegroundColor DarkGray
        Write-Host "  R:Restart  Q:Quit               " -ForegroundColor DarkGray
    }

    if ($script:gameOver -or $script:gameWon) {
        Write-Host "  R:Restart  Q:Quit               " -ForegroundColor DarkGray
    }
}

function Select-Difficulty {
    Clear-Host
    Write-Host ""
    Write-Host "  =========================" -ForegroundColor Cyan
    Write-Host "       MINESWEEPER         " -ForegroundColor Cyan
    Write-Host "  =========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Select difficulty:" -ForegroundColor Yellow
    Write-Host "  [1] Beginner  (9x9,  10 mines)" -ForegroundColor Green
    Write-Host "  [2] Medium    (9x9,  20 mines)" -ForegroundColor Yellow
    Write-Host "  [3] Expert    (9x9,  35 mines)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press 1, 2, or 3..." -ForegroundColor Gray

    while ($true) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.Character) {
            '1' { $script:MINES = 10; return }
            '2' { $script:MINES = 20; return }
            '3' { $script:MINES = 35; return }
        }
    }
}

# --- Main Game Loop ---
Select-Difficulty

while ($true) {
    Initialize-Board
    Clear-Host
    Draw-Board

    while (-not $script:gameOver -and -not $script:gameWon) {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { if ($script:cursorRow -gt 0) { $script:cursorRow-- } }           # Up
            40 { if ($script:cursorRow -lt $ROWS-1) { $script:cursorRow++ } }     # Down
            37 { if ($script:cursorCol -gt 0) { $script:cursorCol-- } }           # Left
            39 { if ($script:cursorCol -lt $COLS-1) { $script:cursorCol++ } }     # Right
            default {
                switch ($key.Character) {
                    ' ' {  # Reveal
                        if (-not $script:flagged[$script:cursorRow, $script:cursorCol]) {
                            if ($script:firstMove) {
                                Place-Mines $script:cursorRow $script:cursorCol
                                $script:startTime = Get-Date
                                $script:firstMove = $false
                            }
                            if ($script:board[$script:cursorRow, $script:cursorCol] -eq -1) {
                                $script:visible[$script:cursorRow, $script:cursorCol] = $true
                                $script:gameOver = $true
                            } else {
                                Reveal-Cell $script:cursorRow $script:cursorCol
                                if (Check-Win) { $script:gameWon = $true }
                            }
                        }
                    }
                    'f' {  # Flag toggle
                        if (-not $script:visible[$script:cursorRow, $script:cursorCol]) {
                            $script:flagged[$script:cursorRow, $script:cursorCol] = -not $script:flagged[$script:cursorRow, $script:cursorCol]
                        }
                    }
                    'F' {
                        if (-not $script:visible[$script:cursorRow, $script:cursorCol]) {
                            $script:flagged[$script:cursorRow, $script:cursorCol] = -not $script:flagged[$script:cursorRow, $script:cursorCol]
                        }
                    }
                    'r' { break }
                    'R' { break }
                    'q' { Clear-Host; exit }
                    'Q' { Clear-Host; exit }
                }
            }
        }

        # R to restart breaks inner loop
        if ($key.Character -in 'r','R') { break }

        Draw-Board
    }

    if ($script:gameOver -or $script:gameWon) {
        Draw-Board
        # Wait for R or Q
        while ($true) {
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            if ($key.Character -in 'r','R') { break }
            if ($key.Character -in 'q','Q') { Clear-Host; exit }
        }
    }
}
