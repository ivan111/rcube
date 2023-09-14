# キューブ動作関連の関数と変数

<#
    .synopsis
    引数で指定した動作の逆動作を返す。
    .parameter Move
    逆動作を得たい動作
    .outputs
    逆動作
    .example
    PS> # 動作Rから逆動作R'を取得する。
    PS> $Rprime = Get-IICubePrimeMove($global:IICubeMoves.R)
#>
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


# .synopsis
# キューブ動作。この変数に値を設定することで、新しい動作を定義できる。
# .example
# PS> $global:IICubeMoves["sexy-move"] = $solved * "R U R' U'"
$global:IICubeMoves = [System.Collections.Generic.Dictionary[string, IICubeState]]::new()

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
