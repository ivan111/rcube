# キューブの色。上から順に、上面、正面、右、裏、左、下
enum CubeColor {
    White
    Green
    Red
    Blue
    Orange
    Yellow
}

# センターピース色
$CenterColors = @(
    [CubeColor]::White,
    [CubeColor]::Green,
    [CubeColor]::Red,
    [CubeColor]::Blue,
    [CubeColor]::Orange,
    [CubeColor]::Yellow
)

# コーナーピース色
$CornerColors = @(
    @([CubeColor]::White, [CubeColor]::Blue, [CubeColor]::Orange),
    @([CubeColor]::White, [CubeColor]::Red, [CubeColor]::Blue),
    @([CubeColor]::White, [CubeColor]::Green, [CubeColor]::Red),
    @([CubeColor]::White, [CubeColor]::Orange, [CubeColor]::Green),
    @([CubeColor]::Yellow, [CubeColor]::Orange, [CubeColor]::Blue),
    @([CubeColor]::Yellow, [CubeColor]::Blue, [CubeColor]::Red),
    @([CubeColor]::Yellow, [CubeColor]::Red, [CubeColor]::Green),
    @([CubeColor]::Yellow, [CubeColor]::Green, [CubeColor]::Orange)
)

# エッジピース色
$EdgeColors = @(
    @([CubeColor]::Blue, [CubeColor]::Orange),
    @([CubeColor]::Blue, [CubeColor]::Red),
    @([CubeColor]::Green, [CubeColor]::Red),
    @([CubeColor]::Green, [CubeColor]::Orange),
    @([CubeColor]::White, [CubeColor]::Blue),
    @([CubeColor]::White, [CubeColor]::Red),
    @([CubeColor]::White, [CubeColor]::Green),
    @([CubeColor]::White, [CubeColor]::Orange),
    @([CubeColor]::Yellow, [CubeColor]::Blue),
    @([CubeColor]::Yellow, [CubeColor]::Red),
    @([CubeColor]::Yellow, [CubeColor]::Green),
    @([CubeColor]::Yellow, [CubeColor]::Orange)
)

$CubeCharColor = @(
    @{ Char = "W" ; Color = "White" },
    @{ Char = "G" ; Color = "DarkGreen" },
    @{ Char = "R" ; Color = "DarkRed" },
    @{ Char = "B" ; Color = "Blue" },
    @{ Char = "O" ; Color = "Magenta" },
    @{ Char = "Y" ; Color = "DarkYellow" }
)


class IICubeState : System.IEquatable[Object] {
    [int[]]$cc  # センターカラー。@(上, 前, 右, 裏, 左, 下)
    [int[]]$cp  # コーナー位置
    [int[]]$co  # コーナー方向
    [int[]]$ep  # エッジ位置
    [int[]]$eo  # エッジ方向

    IICubeState() {
        # 白上、緑前
        $this.cc = @(0..5)
        $this.cp = @(0..7)
        $this.co = @(0) * 8
        $this.ep = @(0..11)
        $this.eo = @(0) * 12
    }

    IICubeState([int[]]$cc, [int[]]$cp, [int[]]$co, [int[]]$ep, [int[]]$eo) {
        $this.cc = $cc
        $this.cp = $cp
        $this.co = $co
        $this.ep = $ep
        $this.eo = $eo
    }

    [bool] Equals([Object] $obj) {
        return (Compare-Object $this.cc $obj.cc -SyncWindow 0) -eq 0 &&
               (Compare-Object $this.cp $obj.cp -SyncWindow 0) -eq 0 &&
               (Compare-Object $this.co $obj.co -SyncWindow 0) -eq 0 &&
               (Compare-Object $this.ep $obj.ep -SyncWindow 0) -eq 0 &&
               (Compare-Object $this.eo $obj.eo -SyncWindow 0) -eq 0
    }

    [IICubeState] Clone() {
        $cube = @{}

        $cube.cc = $this.cc.Clone()
        $cube.cp = $this.cp.Clone()
        $cube.co = $this.co.Clone()
        $cube.ep = $this.ep.Clone()
        $cube.eo = $this.eo.Clone()

        return $cube
    }

