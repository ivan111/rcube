# キューブを表すクラスの定義


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


    <#
        .synopsis
        上白、緑前の状態のキューブを作成するコンストラクタ。
    #>
    IICubeState() {
        $this.cc = @(0..5)
        $this.cp = @(0..7)
        $this.co = @(0) * 8
        $this.ep = @(0..11)
        $this.eo = @(0) * 12
    }


    <#
        .synopsis
        引数で指定した状態のキューブを作成するコンストラクタ。
    #>
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


    <#
        .synopsis
        キューブの状態を保存したjsonファイルから、キューブオブジェクトを作成する。
    #>
    static [IICubeState] CreateFromFile([string]$FilePath) {
        return Get-Content -Path $FilePath -Raw -ErrorAction Stop | ConvertFrom-Json
    }


    <#
        .synopsis
        キューブの状態をjson形式で保存する。
    #>
    OutFile([string]$FilePath) {
        $this | ConvertTo-Json | Out-File -FilePath $FilePath -NoClobber
    }


    [String] ToString()
    {
        return "cc: " + $this.cc + "`ncp: " + $this.cp + "`nco: " + $this.co + "`nep: " + $this.ep + "`neo: " + $this.eo
    }


    <#
        .synopsis
        キューブの状態と動きを*演算子で操作できるようにする。
    #>
    static [IICubeState] op_Multiply([IICubeState]$State, [IICubeState]$Move) {
        return $State.ApplyMove($Move)
    }


    <#
        .synopsis
        キューブの状態と動きを表す文字列を*演算子で操作できるようにする。
        .example
        PS> $cube * "R U R' U'"
    #>
    static [IICubeState] op_Multiply([IICubeState]$State, [string]$MoveStr) {
        return $State.ApplyMoves($MoveStr)
    }


    <#
        .synopsis
        キューブの状態へ引数で指定した動きを適用し返す。キューブの状態オブジェクト自体は変化しない。
        .outputs
        動作を適用したあとのキューブの状態
    #>
    [IICubeState] ApplyMove([IICubeState]$Move) {
        $cube = @{}

        $cube.cc = $Move.cc.foreach({$this.cc[$_]})
        $cube.cp = $Move.cp.foreach({$this.cp[$_]})
        $cube.co = @(0..7).foreach({($this.co[$Move.cp[$_]] + $Move.co[$_]) % 3})
        $cube.ep = $Move.ep.foreach({$this.ep[$_]})
        $cube.eo = @(0..11).foreach({($this.eo[$Move.ep[$_]] + $Move.eo[$_]) % 2})

        return $cube
    }


    <#
        .synopsis
        キューブの状態へ引数で指定した動きを表す文字列を適用し返す。キューブの状態オブジェクト自体は変化しない。
        .outputs
        動作を適用したあとのキューブの状態
    #>
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


    <#
        .synopsis
        キューブ上面の色を表す配列を返す。
        .outputs
        @(ulb, ub, urb, ul, センター), ur, ulf, uf, urf)
    #>
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


<#
    .synopsis
    キューブ状態オブジェクトの作成。
    .description
    Import-Moduleではクラスがインポートされないので、この関数を用意している。
#>
function New-IICube {
    [IICubeState]::new()
}


<#
    .synopsis
    キューブ状態をコンソールに色付きで表示する。
    .inputs
    表示したいキューブ
    .parameter Cube
    表示したいキューブ
    .example
    PS> $cube * "R U R' U'" | Write-IICube
#>
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
        Write-Host ""

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
        Write-Host ""

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