    static [IICubeState] CreateFromFile([string]$FilePath) {
        return Get-Content -Path $FilePath -Raw -ErrorAction Stop | ConvertFrom-Json
    }

    OutFile([string]$FilePath) {
        $this | ConvertTo-Json | Out-File -FilePath $FilePath -NoClobber
    }

    [String] ToString()
    {
        return "cc: " + $this.cc + "`ncp: " + $this.cp + "`nco: " + $this.co + "`nep: " + $this.ep + "`neo: " + $this.eo
    }

    static [IICubeState] op_Multiply([IICubeState]$State, [IICubeState]$Move) {
        return $State.ApplyMove($Move)
    }

    static [IICubeState] op_Multiply([IICubeState]$State, [string]$MoveStr) {
        return $State.ApplyMoves($MoveStr)
    }

    [IICubeState] ApplyMove([IICubeState]$Move) {
        $cube = @{}

        $cube.cc = $Move.cc.foreach({$this.cc[$_]})
        $cube.cp = $Move.cp.foreach({$this.cp[$_]})
        $cube.co = @(0..7).foreach({($this.co[$Move.cp[$_]] + $Move.co[$_]) % 3})
        $cube.ep = $Move.ep.foreach({$this.ep[$_]})
        $cube.eo = @(0..11).foreach({($this.eo[$Move.ep[$_]] + $Move.eo[$_]) % 2})

        return $cube
    }

    [IICubeState] ApplyMoves([string]$MoveStr) {
        $cube = $this.Clone()

        $MoveStr.Split().foreach({
            if ($global:IICubeMoves.ContainsKey($_)) {
                $cube = $cube.ApplyMove($global:IICubeMoves[$_])
            } else {
                Write-Warning -Message ("無効なキューブ操作:" + $_)
            }
        })

        return $cube
    }

    [CubeColor[]] GetUpColors() {
        $colors = @([CubeColor]::White) * 9

        $colors[0] = $script:CornerColors[$this.cp[0]][$this.co[0]]
        $colors[1] = $script:EdgeColors[$this.ep[4]][$this.eo[4]]
        $colors[2] = $script:CornerColors[$this.cp[1]][$this.co[1]]
        $colors[3] = $script:EdgeColors[$this.ep[7]][$this.eo[7]]
        $colors[4] = $script:CenterColors[$this.cc[0]]
        $colors[5] = $script:EdgeColors[$this.ep[5]][$this.eo[5]]
        $colors[6] = $script:CornerColors[$this.cp[3]][$this.co[3]]
        $colors[7] = $script:EdgeColors[$this.ep[6]][$this.eo[6]]
        $colors[8] = $script:CornerColors[$this.cp[2]][$this.co[2]]

        return $colors
    }

    [CubeColor[]] GetFrontColors() {
        return $this.ApplyMoves("x").GetUpColors()
    }

    [CubeColor[]] GetRightColors() {
        return $this.ApplyMoves("y x").GetUpColors()
    }

    [CubeColor[]] GetBackColors() {
        return $this.ApplyMoves("y2 x").GetUpColors()
    }

    [CubeColor[]] GetLeftColors() {
        return $this.ApplyMoves("y' x").GetUpColors()
    }

    [CubeColor[]] GetDownColors() {
        return $this.ApplyMoves("x2").GetUpColors()
    }

    WriteChar([CubeColor]$Color) {
        $obj = $script:CubeCharColor[$Color]
        Write-Host $obj.Char -ForegroundColor $obj.Color -NoNewLIne
    }

    Write() {
        $this | Write-IICube
    }
}


function New-IICube {
    [IICubeState]::new()
}


function Get-IICubePrimeMove {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [IICubeState]$Move
    )

    process {
        $solved_cube = [IICubeState]::new()

        $state0 = $solved_cube.ApplyMove($Move)
        $state = $state0
        $prev = $state0

        while ($solved_cube -ne $state) {
            $prev = $state
            $state.Write()
            $state = $state.ApplyMove($Move)
        }

        return $prev
    }
}


function Write-IICube {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [IICubeState]$Cube
    )

    process {
        $up = $Cube.GetUpColors()
        foreach($i in @(0..2)) {
            Write-Host "    " -NoNewLIne
            foreach($k in @(0..2)) {
                $Cube.WriteChar($up[$i * 3 + $k])
            }
            Write-Host ""
        }

        $left = $Cube.GetLeftColors()
        $front = $Cube.GetFrontColors()
        $right = $Cube.GetRightColors()
        $back = $Cube.GetBackColors()

        foreach($i in @(0..2)) {
            foreach($k in @(0..2)) {
                $Cube.WriteChar($left[$i * 3 + $k])
            }
            Write-Host " " -NoNewLIne

            foreach($k in @(0..2)) {
                $Cube.WriteChar($front[$i * 3 + $k])
            }
            Write-Host " " -NoNewLIne

            foreach($k in @(0..2)) {
                $Cube.WriteChar($right[$i * 3 + $k])
            }
            Write-Host " " -NoNewLIne

            foreach($k in @(0..2)) {
                $Cube.WriteChar($back[$i * 3 + $k])
            }
            Write-Host " " -NoNewLIne

            Write-Host ""
        }

        $down = $Cube.GetDownColors()
        foreach($i in @(0..2)) {
            Write-Host "    " -NoNewLIne
            foreach($k in @(0..2)) {
                $Cube.WriteChar($down[$i * 3 + $k])
            }
            Write-Host ""
        }
    }
}

$global:IICubeMoves = [System.Collections.Hashtable]::new()

$global:IICubeMoves.x = [IICubeState]@{
    cc = @(1, 5, 2, 0, 4, 3)
    cp = @(3, 2, 6, 7, 0, 1, 5, 4)
    co = @(2, 1, 2, 1, 1, 2, 1, 2)
    ep = @(7, 5, 9, 11, 6, 2, 10, 3, 4, 1, 8, 0)
    eo = @(0, 0, 0,  0, 1, 0,  1, 0, 1, 0, 1, 0)
}

$global:IICubeMoves.y = [IICubeState]@{
    cc = @(0, 2, 3, 4, 1, 5)
    cp = @(3, 0, 1, 2, 7, 4, 5, 6)
    co = @(0) * 8
    ep = @(3, 0, 1, 2, 7, 4, 5, 6, 11, 8, 9, 10)
    eo = @(1, 1, 1, 1, 0, 0, 0, 0,  0, 0, 0,  0)
}

$global:IICubeMoves.U = [IICubeState]@{
    cc = @(0..5)
    cp = @(3, 0, 1, 2, 4, 5, 6, 7)
    co = @(0) * 8
    ep = @(0, 1, 2, 3, 7, 4, 5, 6, 8, 9, 10, 11)
    eo = @(0) * 12
}

$Solved = [IICubeState]::new()

$global:IICubeMoves.z = $Solved * "y y y x y"

$global:IICubeMoves.D = $Solved * "x x U x x"
$global:IICubeMoves.L = $Solved * "z U z z z"
$global:IICubeMoves.R = $Solved * "z z z U z"
$global:IICubeMoves.F = $Solved * "x U x x x"
$global:IICubeMoves.B = $Solved * "x x x U x"

$global:IICubeMoves.M = $Solved * "x x x R L L L"
$global:IICubeMoves.E = $Solved * "y y y U D D D"
$global:IICubeMoves.S = $Solved * "z F F F B"

$global:IICubeMoves.u = $Solved * "U E E E"
$global:IICubeMoves.f = $Solved * "F S"
$global:IICubeMoves.r = $Solved * "R M M M"
$global:IICubeMoves.b = $Solved * "B S S S"
$global:IICubeMoves.l = $Solved * "L M"
$global:IICubeMoves.d = $Solved * "D E"

@("u", "f", "r", "b", "l", "d").foreach({
    $global:IICubeMoves[$_.ToUpper() + "w"] = $global:IICubeMoves[$_]
})

$global:IICubeMoves.Keys.Clone().foreach({
    $global:IICubeMoves[$_ + "2"] = $global:IICubeMoves[$_] * $global:IICubeMoves[$_]
    $global:IICubeMoves[$_ + "'"] = $global:IICubeMoves[$_ + "2"] * $global:IICubeMoves[$_]
})
